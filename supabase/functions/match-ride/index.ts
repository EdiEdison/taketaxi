import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { type, table, record } = await req.json()

  // Handle both INSERT (new rides) and UPDATE (re-matching after declines)
  if (table !== 'rides' || (type !== 'INSERT' && type !== 'UPDATE')) {
    return new Response(JSON.stringify({ message: 'Not a relevant rides table event' }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })
  }

  // For UPDATE events, only proceed if status changed to 'searching_drivers'
  if (type === 'UPDATE' && record.status !== 'searching_drivers') {
    return new Response(JSON.stringify({ message: 'Not a re-matching update' }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })
  }

  const rideId = record.id;
  const isRematch = type === 'UPDATE' && record.status === 'searching_drivers';

  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', 
    {
      auth: {
        persistSession: false,
      },
    }
  )

  try {
    interface RideDetailsRpcResponse {
      id: string;
      pickup_wkt: string;
      status: string;
    }

    // Call the PostgreSQL RPC function to get ride details with WKT location
    const { data, error: fetchError } = await supabaseClient.rpc(
      'get_ride_details_with_wkt',
      { ride_id_param: rideId }
    ).single();

    const fetchedRideDetails: RideDetailsRpcResponse | null = data as RideDetailsRpcResponse | null;

    if (fetchError) {
      console.error('Error fetching ride details with WKT via RPC:', fetchError);
      throw fetchError;
    }

    if (!fetchedRideDetails || typeof fetchedRideDetails.pickup_wkt !== 'string') {
      console.error('Could not retrieve WKT for pickup_location for ride:', rideId);
      return new Response(JSON.stringify({ message: 'Pickup location WKT not found or invalid type' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    const pickupLocationWKT = fetchedRideDetails.pickup_wkt;
    console.log('Parsed pickup location WKT:', pickupLocationWKT);

    // Parse coordinates from WKT
    const coordsMatch = pickupLocationWKT.match(/POINT\(([-+]?\d+\.?\d*)\s+([-+]?\d+\.?\d*)\)/);
    if (!coordsMatch || coordsMatch.length < 3) {
      console.error('Invalid pickup_location WKT format after conversion:', pickupLocationWKT);
      return new Response(JSON.stringify({ message: 'Invalid pickup location format after conversion' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      });
    }
    const [_, longitude, latitude] = coordsMatch;
    const pickupPointForRpc = `POINT(${longitude} ${latitude})`;

    // Get previously notified drivers to exclude them (for re-matching)
    let excludedDriverIds: string[] = [];
    if (isRematch) {
      const { data: currentRide } = await supabaseClient
        .from('rides')
        .select('driver_ids_notified')
        .eq('id', rideId)
        .single();
      
      if (currentRide && currentRide.driver_ids_notified) {
        excludedDriverIds = currentRide.driver_ids_notified;
      }
    }

    // Find online drivers near the pickup location
    let driversQuery = supabaseClient
      .from('driver_locations')
      .select('driver_id, location')
      .eq('is_online', true)
      .eq('is_available', true) // Only available drivers
      .not('location', 'is', null)
      .order('last_updated_at', { ascending: false });

    // Exclude previously notified drivers for re-matching
    if (excludedDriverIds.length > 0) {
      driversQuery = driversQuery.not('driver_id', 'in', `(${excludedDriverIds.map(id => `"${id}"`).join(',')})`);
    }

    const { data: drivers, error: driversError } = await driversQuery;

    if (driversError) {
      console.error('Error fetching online drivers:', driversError);
      throw driversError;
    }

    if (!drivers || drivers.length === 0) {
      console.log(`No ${isRematch ? 'additional ' : ''}online drivers found for ride:`, rideId);
      
      // If this is a re-match and no more drivers are available, mark as no drivers available
      if (isRematch) {
        await supabaseClient
          .from('rides')
          .update({ status: 'no_drivers_available' })
          .eq('id', rideId);
      }
      
      return new Response(JSON.stringify({ 
        message: `No ${isRematch ? 'additional ' : ''}online drivers found` 
      }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    // Use expanding radius search for re-matching
    const baseRadius = 5000; // 5km
    const maxRadius = isRematch ? 15000 : baseRadius; // 15km for re-matching
    const radiusStep = 2500; // Increase by 2.5km each time
    
    let relevantDriverIds: string[] = [];
    let currentRadius = baseRadius;

    while (relevantDriverIds.length === 0 && currentRadius <= maxRadius) {
      console.log(`Searching for drivers within ${currentRadius}m radius`);
      
      for (const driver of drivers) {
        if (driver.location) {
          const { data: distanceData, error: distanceError } = await supabaseClient.rpc('is_within_distance', {
            point1: pickupPointForRpc,
            point2: driver.location,
            distance: currentRadius,
          });

          if (distanceError) {
            console.error('Error calculating distance for driver', driver.driver_id, ':', distanceError);
            continue;
          }

          if (distanceData) {
            relevantDriverIds.push(driver.driver_id);
          }
        }
      }
      
      if (relevantDriverIds.length === 0) {
        currentRadius += radiusStep;
      }
    }

    if (relevantDriverIds.length === 0) {
      console.log('No relevant drivers found within maximum radius for ride:', rideId);
      
      // Mark as no drivers available
      await supabaseClient
        .from('rides')
        .update({ status: 'no_drivers_available' })
        .eq('id', rideId);
        
      return new Response(JSON.stringify({ message: 'No drivers within maximum radius' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    // Limit to 5 drivers for notification
    const driversToNotify = relevantDriverIds.slice(0, 5);
    
    // Combine with previously notified drivers if this is a re-match
    const allNotifiedDrivers = isRematch ? 
      [...excludedDriverIds, ...driversToNotify] : 
      driversToNotify;

    const { data: updatedRide, error: updateError } = await supabaseClient
      .from('rides')
      .update({ 
        driver_ids_notified: allNotifiedDrivers,
        status: 'pending' // Reset to pending for re-matching
      })
      .eq('id', rideId);

    if (updateError) {
      console.error('Error updating ride with driver_ids_notified:', updateError);
      throw updateError;
    }

    console.log(`Ride ${rideId} ${isRematch ? 're-matched' : 'matched'} with drivers:`, driversToNotify);
    console.log(`Total drivers notified: ${allNotifiedDrivers.length}`);

    return new Response(JSON.stringify({ 
      message: `Ride ${isRematch ? 're-matched' : 'matched'} and drivers notified`,
      driversNotified: driversToNotify.length,
      radius: currentRadius 
    }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    console.error('Edge Function error:', error);
    const errorMessage = (error instanceof Error) ? error.message : String(error);
    return new Response(JSON.stringify({ error: errorMessage }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
})
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

function errorResponse(message: string, status: number = 400) {
  return new Response(JSON.stringify({ success: false, message }), {
    headers: { 'Content-Type': 'application/json' },
    status: status,
  });
}

serve(async (req) => {
    if (req.method !== 'POST') {
        return errorResponse('Method Not Allowed. Only POST requests are accepted.', 405);
    }

    let data;
    try {
        data = await req.json();
    } catch (jsonError) {
        return errorResponse('Invalid JSON payload.', 400);
    }

    const { token, fileBase64, fileName, fileType, documentType } = data;

    if (!token || !fileBase64 || !fileName || !fileType || !documentType) {
        return errorResponse('Missing required fields (token, fileBase64, fileName, fileType, documentType).', 400);
    }

    const supabase = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_ANON_KEY') ?? '',
        {
            global: {
                headers: { Authorization: `Bearer ${token}` },
            },
            auth: {
                autoRefreshToken: false,
                persistSession: false,
            },
        }
    );

    try {
        const { data: userData, error: userError } = await supabase.auth.getUser(token);

        if (userError || !userData || !userData.user) {
            console.error('Edge Function Auth Error: Failed to get user from token.', userError?.message || 'User data not found.');
            return errorResponse('Authentication failed: Invalid or expired token.', 401);
        }

        const userId = userData.user.id;
        console.log(`Edge Function Debug: User ID from token: ${userId}`);

        const bucketName = 'userdocuments'; 

        const filePath = `${userId}/private/${documentType}_${fileName}`; 
        console.log(`Edge Function Debug: File path for upload: ${filePath}`);

        const fileBuffer = Uint8Array.from(atob(fileBase64), c => c.charCodeAt(0));

        const { data: uploadData, error: uploadError } = await supabase.storage
            .from(bucketName)
            .upload(filePath, fileBuffer, {
                contentType: fileType, 
                upsert: true, 
            });

        if (uploadError) {
            console.error(`Storage upload error: ${JSON.stringify(uploadError)}`);
            if (uploadError.message?.includes('violates row-level security policy')) {
                 return errorResponse(`Upload denied by security policy. Please check RLS rules and file path: ${uploadError.message}`, 403);
            }
            return errorResponse(`Failed to upload file to storage: ${uploadError.message}`, 500);
        }

        const { publicUrl } = supabase.storage.from(bucketName).getPublicUrl(uploadData.path).data;
        
        console.log(`Edge Function Debug: Successfully uploaded to: ${publicUrl}`);

        return new Response(JSON.stringify({ success: true, path: uploadData.path, publicUrl: publicUrl }), {
            headers: { 'Content-Type': 'application/json' },
            status: 200,
        });

    } catch (e) {
        const errorMessage = (e && typeof e === 'object' && 'message' in e) ? (e as { message: string }).message : String(e);
        console.error(`Edge Function Runtime Error: ${errorMessage}`);
        return errorResponse(`Server error: ${errorMessage}`, 500);
    }
});
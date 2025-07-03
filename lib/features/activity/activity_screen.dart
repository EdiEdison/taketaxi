import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:taketaxi/core/constants/colors.dart';
import 'package:taketaxi/features/activity/controller/activity_controller.dart';
import 'package:taketaxi/features/activity/model/activity_model.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ActivityController>(context, listen: false).loadActivities();
    });
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'Your Activities',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 1, // Slight shadow for app bar
        centerTitle: true,
      ),
      body: Consumer<ActivityController>(
        builder: (context, activityController, child) {
          if (activityController.activities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_filled_outlined,
                    size: 60,
                    color: AppColors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activities yet.',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Complete a ride to see your activity here!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: activityController.activities.length,
            itemBuilder: (context, index) {
              final activity = activityController.activities[index];
              return ActivityCard(activity: activity);
            },
          );
        },
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  final Activity activity;
  const ActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    // For date and time formatting
    final DateFormat dateFormatter = DateFormat('MMM dd, yyyy');
    final DateFormat timeFormatter = DateFormat('hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activity.destination,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${activity.estimatedFare.toStringAsFixed(0)} CFA', // Format fare
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success, // Green for paid amount
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.grey, size: 16),
                const SizedBox(width: 8),
                Text(
                  dateFormatter.format(activity.timestamp),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, color: AppColors.grey, size: 16),
                const SizedBox(width: 8),
                Text(
                  timeFormatter.format(activity.timestamp),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, color: AppColors.grey, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Driver: ${activity.driverName}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.directions_car, color: AppColors.grey, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Car: ${activity.carModel} (${activity.licensePlate})',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.credit_card, color: AppColors.grey, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Paid via: ${activity.paymentMethodDetails}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

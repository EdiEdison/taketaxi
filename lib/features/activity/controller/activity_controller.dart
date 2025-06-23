import 'package:flutter/material.dart';
import 'package:taketaxi/features/activity/model/activity_model.dart';

class ActivityController extends ChangeNotifier {
  final List<Activity> _activities = [];
  List<Activity> get activities => List.unmodifiable(_activities);

  void addActivity(Activity activity) {
    _activities.insert(0, activity);
    notifyListeners();
  }

  Future<void> loadActivities() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Example: _activities.addAll(loadedData);
    notifyListeners();
  }

  void clearActivities() {
    _activities.clear();
    notifyListeners();
  }
}

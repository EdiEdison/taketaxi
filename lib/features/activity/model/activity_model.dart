class Activity {
  final String id;
  final String destination;
  final DateTime timestamp;
  final String driverName;
  final String carModel;
  final String licensePlate;
  final double estimatedFare; // The estimated fare for the ride
  final String
  paymentMethodDetails; // e.g., "MoMo", "Orange Money", "Direct Cash (10k)"

  Activity({
    required this.id,
    required this.destination,
    required this.timestamp,
    required this.driverName,
    required this.carModel,
    required this.licensePlate,
    required this.estimatedFare,
    required this.paymentMethodDetails,
  });

  // Optional: A factory constructor to create Activity from a map (e.g., for JSON deserialization)
  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'],
      destination: map['destination'],
      timestamp: DateTime.parse(map['timestamp']), // Assuming ISO 8601 string
      driverName: map['driverName'],
      carModel: map['carModel'],
      licensePlate: map['licensePlate'],
      estimatedFare: map['estimatedFare'],
      paymentMethodDetails: map['paymentMethodDetails'],
    );
  }

  // Optional: A method to convert Activity to a map (e.g., for JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destination': destination,
      'timestamp': timestamp.toIso8601String(),
      'driverName': driverName,
      'carModel': carModel,
      'licensePlate': licensePlate,
      'estimatedFare': estimatedFare,
      'paymentMethodDetails': paymentMethodDetails,
    };
  }
}

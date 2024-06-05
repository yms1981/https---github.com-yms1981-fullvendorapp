class OfflineLocationData {
  int id = 0;
  bool? isLocationAllowed;
  bool? isGPSOn;
  double? latitude;
  double? longitude;
  int? time;
  double? accuracy;

  OfflineLocationData({
    this.id = 0,
    this.isLocationAllowed,
    this.isGPSOn,
    this.latitude,
    this.longitude,
    this.time,
    this.accuracy,
  });

  factory OfflineLocationData.fromJson(Map<String, dynamic> json) {
    return OfflineLocationData(
      id: json['id'],
      isLocationAllowed: json['isLocationAllowed'] == 1,
      isGPSOn: json['isGPSOn'] == 1,
      latitude: json['latitude'],
      longitude: json['longitude'],
      time: json['time'],
      accuracy: json['accuracy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isLocationAllowed': isLocationAllowed,
      'isGPSOn': isGPSOn,
      'latitude': latitude,
      'longitude': longitude,
      'time': time,
      'accuracy': accuracy,
    };
  }
}

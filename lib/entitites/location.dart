class Location {
  final num? lat;
  final num? lng;

  Location({
    this.lat,
    this.lng,
  });

  Location copyWith({
    num? lat,
    num? lng,
  }) {
    return Location(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'lat': lat,
      'lng': lng,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      lat: map['lat'] != null ? map['lat'] as num : null,
      lng: map['lng'] != null ? map['lng'] as num : null,
    );
  }

  @override
  String toString() => 'Location(lat: $lat, lng: $lng)';
}

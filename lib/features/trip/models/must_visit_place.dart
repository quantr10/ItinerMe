class MustVisitPlace {
  final String name;
  final String placeId;

  MustVisitPlace({required this.name, required this.placeId});

  Map<String, dynamic> toJson() => {'name': name, 'placeId': placeId};

  factory MustVisitPlace.fromJson(Map<String, dynamic> json) =>
      MustVisitPlace(name: json['name'], placeId: json['placeId']);
}

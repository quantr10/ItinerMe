class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final List<String> createdTripIds;
  final List<String> savedTripIds;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.createdTripIds = const [],
    this.savedTripIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'avatarUrl': avatarUrl,
    'createdTripIds': createdTripIds,
    'savedTripIds': savedTripIds,
  };

  factory UserModel.fromJson(Map<String, dynamic> json, String id) => UserModel(
    id: id,
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    avatarUrl: json['avatarUrl'] ?? '',
    createdTripIds: List<String>.from(json['createdTripIds'] ?? []),
    savedTripIds: List<String>.from(json['savedTripIds'] ?? []),
  );

  UserModel copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    List<String>? createdTripIds,
    List<String>? savedTripIds,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdTripIds: createdTripIds ?? this.createdTripIds,
      savedTripIds: savedTripIds ?? this.savedTripIds,
    );
  }
}

import 'package:equatable/equatable.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class User extends Equatable {
  String username;
  String photoUrl;
  String? _id;
  bool active;
  DateTime lastSeen;

  String? get id => _id;

  User({
    required this.username,
    required this.photoUrl,
    required this.active,
    required this.lastSeen,
  });

  toJson() => <String, dynamic>{
        'username': username,
        'photo_url': photoUrl,
        'active': active,
        'last_seen': lastSeen.millisecondsSinceEpoch,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    final user = User(
        username: json['username'],
        photoUrl: json['photo_url'],
        active: json['active'],
        lastSeen:
            DateTime.fromMillisecondsSinceEpoch(json['last_seen'] as int));
    user._id = json['id'];

    return user;
  }

  @override
  List<Object?> get props => [username, photoUrl, active, lastSeen];
}

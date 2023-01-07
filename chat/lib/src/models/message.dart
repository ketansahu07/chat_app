import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String to;
  final String from;
  final DateTime timestamp;
  final String contents;
  String? _id;

  String? get id => _id;

  Message({
    required this.to,
    required this.from,
    required this.timestamp,
    required this.contents,
  });

  toJson() => <String, dynamic>{
        'to': to,
        'from': from,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'contents': contents
      };

  factory Message.fromJson(Map<String, dynamic> json) {
    var message = Message(
        to: json['to'],
        from: json['from'],
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        contents: json['contents']);

    message._id = json['id'];
    return message;
  }
  
  @override
  List<Object?> get props => [to, from, timestamp, contents];
}

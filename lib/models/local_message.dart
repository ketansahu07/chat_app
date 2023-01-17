import 'package:chat/chat.dart';

class LocalMessage {
  String chatId;
  String? _id;
  Message message;
  ReceiptStatus receipt;

  LocalMessage(this.chatId, this.message, this.receipt);

  String? get id => _id;

  Map<String, dynamic> toMap() => {
        'chat_id': chatId,
        'id': message.id,
        ...message.toJson(),
        'receipt': receipt.value(),
      };

  factory LocalMessage.fromMap(Map<String, dynamic> json) {
    final message = Message(
        to: json['to'],
        from: json['from'],
        timestamp: json['timestamp'],
        contents: json['contents']);

    final localMessage = LocalMessage(json['chat_id'], message, EnumParsing.fromString(json['receipt']));
    localMessage._id = json['id'];
    return localMessage;
  }
}

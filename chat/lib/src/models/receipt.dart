// ignore_for_file: public_member_api_docs, sort_constructors_first
enum ReceiptStatus { sent, delivered, read }

extension EnumParsing on ReceiptStatus {
  String value() {
    return toString().split('.').last;
  }

  static ReceiptStatus fromString(String status) {
    return ReceiptStatus.values
        .firstWhere((element) => element.value() == status);
  }
}

class Receipt {
  String? _id;
  final String recipient;
  final String messageId;
  final ReceiptStatus status;
  final DateTime timestamp;

  Receipt({
    required this.recipient,
    required this.messageId,
    required this.status,
    required this.timestamp,
  });

  String? get id => _id;

  Map<String, dynamic> toJson() => {
        'recipient': recipient,
        'message_id': messageId,
        'status': status.value(),
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory Receipt.fromJson(Map<String, dynamic> json) {
    var receipt = Receipt(
        recipient: json['recipient'],
        messageId: json['message_id'],
        status: EnumParsing.fromString(json['status']),
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int));
    receipt._id = json['id'];
    return receipt;
  }
}

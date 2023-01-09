import 'package:chat/src/models/receipt.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/receipt/receipt_service_contract.dart';
import 'package:chat/src/services/receipt/receipt_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late IReceiptService sut;

  setUp(() async {
    connection = await r.connect(host: '127.0.0.1', port: 28015);
    await createDb(r, connection);
    sut = ReceiptService(r, connection);
  });

  tearDown(() async {
    sut.dispose();
    await cleanDb(r, connection);
  });

  User user = User.fromJson({
    'id': '1234',
    'username': 'testUser',
    'photo_url': 'url',
    'active': true,
    'last_seen': DateTime.now().millisecondsSinceEpoch,
  });

  test('receipt sent successfully', () async {
    Receipt receipt = Receipt(
        recipient: '444',
        messageId: '1234',
        status: ReceiptStatus.delivered,
        timestamp: DateTime.now());

    final res = await sut.send(receipt);
    expect(res, true);
  });

  test('successfully subscribe and receive receipts', () async {
    sut.receipts(user).listen(expectAsync1((receipt) {
          expect(receipt.recipient, user.id);
        }, count: 2));

    Receipt receipt = Receipt(
        recipient: user.id!,
        messageId: '1234',
        status: ReceiptStatus.delivered,
        timestamp: DateTime.now());

    Receipt receipt2 = Receipt(
        recipient: user.id!,
        messageId: '1234',
        status: ReceiptStatus.delivered,
        timestamp: DateTime.now());

    await sut.send(receipt);
    await sut.send(receipt2);
  });
}

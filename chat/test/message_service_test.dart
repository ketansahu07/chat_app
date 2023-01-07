import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/message/message_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late MessageService sut; // System under test

  setUp(() async {
    connection = await r.connect(host: '127.0.0.1', port: 28015);
    await createDb(r, connection);
    sut = MessageService(r, connection);
  });

  tearDown(() async {
    sut.dispose();
    await cleanDb(r, connection);
  });

  final user = User.fromJson({
    'username': 'userOne',
    'photo_url': 'url',
    'id': '1234',
    'active': true,
    'last_seen': DateTime.now().millisecondsSinceEpoch,
  });

  final user2 = User.fromJson({
    'username': 'userTwo',
    'photo_url': 'url',
    'id': '5678',
    'active': true,
    'last_seen': DateTime.now().millisecondsSinceEpoch,
  });

  test('message sent successfully', () async {
    Message message = Message(
        to: '5678',
        from: user.id!,
        timestamp: DateTime.now(),
        contents: 'this is a test message');

    final res = await sut.send(message);
    expect(res, true);
  });

  test('successfully subscribe and receive message', () async {
    sut.messages(activeUser: user2).listen(expectAsync1((message) {
          expect(message.to, user2.id);
          expect(message.id, isNotEmpty);
        }, count: 2));

    Message message = Message(
        to: user2.id!,
        from: user.id!,
        timestamp: DateTime.now(),
        contents: 'this is first message');

    Message message2 = Message(
        to: user2.id!,
        from: user.id!,
        timestamp: DateTime.now(),
        contents: 'this is second message');

    await sut.send(message);
    await sut.send(message2);
  });

  test('successfully subscribe and receive new message', () async {
    Message message = Message(
        to: user2.id!,
        from: user.id!,
        timestamp: DateTime.now(),
        contents: 'this is first message');

    Message message2 = Message(
        to: user2.id!,
        from: user.id!,
        timestamp: DateTime.now(),
        contents: 'this is second message');

    await sut.send(message);
    await sut.send(message2).whenComplete(
          () => sut.messages(activeUser: user2).listen(
                expectAsync1((message) {
                  expect(message.to, user2.id);
                }, count: 2),
              ),
        );
  });
}

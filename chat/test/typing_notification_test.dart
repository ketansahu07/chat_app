import 'package:chat/src/models/typing_event.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/typing/typing_notification.dart';
import 'package:chat/src/services/typing/typing_notification_service_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late ITypingNotification sut;

  setUp(() async {
    connection = await r.connect();
    await createDb(r, connection);
    sut = TypingNotification(r, connection);
  });

  tearDown(() async {
    sut.dispose();
    await cleanDb(r, connection);
  });

  final user = User.fromJson({
    'id': '1234',
    'username': 'user1',
    'photo_url': 'url',
    'active': true,
    'last_seen': DateTime.now().millisecondsSinceEpoch,
  });

  final user2 = User.fromJson({
    'id': '5678',
    'username': 'user2',
    'photo_url': 'url',
    'active': true,
    'last_seen': DateTime.now().millisecondsSinceEpoch,
  });

  test('sent typing notification successfully', () async {
    TypingEvent typingEvent =
        TypingEvent(from: user2.id!, to: user.id!, event: Typing.start);

    final res = await sut.send(event: typingEvent, to: user);
    expect(res, true);
  });

  test('successfully subscrive and receive typing events', () async {
    sut.subscribe(user2, [user.id!]).listen(expectAsync1((event) {
      expect(event.from, user.id!);
    }, count: 2));

    TypingEvent typing =
        TypingEvent(to: user2.id!, from: user.id!, event: Typing.start);

    TypingEvent stopTyping =
        TypingEvent(to: user2.id!, from: user.id!, event: Typing.stop);

    await sut.send(event: typing, to: user2);
    await sut.send(event: stopTyping, to: user2);
  });
}

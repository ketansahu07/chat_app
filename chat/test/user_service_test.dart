import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/user_service_impl.dart';

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late UserService sut;
  DateTime TEST_DATE_TIME =
      DateFormat('dd-MM-yyyy HH:mm:ss').parse('17-09-1999 06:00:00');

  setUp(() async {
    connection = await r.connect(host: '127.0.0.1', port: 28015);
    await createDb(r, connection);
    sut = UserService(r, connection);
  });

  tearDown(() async {
    await cleanDb(r, connection);
  });

  test('creates a new user document in database', () async {
    final user = User(
      username: 'test',
      photoUrl: 'url',
      active: true,
      lastSeen: TEST_DATE_TIME,
    );

    final userWithId = await sut.connect(user);
    expect(userWithId, user);
  });

  test('get online users', () async {
    final user = User(
        username: 'test',
        photoUrl: 'url',
        active: true,
        lastSeen: TEST_DATE_TIME);

    await sut.connect(user);

    final users = await sut.online();

    expect(users.length, 1);
  });
}

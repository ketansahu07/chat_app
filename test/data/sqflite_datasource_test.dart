import 'package:chat/chat.dart';
import 'package:chat_app/data/datasources/sqflite_datasource.dart';
import 'package:chat_app/models/chat.dart';
import 'package:chat_app/models/local_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqlite_api.dart';

import 'sqflite_datasource_test.mocks.dart';

class MySqfliteDatabase extends Mock implements Database {}

class MyBatch extends Mock implements Batch {}

@GenerateMocks([MySqfliteDatabase, MyBatch])
void main() {
  late SqfliteDatasource sut;
  late MockMySqfliteDatabase database;
  late MockMyBatch batch;

  setUp(() {
    database = MockMySqfliteDatabase();
    batch = MockMyBatch();
    sut = SqfliteDatasource(database);
  });

  final message = Message.fromJson({
    'from': '1111',
    'to': '2222',
    'contents': 'hey',
    'timestamp': DateTime.parse('2023-01-01').millisecondsSinceEpoch,
    'id': '4444',
  });

  test('should perform insert of chat to the database', () async {
    // arrange
    final chat = Chat('1234');
    when(database.insert('chats', chat.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .thenAnswer((_) async => 1);

    // act
    await sut.addChat(chat);

    // assert
    verify(database.insert('chats', chat.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .called(1);
  });

  test('should perform insert of message to the database', () async {
    // arrange
    final localMessage = LocalMessage('1234', message, ReceiptStatus.sent);
    when(database.insert('messages', localMessage.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .thenAnswer((_) async => 1);

    // act
    await sut.addMessage(localMessage);

    // assert
    verify(database.insert('messages', localMessage.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .called(1);
  });

  test('should perform a database query and return a message', () async {
    // arrange
    final messageMap = [
      {
        'chat_id': '111',
        'id': '4444',
        'from': '111',
        'to': '222',
        'contents': 'hey!',
        'receipt': 'sent',
        'timestamp': DateTime.parse('2023-01-01'),
      }
    ];
    when(database.query('messages',
            where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
        .thenAnswer((_) async => messageMap);

    // act
    var message = await sut.findMessages('111');

    // verify
    expect(message.length, 1);
    expect(message.first.chatId, '111');
    verify(database.query('messages',
            where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
        .called(1);
  });

  test('should perform database update on messages', () async {
    // arrange
    final localMessage = LocalMessage('1234', message, ReceiptStatus.sent);
    when(database.update('messages', localMessage.toMap(),
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .thenAnswer((_) async => 1);

    // act
    await sut.updateMessage(localMessage);

    // assert
    verify(database.update('messages', localMessage.toMap(),
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .called(1);
  });

  test('should perform database batch delete of chat', () async {
    // arrange
    const chatId = '111';
    when(database.batch()).thenReturn(batch);
    when(batch.commit(noResult: true)).thenAnswer((_) async => List.empty());

    // act
    await sut.deleteChat(chatId);

    // assert
    verifyInOrder([
      database.batch(),
      batch.delete('messages', where: anyNamed('where'), whereArgs: [chatId]),
      batch.delete('chats', where: anyNamed('where'), whereArgs: [chatId]),
      batch.commit(noResult: true)
    ]);
  });
}

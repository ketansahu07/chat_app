import 'package:chat/chat.dart';
import 'package:chat_app/data/datasources/datasource_contract.dart';
import 'package:chat_app/models/chat.dart';
import 'package:chat_app/models/local_message.dart';
import 'package:chat_app/viewmodels/chat_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_view_model_test.mocks.dart';

class MyDataSource extends Mock implements IDatasource {}

@GenerateMocks([MyDataSource])
void main() {
  late ChatViewModel sut;
  late MockMyDataSource mockMyDataSource;

  setUp(() {
    mockMyDataSource = MockMyDataSource();
    sut = ChatViewModel(mockMyDataSource);
  });

  final message = Message.fromJson({
    'from': '111',
    'to': '222',
    'contents': 'hey',
    'timestamp': DateTime.parse('2023-01-01').millisecondsSinceEpoch,
    'id': '4444'
  });

  test('initial message return empty list', () async {
    when(mockMyDataSource.findMessages(any)).thenAnswer((_) async => []);
    expect(await sut.getMessages('123'), isEmpty);
  });

  test('returns list of messages from local storage', () async {
    final chat = Chat('123');
    final localMessage =
        LocalMessage(chat.id, message, ReceiptStatus.delivered);
    when(mockMyDataSource.findMessages(chat.id))
        .thenAnswer((_) async => [localMessage]);
    final messages = await sut.getMessages('123');
    expect(messages, isNotEmpty);
    expect(messages.first.chatId, '123');
  });

  test('creates a new chat when sending first message', () async {
    when(mockMyDataSource.findChat(any)).thenAnswer((_) async => null);
    await sut.sentMessage(message);
    verify(mockMyDataSource.addChat(any)).called(1);
  });

  test('add new sent message to the chat', () async {
    final chat = Chat('123');
    final localMessage = LocalMessage(chat.id, message, ReceiptStatus.sent);
    when(mockMyDataSource.findMessages(chat.id))
        .thenAnswer((_) async => [localMessage]);

    await sut.getMessages(chat.id);
    await sut.sentMessage(message);

    verifyNever(mockMyDataSource.addChat(any));
    verify(mockMyDataSource.addMessage(any)).called(1);
  });

  test('add new received message to the chat', () async {
    final chat = Chat('111');
    final localMessage =
        LocalMessage(chat.id, message, ReceiptStatus.delivered);
    when(mockMyDataSource.findMessages(chat.id))
        .thenAnswer((_) async => [localMessage]);
    when(mockMyDataSource.findChat(chat.id)).thenAnswer((_) async => chat);

    await sut.getMessages(chat.id);
    await sut.receivedMessage(message);

    verifyNever(mockMyDataSource.addChat(any));
    verify(mockMyDataSource.addMessage(any)).called(1);
  });

  test('creates new chat when message received is not a part of this chat',
      () async {
    final chat = Chat('123');
    final localMessage =
        LocalMessage(chat.id, message, ReceiptStatus.delivered);
    when(mockMyDataSource.findMessages(chat.id))
        .thenAnswer((_) async => [localMessage]);
    when(mockMyDataSource.findChat(any)).thenAnswer((_) async => null);

    await sut.getMessages(chat.id);
    await sut.receivedMessage(message);

    verify(mockMyDataSource.addChat(any)).called(1);
    verify(mockMyDataSource.addMessage(any)).called(1);
    expect(sut.otherMessages, 1);
  });
}

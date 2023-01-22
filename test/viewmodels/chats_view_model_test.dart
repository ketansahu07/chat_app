import 'package:chat/chat.dart';
import 'package:chat_app/data/datasources/datasource_contract.dart';
import 'package:chat_app/models/chat.dart';
import 'package:chat_app/viewmodels/chats_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chats_view_model_test.mocks.dart';

class MyDatasource extends Mock implements IDatasource {}

@GenerateMocks([MyDatasource])
void main() {
  late ChatsViewModel sut;
  late MockMyDatasource mockMyDatasource;

  setUp(() {
    mockMyDatasource = MockMyDatasource();
    sut = ChatsViewModel(mockMyDatasource);
  });

  final message = Message.fromJson({
    'from': '111',
    'to': '222',
    'contents': 'test',
    'timestamp': DateTime.parse('2023-01-01').millisecondsSinceEpoch,
    'id': '4444'
  });

  test('initial chats return empty lislt', () async {
    when(mockMyDatasource.findAllChats()).thenAnswer((_) async => []);
    expect(await sut.getChats(), isEmpty);
  });

  test('returns list of chats', () async {
    final chat = Chat('123');
    when(mockMyDatasource.findAllChats()).thenAnswer((_) async => [chat]);
    final chats = await sut.getChats();
    expect(chats, isNotEmpty);
  });

  test('creates a new chat when receiving message for the first time',
      () async {
    when(mockMyDatasource.findChat(any)).thenAnswer((_) async => null);
    await sut.receivedMessage(message);
    verify(mockMyDatasource.addChat(any)).called(1);
  });

  test('add new message to existing chat', () async {
    final chat = Chat('123');

    when(mockMyDatasource.findChat(any)).thenAnswer((_) async => chat);
    await sut.receivedMessage(message);
    verifyNever(mockMyDatasource.addChat(any));
    verify(mockMyDatasource.addMessage(any)).called(1);
  });
}

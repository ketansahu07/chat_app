import 'package:chat/chat.dart';
import 'package:chat_app/states_management/message/message_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'message_bloc_test.mocks.dart';

class MessageService extends Mock implements IMessageService {}

@GenerateMocks([MessageService])
void main() {
  late MessageBloc sut;
  late IMessageService messageService;
  late User user;

  setUp(() {
    messageService = MockMessageService();
    user = User(
      username: 'test',
      photoUrl: 'url',
      active: true,
      lastSeen: DateTime.parse('2023-01-02'),
    );
    sut = MessageBloc(messageService);

    when(messageService.dispose()).thenAnswer((_) => {});
  });

  tearDown(() => sut.close());

  test('should emit initial only without subscriptions', () {
    expect(sut.state, MessageInitial());
  });

  test('should emit message sent state when message is sent', () {
    final message = Message(
      to: '456',
      from: '123',
      timestamp: DateTime.now(),
      contents: 'test message',
    );

    when(messageService.send(message)).thenAnswer((_) async => true);
    sut.add(MessageEvent.onMessageSent(message));
    expectLater(sut.stream, emits(MessageState.sent(message)));
  });

  test('should emit messages received from service', () {
    final message = Message(
      to: '456',
      from: '123',
      timestamp: DateTime.now(),
      contents: 'test message',
    );

    final message2 = Message(
      to: '456',
      from: '123',
      timestamp: DateTime.now(),
      contents: 'test message 2',
    );

    when(messageService.messages(activeUser: user)).thenAnswer(
        (realInvocation) => Stream.fromIterable([message, message2]));

    sut.add(MessageEvent.onSubscribed(user));
    expectLater(
        sut.stream,
        emitsInOrder([
          MessageReceivedSuccess(message),
          MessageReceivedSuccess(message2)
        ]));
  });
}

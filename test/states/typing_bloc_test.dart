import 'package:chat/chat.dart';
import 'package:chat_app/states_management/receipt/receipt_bloc.dart';
import 'package:chat_app/states_management/typing/typing_notification_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'typing_bloc_test.mocks.dart';

class TypingNotificationService extends Mock implements ITypingNotification {}

@GenerateMocks([TypingNotificationService])
void main() {
  late TypingNotificationBloc sut;
  late ITypingNotification typingNotification;
  late User user;

  setUp(() {
    typingNotification = MockTypingNotificationService();
    user = User(
      username: 'test',
      photoUrl: 'url',
      active: true,
      lastSeen: DateTime.parse('2023-01-02'),
    );
    sut = TypingNotificationBloc(typingNotification);

    when(typingNotification.dispose()).thenAnswer((_) => {});
  });

  tearDown(() => sut.close());

  test('should emit initial only without subscriptions', () {
    expect(sut.state, TypingNotificationInitial());
  });

  test('should emit typing notification sent state when typing notification is sent', () {
    final typingEvent =
        TypingEvent(from: '456', to: '123', event: Typing.start);

    when(typingNotification.send(event: typingEvent))
        .thenAnswer((_) async => true);
    sut.add(TypingNotificationEvent.onTypingNotificationSent(typingEvent));
    expectLater(sut.stream, emits(TypingNotificationState.sent()));
  });

  test('should emit typing notification received from service', () {
    final typingEvent =
        TypingEvent(from: '456', to: '123', event: Typing.start);

    final user2 = User.fromJson({
      'id': '111',
      'username': 'test',
      'photo_url': 'url',
      'active': true,
      'last_seen': DateTime.parse('2023-01-01').millisecondsSinceEpoch,
    });

    when(typingNotification.subscribe(user, [user2.id!]))
        .thenAnswer((realInvocation) => Stream.fromIterable([typingEvent]));

    sut.add(TypingNotificationEvent.onSubscribed(user));
    expectLater(
        sut.stream,
        emitsInOrder([
          TypingNotificationReceivedSuccess(typingEvent),
        ]));
  });
}

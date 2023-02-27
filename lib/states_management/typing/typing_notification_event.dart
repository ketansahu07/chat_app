part of 'typing_notification_bloc.dart';

abstract class TypingNotificationEvent extends Equatable {
  const TypingNotificationEvent();

  factory TypingNotificationEvent.onSubscribed(User user, {List<String>? usersWithChat}) => Subscribed(user, usersWithChat: usersWithChat);
  factory TypingNotificationEvent.onTypingNotificationSent(
          TypingEvent typingevent) =>
      TypingNotificationSent(typingevent);

  @override
  List<Object?> get props => [];
}

class Subscribed extends TypingNotificationEvent {
  final User user;
  final List<String>? usersWithChat;
  const Subscribed(this.user, {this.usersWithChat});

  @override
  List<Object?> get props => [user, usersWithChat];
}

class NotSubscribed extends TypingNotificationEvent {}

class TypingNotificationSent extends TypingNotificationEvent {
  final TypingEvent typingevent;
  const TypingNotificationSent(this.typingevent);

  @override
  List<Object?> get props => [typingevent];
}

class _TypingNotificationReceived extends TypingNotificationEvent {
  final TypingEvent typingevent;

  const _TypingNotificationReceived(this.typingevent);

  @override
  List<Object?> get props => [typingevent];
}

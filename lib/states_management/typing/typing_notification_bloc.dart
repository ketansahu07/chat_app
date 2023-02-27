import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat/chat.dart';
import 'package:equatable/equatable.dart';

part 'typing_notification_event.dart';
part 'typing_notification_state.dart';

class TypingNotificationBloc
    extends Bloc<TypingNotificationEvent, TypingNotificationState> {
  final ITypingNotification _typingNotification;
  StreamSubscription? _subscription;

  TypingNotificationBloc(this._typingNotification)
      : super(TypingNotificationState.initial()) {
    on<Subscribed>((event, emit) async {
      if (event.usersWithChat == null) {
        add(NotSubscribed());
        return;
      }
      await _subscription?.cancel();
      _subscription = _typingNotification
          .subscribe(event.user, event.usersWithChat ?? [])
          .listen((receipt) => add(_TypingNotificationReceived(receipt)));
    });

    on<_TypingNotificationReceived>((event, emit) =>
        emit(TypingNotificationState.received(event.typingevent)));

    on<TypingNotificationSent>((event, emit) async {
      await _typingNotification.send(event: event.typingevent);
      emit(TypingNotificationState.sent());
    });

    on<NotSubscribed>((event, emit) => emit(TypingNotificationState.initial()));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _typingNotification.dispose();
    return super.close();
  }
}

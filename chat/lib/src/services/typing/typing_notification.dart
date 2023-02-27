import 'dart:async';

import 'package:chat/src/models/user.dart';
import 'package:chat/src/models/typing_event.dart';
import 'package:chat/src/services/typing/typing_notification_service_contract.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

class TypingNotification implements ITypingNotification {
  final RethinkDb _r;
  final Connection _connection;

  final _controller = StreamController<TypingEvent>.broadcast();
  StreamSubscription? _changefeed;

  TypingNotification(this._r, this._connection);

  @override
  void dispose() {
    _changefeed?.cancel();
    _controller.close();
  }

  @override
  Future<bool> send({required TypingEvent event}) async {
    Map record = await _r
        .table('typing_events')
        .insert(event.toJson(), {'conflict': 'update'}).run(_connection);

    return record['inserted'] == 1;
  }

  @override
  Stream<TypingEvent> subscribe(User user, List<String> userIds) {
    _startReceivingTypingEvents(user, userIds);
    return _controller.stream;
  }

  _startReceivingTypingEvents(User user, List<String> userIds) {
    _changefeed = _r
        .table('typing_events')
        .filter((event) {
          return event('to')
              .eq(user.id)
              .and(_r.expr(userIds).contains(event('from')));
        })
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event
              .forEach((feedData) {
                if (feedData['new_val'] == null) return;

                final typing = _eventFromFeed(feedData);
                _controller.sink.add(typing);
                _removeEvent(typing);
              })
              .catchError((err) => print(err))
              .onError((error, stackTrace) => print(error));
        });
  }

  TypingEvent _eventFromFeed(feedData) {
    return TypingEvent.fromJson(feedData['new_val']);
  }

  _removeEvent(TypingEvent event) {
    _r
        .table('typing_events')
        .get(event.id)
        .delete({'return_changes': false}).run(_connection);
  }
}

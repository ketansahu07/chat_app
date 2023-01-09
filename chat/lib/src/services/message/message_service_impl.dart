// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:chat/src/services/encryption/encryption_contract.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/message/message_service_contract.dart';

class MessageService implements IMessageService {
  final RethinkDb r;
  final Connection _connection;
  final IEncryption _encryption;

  final _controller = StreamController<Message>.broadcast();
  StreamSubscription? _changeFeed;

  MessageService(this.r, this._connection, this._encryption);

  @override
  dispose() {
    _changeFeed?.cancel();
    _controller.close();
  }

  @override
  Future<bool> send(Message message) async {
    var data = message.toJson();
    data['contents'] = _encryption.encrypt(message.contents);
    Map record = await r.table('messages').insert(data).run(_connection);
    return record['inserted'] == 1;
  }

  @override
  Stream<Message> messages({required User activeUser}) {
    _startReceivingMessage(activeUser);
    return _controller.stream;
  }

  _startReceivingMessage(User user) {
    _changeFeed = r
        .table('messages')
        .filter({'to': user.id})
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event
              .forEach((feedData) {
                if (feedData['new_val'] == null) return;

                final message = _messageFromFeed(feedData);
                _controller.sink.add(message);
                _removeDeliveredMessage(message);
              })
              .catchError((err) => print(err))
              .onError((error, stackTrace) => print(error));
        });
  }

  Message _messageFromFeed(feedData) {
    var data = feedData['new_val'];
    data['contents'] = _encryption.decrypt(data['contents']);
    return Message.fromJson(data);
  }

  _removeDeliveredMessage(Message message) {
    r
        .table('messages')
        .get(message.id)
        .delete({'return_changes': false}).run(_connection);
  }
}

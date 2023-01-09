import 'dart:async';

import 'package:chat/src/models/user.dart';
import 'package:chat/src/models/receipt.dart';
import 'package:chat/src/services/receipt/receipt_service_contract.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

class ReceiptService implements IReceiptService {
  final RethinkDb r;
  final Connection _connection;

  final _controller = StreamController<Receipt>.broadcast();
  StreamSubscription? _changeFeed;

  ReceiptService(this.r, this._connection);
  
  @override
  void dispose() {
    _changeFeed?.cancel();
    _controller.close();
  }

  @override
  Future<bool> send(Receipt receipt) async {
    var data = receipt.toJson();
    Map record = await r.table('receipts').insert(data).run(_connection);
    return record['inserted'] == 1;
  }

  @override
  Stream<Receipt> receipts(User user) {
     _startReceivingReceipts(user);
    return _controller.stream;
  }

  _startReceivingReceipts(User user) {
    _changeFeed = r
        .table('receipts')
        .filter({'recipient': user.id})
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event
              .forEach((feedData) {
                if (feedData['new_val'] == null) return;

                final receipt = _receiptFromFeed(feedData);
                _controller.sink.add(receipt);
              })
              .catchError((err) => print(err))
              .onError((error, stackTrace) => print(error));
        });
  }

  Receipt _receiptFromFeed(feedData) {
    var data = feedData['new_val'];
    return Receipt.fromJson(data);
  }

}
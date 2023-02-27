import 'package:chat/chat.dart';
import 'package:chat_app/states_management/receipt/receipt_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'receipt_bloc_test.mocks.dart';

class ReceiptService extends Mock implements IReceiptService {}

@GenerateMocks([ReceiptService])
void main() {
  late ReceiptBloc sut;
  late IReceiptService receiptService;
  late User user;

  setUp(() {
    receiptService = MockReceiptService();
    user = User(
      username: 'test',
      photoUrl: 'url',
      active: true,
      lastSeen: DateTime.parse('2023-01-02'),
    );
    sut = ReceiptBloc(receiptService);

    when(receiptService.dispose()).thenAnswer((_) => {});
  });

  tearDown(() => sut.close());

  test('should emit initial only without subscriptions', () {
    expect(sut.state, ReceiptInitial());
  });

  test('should emit receipt sent state when receipt is sent', () {
    final receipt = Receipt(
      recipient: '456',
      messageId: '123',
      status: ReceiptStatus.sent,
      timestamp: DateTime.now(),
    );

    when(receiptService.send(receipt)).thenAnswer((_) async => true);
    sut.add(ReceiptEvent.onReceiptSent(receipt));
    expectLater(sut.stream, emits(ReceiptState.sent(receipt)));
  });

  test('should emit receipt received from service', () {
    final receipt = Receipt(
      recipient: '456',
      messageId: '123',
      status: ReceiptStatus.delivered,
      timestamp: DateTime.now(),
    );

    final receipt2 = Receipt(
      recipient: '456',
      messageId: '234',
      status: ReceiptStatus.delivered,
      timestamp: DateTime.now(),
    );

    when(receiptService.receipts(user)).thenAnswer(
        (realInvocation) => Stream.fromIterable([receipt, receipt2]));

    sut.add(ReceiptEvent.onSubscribed(user));
    expectLater(
        sut.stream,
        emitsInOrder([
          ReceiptReceivedSuccess(receipt),
          ReceiptReceivedSuccess(receipt2)
        ]));
  });
}

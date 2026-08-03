import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/features/receiver/providers/receiver_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReceiverNotifier', () {
    test('initial state is idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(receiverProvider);
      expect(state.step, ReceiverStep.idle);
      expect(state.transferProgress, 0.0);
    });

    test('onOpenHandDetected transitions idle → openHandDetected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(receiverProvider.notifier);

      notifier.onOpenHandDetected();
      expect(container.read(receiverProvider).step,
          ReceiverStep.openHandDetected);
    });

    test('onOpenHandDetected is ignored outside idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(receiverProvider.notifier);

      notifier.onOpenHandDetected();
      notifier.onOpenHandDetected();
      expect(container.read(receiverProvider).step,
          ReceiverStep.openHandDetected);
    });

    test('onHandLost resets to idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(receiverProvider.notifier);

      notifier.onOpenHandDetected();
      notifier.onHandLost();
      expect(container.read(receiverProvider).step, ReceiverStep.idle);
    });

    test('onReceivingStarted requires openHandDetected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(receiverProvider.notifier);

      // From idle it is ignored.
      notifier.onReceivingStarted();
      expect(container.read(receiverProvider).step, ReceiverStep.idle);

      notifier.onOpenHandDetected();
      notifier.onReceivingStarted();
      expect(container.read(receiverProvider).step, ReceiverStep.receiving);
    });

    test('completeReceive transitions receiving → completed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(receiverProvider.notifier);

      notifier.onOpenHandDetected();
      notifier.onReceivingStarted();
      notifier.completeReceive();

      final state = container.read(receiverProvider);
      expect(state.step, ReceiverStep.completed);
      expect(state.transferProgress, 1.0);
      expect(state.unpackProgress, 1.0);
    });

    test('setTransferMetadata populates sender and file info', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(receiverProvider.notifier);

      notifier.setTransferMetadata(
        senderName: 'Desktop-PC',
        senderDevice: '192.168.1.5',
        fileNames: const ['a.txt', 'b.png'],
        fileCount: 2,
        totalSize: '3.2 MB',
      );

      final state = container.read(receiverProvider);
      expect(state.senderName, 'Desktop-PC');
      expect(state.senderDevice, '192.168.1.5');
      expect(state.fileNames, ['a.txt', 'b.png']);
      expect(state.fileCount, 2);
      expect(state.totalSize, '3.2 MB');
    });
  });
}

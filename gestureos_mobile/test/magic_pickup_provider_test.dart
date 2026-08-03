import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/features/magic_transfer/domain/gesture_result.dart';
import 'package:gesture_os/features/magic_transfer/providers/magic_pickup_provider.dart';
import 'package:gesture_os/shared/models/app_file.dart';
import 'package:gesture_os/shared/providers/transfer_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GestureResult handResult({double confidence = 0.9}) => GestureResult(
        isHandDetected: true,
        confidence: confidence,
        openHandScore: 0.9,
        stage2Passed: true,
        stage3Passed: true,
      );

  Future<List<AppFile>> makeTempFiles(int count) async {
    final dir = await Directory.systemTemp.createTemp('gestureos_test');
    final files = <AppFile>[];
    for (int i = 0; i < count; i++) {
      final f = File('${dir.path}/file_$i.txt');
      await f.writeAsString('test content $i');
      files.add(AppFile(
        path: f.path,
        name: 'file_$i.txt',
        sizeBytes: await f.length(),
        extension: 'txt',
        category: FileCategory.documents,
        lastModified: DateTime.now(),
      ));
    }
    addTearDown(() => dir.delete(recursive: true));
    return files;
  }

  group('MagicPickupNotifier', () {
    test('initial state is idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(magicPickupProvider);
      expect(state.step, MagicPickupStep.idle);
      expect(state.packingProgress, 0.0);
    });

    test('onHandDetected transitions idle → openHandDetected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(magicPickupProvider.notifier);

      notifier.onHandDetected(handResult());
      expect(container.read(magicPickupProvider).step,
          MagicPickupStep.openHandDetected);
      expect(container.read(magicPickupProvider).confidence, 0.9);
    });

    test('onHandDetected is ignored outside idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(magicPickupProvider.notifier);

      notifier.onHandDetected(handResult());
      notifier.onHandDetected(handResult());
      expect(container.read(magicPickupProvider).step,
          MagicPickupStep.openHandDetected);
    });

    test('onHandLost during openHandDetected resets to idle', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(magicPickupProvider.notifier);

      notifier.onHandDetected(handResult());
      expect(container.read(magicPickupProvider).step,
          MagicPickupStep.openHandDetected);

      notifier.onHandLost();
      expect(container.read(magicPickupProvider).step, MagicPickupStep.idle);

      // The confirm timer must not fire after reset.
      await Future.delayed(const Duration(milliseconds: 700));
      expect(container.read(magicPickupProvider).step, MagicPickupStep.idle);
    });

    test('confirm timer completes packing with empty selection', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(magicPickupProvider.notifier);

      notifier.onHandDetected(handResult());
      expect(container.read(magicPickupProvider).step,
          MagicPickupStep.openHandDetected);

      // 500ms hold → confirm → packing with empty selection completes.
      await Future.delayed(const Duration(milliseconds: 700));
      expect(container.read(magicPickupProvider).step, MagicPickupStep.packed);
      expect(container.read(magicPickupProvider).packingProgress, 1.0);
    });

    test('full flow with files reaches packed with correct count', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(magicPickupProvider.notifier);
      final transfer = container.read(transferProvider.notifier);

      transfer.setFiles(await makeTempFiles(3));

      notifier.onHandDetected(handResult());
      await Future.delayed(const Duration(milliseconds: 700));

      expect(container.read(magicPickupProvider).step, MagicPickupStep.packed);
      expect(container.read(magicPickupProvider).selectedFileCount, 3);
      expect(container.read(magicPickupProvider).packingProgress, 1.0);
    });

    test('resetToIdle during packing does not complete to packed', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(magicPickupProvider.notifier);
      final transfer = container.read(transferProvider.notifier);

      // 50 files × 16ms yield = ~800ms packing window.
      transfer.setFiles(await makeTempFiles(50));

      notifier.onHandDetected(handResult());
      // Confirm fires at 500ms; packing is still in progress here.
      await Future.delayed(const Duration(milliseconds: 520));
      expect(container.read(magicPickupProvider).step, MagicPickupStep.packing);

      notifier.resetToIdle();
      expect(container.read(magicPickupProvider).step, MagicPickupStep.idle);

      // Wait past the full packing duration: must remain idle.
      await Future.delayed(const Duration(milliseconds: 1500));
      expect(container.read(magicPickupProvider).step, MagicPickupStep.idle);
    });

    test('transitionToCarrying sets carrying and transfer status', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(magicPickupProvider.notifier);

      notifier.onHandDetected(handResult());
      await Future.delayed(const Duration(milliseconds: 700));
      expect(container.read(magicPickupProvider).step, MagicPickupStep.packed);

      notifier.transitionToCarrying();
      expect(container.read(magicPickupProvider).step, MagicPickupStep.carrying);
      expect(container.read(transferProvider).status, TransferState.carrying);
    });

    test('transitionToCarrying is ignored unless packed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(magicPickupProvider.notifier);

      notifier.transitionToCarrying();
      expect(container.read(magicPickupProvider).step, MagicPickupStep.idle);
    });

    test('advanceToOpenHandDetected starts the flow and completes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(magicPickupProvider.notifier);

      notifier.advanceToOpenHandDetected();
      expect(container.read(magicPickupProvider).step,
          MagicPickupStep.openHandDetected);

      // Empty selection: confirm → packing completes.
      await Future.delayed(const Duration(milliseconds: 700));
      expect(container.read(magicPickupProvider).step, MagicPickupStep.packed);
    });
  });
}

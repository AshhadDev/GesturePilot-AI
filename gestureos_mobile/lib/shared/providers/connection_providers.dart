import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/shared/services/connection_manager.dart';

/// Synchronized connection state streamed from [ConnectionManager].
/// Both desktop and mobile expose the same phases.
final connectionStateProvider = StreamProvider<ConnectionSnapshot>((ref) {
  return ConnectionManager.instance.stateStream;
});

/// Current connection phase as a simple value for quick reads.
final connectionPhaseProvider = Provider<ConnectionPhase>((ref) {
  return ConnectionManager.instance.currentState.phase;
});

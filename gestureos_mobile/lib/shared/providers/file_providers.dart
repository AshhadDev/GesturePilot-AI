import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/shared/models/app_file.dart';
import 'package:gesture_os/shared/providers/permission_provider.dart';
import 'package:gesture_os/shared/services/file_service.dart';

class FileListState {
  const FileListState({
    this.files = const [],
    this.isLoading = false,
    this.error,
  });

  final List<AppFile> files;
  final bool isLoading;
  final String? error;

  FileListState copyWith({
    List<AppFile>? files,
    bool? isLoading,
    String? error,
  }) {
    return FileListState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FileListNotifier extends StateNotifier<FileListState> {
  FileListNotifier(this._ref) : super(const FileListState()) {
    _listenToPermissions();
  }

  final Ref _ref;

  void _listenToPermissions() {
    _ref.listen<PermissionStateData>(permissionProvider, (prev, next) {
      if (next.canAccessFiles && prev?.canAccessFiles != true) {
        loadFiles(FileCategory.all);
      }
    });
    final perm = _ref.read(permissionProvider);
    if (perm.canAccessFiles) {
      loadFiles(FileCategory.all);
    }
  }

  Future<void> loadFiles(FileCategory category) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final files = await FileService.getFiles(category);
      state = state.copyWith(files: files, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load files',
      );
    }
  }
}

final fileListProvider =
    StateNotifierProvider<FileListNotifier, FileListState>((ref) {
  return FileListNotifier(ref);
});

/// Current category filter
final categoryProvider = StateProvider<FileCategory>(
  (ref) => FileCategory.all,
);

/// Search query string
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered files based on category + search
final filteredFilesProvider = Provider<AsyncValue<List<AppFile>>>((ref) {
  final fileList = ref.watch(fileListProvider);
  final category = ref.watch(categoryProvider);
  final query = ref.watch(searchQueryProvider);

  if (fileList.isLoading) {
    return const AsyncValue.loading();
  }
  if (fileList.error != null) {
    return AsyncValue.error(fileList.error!, StackTrace.empty);
  }

  var files = FileService.filterByCategory(fileList.files, category);
  files = FileService.searchFiles(files, query);
  return AsyncValue.data(files);
});

/// Selected files for transfer
final selectedFilesProvider = StateProvider<List<AppFile>>((ref) => []);

/// Total size of selected files
final selectedTotalSizeProvider = Provider<int>((ref) {
  final selected = ref.watch(selectedFilesProvider);
  return selected.fold(0, (sum, f) => sum + f.sizeBytes);
});

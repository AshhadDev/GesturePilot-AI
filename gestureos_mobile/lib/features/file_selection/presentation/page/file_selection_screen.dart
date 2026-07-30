import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gesture_os/app/router/route_names.dart';
import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/core/widgets/empty_state.dart';
import 'package:gesture_os/core/widgets/file_skeleton.dart';
import 'package:gesture_os/core/widgets/file_tile.dart';
import 'package:gesture_os/shared/models/app_file.dart';
import 'package:gesture_os/shared/providers/file_providers.dart';
import 'package:gesture_os/shared/providers/permission_provider.dart';
import 'package:gesture_os/shared/providers/transfer_provider.dart';

/// Premium file picker UI with categories, search, and multi-select.
/// Uses real device storage via permission_handler + dart:io.
class FileSelectionScreen extends ConsumerStatefulWidget {
  const FileSelectionScreen({super.key});

  @override
  ConsumerState<FileSelectionScreen> createState() =>
      _FileSelectionScreenState();
}

class _FileSelectionScreenState extends ConsumerState<FileSelectionScreen> {
  final _searchController = TextEditingController();

  static const _categories = [
    FileCategory.all,
    FileCategory.images,
    FileCategory.videos,
    FileCategory.documents,
  ];

  static const _categoryLabels = {
    FileCategory.all: 'All',
    FileCategory.images: 'Images',
    FileCategory.videos: 'Videos',
    FileCategory.documents: 'Docs',
    FileCategory.downloads: 'Downloads',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transfer = ref.watch(transferProvider);
    final selectedCount = transfer.selectedFiles.length;
    final perm = ref.watch(permissionProvider);
    final filtered = ref.watch(filteredFilesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: perm.canAccessFiles
            ? Column(
                children: [
                  _buildHeader(),
                  _buildSearchBar(),
                  _buildCategoryTabs(),
                  Expanded(child: _buildFileGrid(filtered)),
                ],
              )
            : _buildPermissionView(perm),
      ),
      bottomSheet: selectedCount > 0
          ? _buildContinueButton(selectedCount)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.goNamed(RouteNames.home),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Select Files',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionView(PermissionStateData perm) {
    if (perm.isRequesting) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyStateWidget(
            title: 'Storage Access Required',
            subtitle:
                'GestureOS needs access to your files to select and transfer them.',
            icon: Icons.folder_off_rounded,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () =>
                    ref.read(permissionProvider.notifier).requestPermission(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Grant Access',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        controller: _searchController,
        onChanged: (v) =>
            ref.read(searchQueryProvider.notifier).state = v,
        style: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Search files...',
          hintStyle: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final selectedCat = ref.watch(categoryProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: _categories.map((cat) {
          final isActive = cat == selectedCat;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(categoryProvider.notifier).state = cat,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.border,
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  _categoryLabels[cat] ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFileGrid(AsyncValue<List<AppFile>> filtered) {
    return filtered.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: 9,
          itemBuilder: (context, index) => const FileSkeleton(),
        ),
      ),
      error: (e, st) => EmptyStateWidget(
        title: 'Error loading files',
        subtitle: 'Please try again or check storage permissions.',
        icon: Icons.error_outline_rounded,
      ),
      data: (files) {
        if (files.isEmpty) {
          return const EmptyStateWidget(
            title: 'No files found',
            subtitle: 'Try a different category or search term.',
          );
        }
        final selectedFiles =
            ref.watch(transferProvider).selectedFiles;
        final selectedPaths =
            selectedFiles.map((f) => f.path).toSet();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final isSelected = selectedPaths.contains(file.path);
              return FileTile(
                file: file,
                isSelected: isSelected,
                onToggle: () => ref
                    .read(transferProvider.notifier)
                    .toggleFile(file),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildContinueButton(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: GestureDetector(
        onTap: () {
          ref
              .read(transferProvider.notifier)
              .setStatus(TransferState.magicTransfer);
          context.goNamed(RouteNames.magicTransfer);
        },
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Continue with $count file${count > 1 ? 's' : ''}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

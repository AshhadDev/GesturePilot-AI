import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/core/theme/app_dimensions.dart';
import 'package:gestureos_desktop/core/utils/file_utils.dart';
import 'package:gestureos_desktop/core/widgets/desktop_app_bar.dart';
import 'package:gestureos_desktop/core/widgets/empty_state.dart';
import 'package:gestureos_desktop/core/widgets/transfer_history_tile.dart';
import 'package:gestureos_desktop/shared/models/app_models.dart';
import 'package:gestureos_desktop/shared/providers/app_providers.dart';

class TransferHistoryScreen extends ConsumerStatefulWidget {
  const TransferHistoryScreen({super.key});

  @override
  ConsumerState<TransferHistoryScreen> createState() =>
      _TransferHistoryScreenState();
}

class _TransferHistoryScreenState
    extends ConsumerState<TransferHistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openTransfer(TransferHistoryItem item) {
    final path = item.filePath;
    if (path != null && path.isNotEmpty) openFileWithDefaultApp(path);
  }

  void _revealTransfer(TransferHistoryItem item) {
    final path = item.filePath;
    if (path != null && path.isNotEmpty) revealInFolder(path);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredHistoryProvider);

    return Column(
      children: [
        const DesktopAppBar(title: 'Transfer History'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingXl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: AppDimensions.spacingMd),
                _buildToolbar(),
                const SizedBox(height: AppDimensions.spacingLg),
                _buildTableHeader(),
                const SizedBox(height: AppDimensions.spacingSm),
                Expanded(
                  child: filtered.isEmpty
                      ? const EmptyState(
                          title: 'No transfers found',
                          subtitle: 'Try a different search or filter',
                          icon: Icons.search_off_rounded,
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(
                                  height: AppDimensions.spacingSm),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return TransferHistoryTile(
                              item: item,
                              onOpenFile: () => _openTransfer(item),
                              onOpenFolder: () => _revealTransfer(item),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (v) =>
          ref.read(transferSearchProvider.notifier).state = v,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Search transfer history...',
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textTertiary,
          size: 22,
        ),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
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
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(null, 'All'),
                const SizedBox(width: AppDimensions.spacingSm),
                _buildFilterChip(TransferStatus.completed, 'Completed'),
                const SizedBox(width: AppDimensions.spacingSm),
                _buildFilterChip(TransferStatus.failed, 'Failed'),
                const SizedBox(width: AppDimensions.spacingSm),
                _buildFilterChip(TransferStatus.pending, 'Pending'),
                const SizedBox(width: AppDimensions.spacingSm),
                _buildFilterChip(TransferStatus.inProgress, 'In Progress'),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        _buildSortControl(),
      ],
    );
  }

  Widget _buildFilterChip(TransferStatus? status, String label) {
    final selected =
        ref.watch(transferStatusFilterProvider) == status;
    final accent = selected ? AppColors.accent : AppColors.textTertiary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () =>
            ref.read(transferStatusFilterProvider.notifier).state = status,
        child: AnimatedContainer(
          duration: AppDimensions.animFast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.card,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortControl() {
    final sort = ref.watch(transferSortProvider);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: PopupMenuButton<TransferSort>(
        color: AppColors.surface,
        tooltip: 'Sort transfers',
        onSelected: (v) =>
            ref.read(transferSortProvider.notifier).state = v,
        itemBuilder: (context) => [
          for (final option in TransferSort.values)
            PopupMenuItem(
              value: option,
              child: Row(
                children: [
                  Icon(_sortIcon(option), color: AppColors.accent, size: 18),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Text(
                    _sortLabel(option),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  if (sort == option)
                    const Icon(
                      Icons.check_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                ],
              ),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.spacingSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_sortIcon(sort), color: AppColors.accent, size: 18),
              const SizedBox(width: AppDimensions.spacingSm),
              Text(
                _sortLabel(sort),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingXs),
              const Icon(
                Icons.arrow_drop_down_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _sortIcon(TransferSort sort) {
    switch (sort) {
      case TransferSort.newest:
        return Icons.schedule_rounded;
      case TransferSort.oldest:
        return Icons.history_rounded;
      case TransferSort.largest:
        return Icons.trending_up_rounded;
      case TransferSort.smallest:
        return Icons.trending_down_rounded;
      case TransferSort.fastest:
        return Icons.speed_rounded;
    }
  }

  String _sortLabel(TransferSort sort) {
    switch (sort) {
      case TransferSort.newest:
        return 'Newest';
      case TransferSort.oldest:
        return 'Oldest';
      case TransferSort.largest:
        return 'Largest';
      case TransferSort.smallest:
        return 'Smallest';
      case TransferSort.fastest:
        return 'Fastest';
    }
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
      ),
      child: Row(
        children: [
          const SizedBox(width: 60),
          const SizedBox(width: AppDimensions.spacingMd),
          const Expanded(
            flex: 3,
            child: Text(
              'File',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Text(
              'Size',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Text(
              'Status',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          const Expanded(
            flex: 1,
            child: Text(
              'Time',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

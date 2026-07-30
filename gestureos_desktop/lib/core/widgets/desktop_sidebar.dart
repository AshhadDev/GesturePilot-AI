import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gestureos_desktop/app/router/route_names.dart';
import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/core/theme/app_dimensions.dart';

class DesktopSidebar extends StatefulWidget {
  const DesktopSidebar({super.key, required this.currentPath});

  final String currentPath;

  @override
  State<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<DesktopSidebar> {
  bool _isHoveringPair = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.spacingLg),
          _buildLogo(),
          const SizedBox(height: AppDimensions.spacingXl),
          _buildNavSection('Main', [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              path: RouteNames.homePath,
            ),
            _NavItem(
              icon: Icons.history_rounded,
              label: 'History',
              path: RouteNames.historyPath,
            ),
            _NavItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              path: RouteNames.settingsPath,
            ),
          ]),
          const Spacer(),
          _buildPairButton(),
          const SizedBox(height: AppDimensions.spacingLg),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingLg,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.touch_app_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Text(
            'GestureOS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavSection(String title, List<_NavItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingLg,
          ),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        ...items.map((item) => _buildNavItem(item)),
      ],
    );
  }

  Widget _buildNavItem(_NavItem item) {
    final isActive = widget.currentPath == item.path;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: 2,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go(item.path),
          child: AnimatedContainer(
            duration: AppDimensions.animFast,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isActive ? AppColors.accent : AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPairButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHoveringPair = true),
        onExit: (_) => setState(() => _isHoveringPair = false),
        child: GestureDetector(
          onTap: () => context.goNamed(RouteNames.pairDevice),
          child: AnimatedContainer(
            duration: AppDimensions.animFast,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: _isHoveringPair ? AppColors.primaryGradient : null,
              color: _isHoveringPair ? null : AppColors.card,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: _isHoveringPair
                    ? AppColors.primary
                    : AppColors.border,
                width: 1,
              ),
              boxShadow: _isHoveringPair
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 18,
                  color: _isHoveringPair
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimensions.spacingSm),
                Text(
                  'Pair Device',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isHoveringPair
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;
}

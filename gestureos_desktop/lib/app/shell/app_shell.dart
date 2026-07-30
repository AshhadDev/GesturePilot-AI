import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/core/widgets/desktop_sidebar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          DesktopSidebar(
            currentPath: GoRouterState.of(context).uri.path,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

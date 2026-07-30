import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/shared/models/onboarding_data.dart';

/// Individual onboarding page content matching reference design exactly.
/// Layout: SVG illustration (35-40% upper), title, description.
class OnboardingPageContent extends StatefulWidget {
  const OnboardingPageContent({
    super.key,
    required this.data,
  });

  final OnboardingData data;

  @override
  State<OnboardingPageContent> createState() => _OnboardingPageContentState();
}

class _OnboardingPageContentState extends State<OnboardingPageContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _floatAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _floatController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Hand illustration with floating animation
          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_floatAnimation.value),
                child: child,
              );
            },
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.7,
              height: MediaQuery.sizeOf(context).height * 0.35,
              child: SvgPicture.asset(
                widget.data.svgAsset,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const Spacer(flex: 1),

          // Title
          _buildTitle(),

          const SizedBox(height: 20),

          // Description
          _buildDescription(),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widget.data.titleLines.map((line) {
        final isPurpleLine = line == widget.data.purpleWord;
        return Text(
          line,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: isPurpleLine ? AppColors.secondary : AppColors.textPrimary,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDescription() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.7,
      child: Text(
        widget.data.description,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.6,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

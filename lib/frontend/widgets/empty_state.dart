import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'custom_button.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    this.title = 'No RideMate found for this route yet.',
    this.message = 'Try another date, time, or route.',
    this.icon = Icons.search_off_rounded,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 52,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            if (buttonText != null) ...[
              const SizedBox(height: 28),
              CustomButton(
                text: buttonText!,
                onPressed: onButtonPressed ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Create Ride feature will be available in the next release.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                isOutlined: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

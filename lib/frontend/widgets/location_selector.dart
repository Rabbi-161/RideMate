import 'package:flutter/material.dart';
import '../../models/location.dart';
import '../theme/app_theme.dart';

class LocationSelector extends StatelessWidget {
  final String label;
  final Location? selectedLocation;
  final String placeholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final IconData icon;
  final Color? iconColor;

  const LocationSelector({
    super.key,
    required this.label,
    required this.selectedLocation,
    required this.placeholder,
    required this.onTap,
    this.onClear,
    this.icon = Icons.location_on_outlined,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = selectedLocation != null;
    final effectiveColor = iconColor ?? AppTheme.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasSelection
                  ? effectiveColor.withValues(alpha: 0.5)
                  : AppTheme.borderColor,
              width: hasSelection ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: effectiveColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasSelection ? selectedLocation!.displayText : placeholder,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: hasSelection ? FontWeight.w700 : FontWeight.w400,
                        color: hasSelection ? AppTheme.textPrimary : AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasSelection) ...[
                      const SizedBox(height: 2),
                      Text(
                        selectedLocation!.fullHierarchy,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (hasSelection && onClear != null)
                IconButton(
                  icon: const Icon(
                    Icons.cancel_rounded,
                    color: AppTheme.textMuted,
                    size: 18,
                  ),
                  tooltip: 'Clear location',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onClear,
                )
              else
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textMuted,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

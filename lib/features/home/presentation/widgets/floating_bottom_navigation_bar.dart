import 'package:flutter/material.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';

class FloatingNavigationDestination {
  final IconData icon;
  final String label;

  const FloatingNavigationDestination({
    required this.icon,
    required this.label,
  });
}

class FloatingBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<FloatingNavigationDestination> destinations;

  const FloatingBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: (isDark ? DarkColors.surface : Colors.white).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(destinations.length, (index) {
                  final destination = destinations[index];
                  final isSelected = index == selectedIndex;
                  
                  // Active: Theme Primary. Inactive: Grey/Neutral
                  final activeColor = theme.colorScheme.primary; 
                  final inactiveColor = isDark ? AppColors.grey300 : AppColors.grey600;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onDestinationSelected(index),
                      behavior: HitTestBehavior.opaque,
                      child: Semantics(
                        label: destination.label,
                        selected: isSelected,
                        button: true,
                        child: AnimatedScale(
                          scale: isSelected ? 1.08 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? activeColor.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  destination.icon,
                                  color: isSelected ? activeColor : inactiveColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Text Label
                              Text(
                                destination.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontFamily: 'Geist',
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? activeColor : inactiveColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              // Subtle active dot indicator at the bottom
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isSelected ? 5 : 0,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: activeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      );
  }
}

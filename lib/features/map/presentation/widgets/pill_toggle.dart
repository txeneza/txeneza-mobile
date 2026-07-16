import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import 'txeneza_map.dart';

class PillToggle extends StatelessWidget {
  final MapMode mapMode;
  final ValueChanged<MapMode> onChanged;

  const PillToggle({
    super.key,
    required this.mapMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const double width = 180.0;
    const double height = 38.0;
    const double padding = 4.0;
    const double toggleWidth = (width - (padding * 2)) / 2;
    const double toggleHeight = height - (padding * 2);

    final int activeIndex = switch (mapMode) {
      MapMode.normal => 0,
      MapMode.heatmap => 1,
      _ => 0, // Fallback
    };

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(19),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(padding),
        child: Stack(
          children: [
            // Sliding Background Indicator
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              left: activeIndex * toggleWidth,
              top: 0,
              width: toggleWidth,
              height: toggleHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 3,
                      offset: Offset(0, 1.5),
                    ),
                  ],
                ),
              ),
            ),

            // Toggle Items
            Row(
              children: [
                // Mapa (Normal Point View)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(MapMode.normal),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.map,
                            size: 13,
                            color: activeIndex == 0
                                ? AppColors.forestGreen
                                : AppColors.forestGreen.withValues(alpha: 0.45),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Mapa',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 11,
                              fontWeight: activeIndex == 0 ? FontWeight.bold : FontWeight.w500,
                              color: activeIndex == 0
                                  ? AppColors.forestGreen
                                  : AppColors.forestGreen.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Calor (Heatmap View)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(MapMode.heatmap),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.flame,
                            size: 13,
                            color: activeIndex == 1
                                ? const Color(0xFFFF5722) // Warm Orange/Red
                                : AppColors.forestGreen.withValues(alpha: 0.45),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Calor',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 11,
                              fontWeight: activeIndex == 1 ? FontWeight.bold : FontWeight.w500,
                              color: activeIndex == 1
                                  ? const Color(0xFFFF5722)
                                  : AppColors.forestGreen.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

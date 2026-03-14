import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class HorizonSelector extends StatelessWidget {
  final String selectedKey;
  final List<String> keys;
  final List<String> labels;
  final bool isDark;
  final ValueChanged<String> onSelect;

  const HorizonSelector({
    super.key,
    required this.selectedKey,
    required this.keys,
    required this.labels,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(keys.length, (i) {
          final isSelected = keys[i] == selectedKey;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(keys[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

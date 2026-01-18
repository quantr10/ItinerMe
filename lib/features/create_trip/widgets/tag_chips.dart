import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class TagChips<T> extends StatelessWidget {
  final List<T> tags;
  final String Function(T) itemText;
  final Function(T) onDelete;

  const TagChips({
    super.key,
    required this.tags,
    required this.itemText,
    required this.onDelete,
  });

  // GENERIC TAG CHIP LIST
  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox();

    return AnimatedSize(
      duration: AppTheme.animationDuration,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            tags.map((tag) {
              final tagText = itemText(tag);
              return Container(
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  color: AppTheme.primaryColor,
                  boxShadow: [AppTheme.defaultShadow],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        tagText,
                        style: const TextStyle(
                          fontSize: AppTheme.defaultFontSize,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => onDelete(tag),
                        child: const Icon(
                          Icons.close,
                          size: AppTheme.mediumIconFont,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

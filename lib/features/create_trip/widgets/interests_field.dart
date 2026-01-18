import 'package:flutter/material.dart';

import '../../../../core/enums/interest_tag_enums.dart';
import '../../../../core/theme/app_theme.dart';

class InterestsField extends StatelessWidget {
  final TextEditingController controller;
  final List<InterestTag> availableTags;
  final List<InterestTag> interestPredictions;
  final List<InterestTag> interests;
  final Function(String) onSearch;
  final Function(InterestTag) onAdd;
  final Function(InterestTag) onRemove;

  const InterestsField({
    super.key,
    required this.controller,
    required this.availableTags,
    required this.interestPredictions,
    required this.interests,
    required this.onSearch,
    required this.onAdd,
    required this.onRemove,
  });

  // INTERESTS INPUT FIELD
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== INPUT ROW =====
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: AppTheme.fieldHeight,
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: onSearch,
                  decoration: AppTheme.inputDecoration(
                    'Add Interests',
                    onClear: () {
                      controller.clear();
                      onSearch('');
                    },
                  ),
                  style: const TextStyle(fontSize: AppTheme.defaultFontSize),
                ),
              ),
            ),
            const SizedBox(width: 8),

            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;

                InterestTag? match;
                try {
                  match = availableTags.firstWhere(
                    (t) => t.label.toLowerCase() == text.toLowerCase(),
                  );
                } catch (_) {
                  match = null;
                }

                if (match == null) return;

                onAdd(match);
                controller.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        ),

        // ===== PREDICTION DROPDOWN =====
        if (interestPredictions.isNotEmpty)
          AnimatedContainer(
            duration: AppTheme.animationDuration,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              boxShadow: [AppTheme.defaultShadow],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: interestPredictions.length,
              itemBuilder: (context, index) {
                final tag = interestPredictions[index];
                return ListTile(
                  leading: const Icon(
                    Icons.label,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text(
                    tag.label,
                    style: const TextStyle(
                      fontSize: AppTheme.defaultFontSize,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () => onAdd(tag),
                );
              },
            ),
          ),

        // ===== SELECTED CHIPS =====
        if (interests.isNotEmpty) ...[
          AppTheme.smallSpacing,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                interests.map((tag) {
                  return Container(
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                      color: AppTheme.primaryColor,
                      boxShadow: [AppTheme.defaultShadow],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tag.label,
                            style: const TextStyle(
                              fontSize: AppTheme.defaultFontSize,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => onRemove(tag),
                            child: const Icon(
                              Icons.close,
                              size: AppTheme.mediumIconFont,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }
}

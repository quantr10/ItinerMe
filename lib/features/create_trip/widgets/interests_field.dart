import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class InterestsField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> availableTags;
  final List<String> interestPredictions;
  final List<String> interests;
  final Function(String) onSearch;
  final Function(String) onAdd;
  final Function(String) onRemove;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                if (controller.text.trim().isNotEmpty) {
                  onAdd(controller.text);
                  controller.clear();
                }
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
                final interest = interestPredictions[index];
                return ListTile(
                  leading: Icon(Icons.label, color: AppTheme.primaryColor),
                  title: Text(
                    interest,
                    style: TextStyle(
                      fontSize: AppTheme.defaultFontSize,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () => onAdd(interest),
                );
              },
            ),
          ),

        if (interests.isNotEmpty) ...[
          AppTheme.smallSpacing,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                interests.map((interest) {
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
                            interest,
                            style: TextStyle(
                              fontSize: AppTheme.defaultFontSize,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => onRemove(interest),
                            child: Icon(
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

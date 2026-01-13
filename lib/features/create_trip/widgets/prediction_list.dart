import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PredictionList<T> extends StatelessWidget {
  final List<T> predictions;
  final Function(T) onSelect;
  final IconData icon;
  final String Function(T) itemText;

  const PredictionList({
    super.key,
    required this.predictions,
    required this.onSelect,
    required this.icon,
    required this.itemText,
  });

  @override
  Widget build(BuildContext context) {
    if (predictions.isEmpty) return const SizedBox();

    return AnimatedContainer(
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
        itemCount: predictions.length,
        itemBuilder:
            (context, index) => ListTile(
              leading: Icon(icon, color: AppTheme.primaryColor),
              title: Text(
                itemText(predictions[index]),
                style: TextStyle(
                  fontSize: AppTheme.defaultFontSize,
                  color: Colors.black,
                ),
              ),
              onTap: () => onSelect(predictions[index]),
            ),
      ),
    );
  }
}

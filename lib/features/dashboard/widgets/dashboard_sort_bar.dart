import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/enums/sort_enums.dart';

class DashboardSortBar extends StatelessWidget {
  final SortOption option;
  final SortOrder order;
  final ValueChanged<SortOption> onSortChange;
  final VoidCallback onToggleOrder;

  const DashboardSortBar({
    super.key,
    required this.option,
    required this.order,
    required this.onSortChange,
    required this.onToggleOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.fieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [AppTheme.defaultShadow],
        border: Border.all(color: Colors.white, width: AppTheme.borderWidth),
      ),
      child: Row(
        children: [
          // Sort icon
          Icon(
            Icons.sort,
            size: AppTheme.largeIconFont,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 24),

          // Dropdown sort option
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<SortOption>(
                value: option,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  size: AppTheme.largeIconFont,
                  color: AppTheme.primaryColor,
                ),
                decoration: const InputDecoration.collapsed(hintText: ''),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                style: const TextStyle(
                  fontSize: AppTheme.defaultFontSize,
                  color: Colors.black,
                ),
                items: const [
                  DropdownMenuItem(value: SortOption.name, child: Text('Name')),
                  DropdownMenuItem(
                    value: SortOption.startDate,
                    child: Text('Start Date'),
                  ),
                  DropdownMenuItem(
                    value: SortOption.location,
                    child: Text('Location'),
                  ),
                ],
                onChanged: (SortOption? value) {
                  if (value != null) {
                    onSortChange(value);
                  }
                },
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Asc / Desc toggle
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleOrder,
            child: Icon(
              order == SortOrder.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: AppTheme.largeIconFont,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/enums/transportation_enums.dart';
import '../../../../core/theme/app_theme.dart';

class TransportationDropdown extends StatelessWidget {
  final TransportationType? value;
  final Function(TransportationType) onChanged;

  const TransportationDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  // TRANSPORTATION SELECT DROPDOWN
  @override
  Widget build(BuildContext context) {
    final items = TransportationType.values;

    return SizedBox(
      height: AppTheme.fieldHeight,
      child: DropdownButtonFormField<TransportationType>(
        value: value,
        isExpanded: true,
        style: const TextStyle(fontSize: AppTheme.defaultFontSize),
        decoration: AppTheme.inputDecoration('Transportation').copyWith(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          isDense: true,
        ),
        items:
            items.map((t) {
              return DropdownMenuItem(
                value: t,
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Icon(
                        t.icon,
                        color: AppTheme.primaryColor,
                        size: AppTheme.largeIconFont,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        t.label,
                        style: const TextStyle(
                          fontSize: AppTheme.defaultFontSize,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        onChanged: (v) => v != null ? onChanged(v) : null,
        dropdownColor: Colors.white,
        icon: const Icon(
          Icons.arrow_drop_down,
          size: AppTheme.largeIconFont,
          color: AppTheme.primaryColor,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
    );
  }
}

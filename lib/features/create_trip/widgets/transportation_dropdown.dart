import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TransportationDropdown extends StatelessWidget {
  final String? value;
  final Function(String) onChanged;

  const TransportationDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'car':
        return Icons.directions_car;
      case 'bus/metro':
        return Icons.directions_bus;
      case 'motorbike':
        return Icons.motorcycle;
      default:
        return Icons.directions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ['Bus/Metro', 'Car', 'Motorbike'];

    return SizedBox(
      height: AppTheme.fieldHeight,
      child: DropdownButtonFormField<String>(
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
                        _getIcon(t),
                        color: AppTheme.primaryColor,
                        size: AppTheme.largeIconFont,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        t,
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
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
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

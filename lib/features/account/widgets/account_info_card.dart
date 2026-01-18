import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AccountInfoCard extends StatelessWidget {
  final String email;
  final String name;

  const AccountInfoCard({super.key, required this.email, required this.name});

  // ACCOUNT INFO CARD UI
  @override
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: AppTheme.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(Icons.email, email),
            const Divider(
              thickness: 1,
              color: AppTheme.primaryColor,
            ), // Divider nhẹ
            _infoRow(Icons.person, name),
          ],
        ),
      ),
    );
  }

  // INFO ROW BUILDER
  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }
}

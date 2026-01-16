import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class EmptyDashboardState extends StatelessWidget {
  final bool isSearching;

  const EmptyDashboardState({super.key, required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.travel_explore,
            size: 60,
            color: AppTheme.secondaryColor,
          ),
          AppTheme.mediumSpacing,

          Text(
            isSearching ? 'No results found' : 'No trips available',
            style: TextStyle(
              fontSize: AppTheme.largeFontSize,
              color: AppTheme.hintColor,
            ),
          ),

          AppTheme.smallSpacing,
          Text(
            isSearching
                ? 'Try searching with a different keyword'
                : 'Start planning your first trip!',
            style: TextStyle(
              fontSize: AppTheme.defaultFontSize,
              color: AppTheme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

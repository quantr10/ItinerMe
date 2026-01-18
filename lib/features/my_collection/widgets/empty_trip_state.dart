import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class EmptyTripState extends StatelessWidget {
  final bool showingMyTrips;
  final bool isSearching;

  const EmptyTripState({
    super.key,
    required this.showingMyTrips,
    required this.isSearching,
  });

  // EMPTY MY COLLECTION STATE
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching
                ? Icons.search_off
                : showingMyTrips
                ? Icons.travel_explore
                : Icons.bookmark_border,
            size: 60,
            color: AppTheme.secondaryColor,
          ),
          AppTheme.mediumSpacing,
          Text(
            isSearching
                ? 'No results found'
                : showingMyTrips
                ? 'No trips created yet'
                : 'No trips saved yet',
            style: TextStyle(
              fontSize: AppTheme.largeFontSize,
              color: AppTheme.hintColor,
            ),
          ),
          AppTheme.smallSpacing,
          Text(
            isSearching
                ? 'Try searching with a different keyword'
                : showingMyTrips
                ? 'Start planning your first trip!'
                : 'Save trips to see them here',
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/trip.dart';
import '../../../core/theme/app_theme.dart';

// TRIP INFO HEADER
class TripInfoHeader extends StatelessWidget {
  final Trip trip;
  final bool canEdit;
  final VoidCallback onPickDate;
  final Function(int) onSelectDay;

  const TripInfoHeader({
    super.key,
    required this.trip,
    required this.canEdit,
    required this.onPickDate,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TRIP NAME
        Text(
          trip.name,
          style: const TextStyle(
            fontSize: AppTheme.titleFontSize,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),

        AppTheme.smallSpacing,

        // LOCATION
        Text(
          trip.location,
          style: const TextStyle(
            fontSize: AppTheme.defaultFontSize,
            fontWeight: FontWeight.bold,
            color: AppTheme.hintColor,
          ),
        ),

        // DATE RANGE
        Text(
          '${DateFormat('EEE, MMM d').format(trip.startDate)} - '
          '${DateFormat('EEE, MMM d').format(trip.endDate)}',
          style: const TextStyle(
            fontSize: AppTheme.defaultFontSize,
            fontWeight: FontWeight.bold,
            color: AppTheme.hintColor,
          ),
        ),

        AppTheme.mediumSpacing,

        // CALENDAR BUTTON + DAY SELECTOR
        Row(
          children: [
            // ===== CALENDAR EDIT BUTTON =====
            if (canEdit)
              Row(
                children: [
                  InkWell(
                    onTap: onPickDate,
                    borderRadius: BorderRadius.circular(
                      AppTheme.largeBorderRadius,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [AppTheme.defaultShadow],
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: AppTheme.largeIconFont,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

            // ===== DAY SELECTOR =====
            Expanded(
              child: SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: trip.itinerary.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final date = trip.itinerary[index].date;

                    return InkWell(
                      onTap: () => onSelectDay(index),
                      borderRadius: BorderRadius.circular(
                        AppTheme.largeBorderRadius,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: AppTheme.borderWidth,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                          boxShadow: [AppTheme.defaultShadow],
                        ),
                        child: Text(
                          DateFormat('MMM d').format(date),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: AppTheme.defaultFontSize,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../trip_detail/screen/trip_detail_screen.dart';
import '../../../core/models/trip.dart';
import '../../../core/theme/app_theme.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final DateFormat formatter;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const TripCard({
    required this.trip,
    required this.formatter,
    required this.isSaved,
    required this.onToggleSave,
    Key? key,
  }) : super(key: key);

  // TRIP CARD
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TripDetailScreen(trip: trip, currentIndex: 0),
              fullscreenDialog: true,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== COVER IMAGE + SAVE BUTTON =====
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.borderRadius),
                  ),
                  child: Image.network(
                    trip.coverImageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          height: 160,
                          color: AppTheme.secondaryColor.withOpacity(0.2),
                          child: const Center(
                            child: Icon(
                              Icons.photo,
                              size: 48,
                              color: AppTheme.hintColor,
                            ),
                          ),
                        ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: onToggleSave,
                    borderRadius: BorderRadius.circular(
                      AppTheme.largeBorderRadius,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [AppTheme.defaultShadow],
                      ),
                      child: Icon(
                        isSaved ? Icons.favorite : Icons.favorite_border,
                        color:
                            isSaved
                                ? AppTheme.errorColor
                                : AppTheme.primaryColor,
                        size: AppTheme.largeIconFont,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ===== TRIP INFO =====
            Padding(
              padding: AppTheme.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTheme.largeFontSize,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: AppTheme.largeIconFont,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trip.location,
                        style: const TextStyle(
                          fontSize: AppTheme.defaultFontSize,
                          color: AppTheme.hintColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: AppTheme.largeIconFont,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${formatter.format(trip.startDate)} - ${formatter.format(trip.endDate)}',
                        style: const TextStyle(
                          fontSize: AppTheme.defaultFontSize,
                          color: AppTheme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

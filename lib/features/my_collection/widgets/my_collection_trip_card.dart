import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../trip_detail/screen/trip_detail_screen.dart';

import '../../../core/models/trip.dart';
import '../../../core/enums/tab_enum.dart';
import '../../../core/theme/app_theme.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final DateFormat formatter;
  final TripCardMode mode;

  final VoidCallback? onDelete;
  final VoidCallback? onRemove;
  final VoidCallback? onCopy;

  const TripCard({
    super.key,
    required this.trip,
    required this.formatter,
    required this.mode,
    this.onDelete,
    this.onRemove,
    this.onCopy,
  });

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
              builder: (_) => TripDetailScreen(trip: trip, currentIndex: 1),
              fullscreenDialog: true,
            ),
          );
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          trip.coverImageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                width: 120,
                                height: 120,
                                color: AppTheme.secondaryColor.withOpacity(0.2),
                                child: const Icon(
                                  Icons.photo,
                                  size: 36,
                                  color: AppTheme.hintColor,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: AppTheme.largeFontSize,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: AppTheme.mediumIconFont,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      trip.location,
                                      style: const TextStyle(
                                        fontSize: AppTheme.defaultFontSize,
                                        color: AppTheme.hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: AppTheme.mediumIconFont,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 6),
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
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (mode == TripCardMode.saved) ...[
                                    _buildAction(
                                      Icons.copy,
                                      onCopy,
                                      tooltip: 'Duplicate trip',
                                    ),
                                    const SizedBox(width: 4),
                                    _buildAction(
                                      Icons.favorite,
                                      onRemove,
                                      color: AppTheme.errorColor,
                                      tooltip: 'Remove from saved',
                                    ),
                                  ],
                                  if (mode == TripCardMode.myTrips)
                                    _buildAction(
                                      Icons.delete_outline,
                                      onDelete,
                                      color: AppTheme.errorColor,
                                      tooltip: 'Delete trip',
                                    ),
                                ],
                              ),
                            ),
                          ],
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

  Widget _buildAction(
    IconData icon,
    VoidCallback? onTap, {
    Color? color,
    String? tooltip,
  }) {
    return Padding(
      padding: AppTheme.smallPadding,
      child: Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.largeBorderRadius),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [AppTheme.defaultShadow],
            ),
            child: Icon(
              icon,
              size: AppTheme.mediumIconFont,
              color: color ?? AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

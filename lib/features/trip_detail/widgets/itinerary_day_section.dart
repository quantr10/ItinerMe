import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/itinerary_day.dart';
import '../../../core/models/trip.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/trip_detail_controller.dart';
import 'confirm_remove_destination_dialog.dart';
import 'confirm_clear_day_dialog.dart';
import 'destination_card.dart';
import 'travel_info_between.dart';

// ITINERARY DAY SECTIONSECTION
class ItineraryDaySection extends StatelessWidget {
  final Trip trip;
  final ItineraryDay day;
  final int dayIndex;
  final TripDetailController controller;
  final GlobalKey sectionKey;
  final VoidCallback onAddDestination;

  const ItineraryDaySection({
    super.key,
    required this.trip,
    required this.day,
    required this.dayIndex,
    required this.controller,
    required this.sectionKey,
    required this.onAddDestination,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: sectionKey,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DAY HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day ${dayIndex + 1} - ${DateFormat('EEEE, MMMM d').format(day.date)}',
                style: const TextStyle(
                  fontSize: AppTheme.largeFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              if (controller.state.canEdit)
                Row(
                  children: [
                    // ===== ADD DESTINATION =====
                    InkWell(
                      onTap: onAddDestination,
                      borderRadius: BorderRadius.circular(
                        AppTheme.largeBorderRadius,
                      ),
                      child: _iconAction(Icons.add, AppTheme.primaryColor),
                    ),

                    // ===== CLEAR DAY =====
                    InkWell(
                      onTap: () async {
                        final confirm = await showConfirmClearDayDialog(
                          context,
                        );
                        if (confirm != true) return;

                        final ok = await controller.deleteDay(dayIndex);
                        if (ok) {
                          AppTheme.success('All destinations removed');
                        } else {
                          AppTheme.error('Failed to delete day');
                        }
                      },
                      borderRadius: BorderRadius.circular(
                        AppTheme.largeBorderRadius,
                      ),
                      child: _iconAction(
                        Icons.delete_outline,
                        AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          AppTheme.mediumSpacing,

          // EMPTY DAY STATE
          if (day.destinations.isEmpty)
            controller.state.canEdit
                ? Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final ok = await controller.generateSingleDay(dayIndex);
                      if (ok) {
                        AppTheme.success('Itinerary generated');
                      } else {
                        AppTheme.error('Failed to generate itinerary');
                      }
                    },
                    icon: const Icon(
                      Icons.auto_mode,
                      size: AppTheme.largeIconFont,
                    ),
                    label: const Text(
                      'AUTOFILL DAY',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.defaultFontSize,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius,
                        ),
                      ),
                      elevation: 2,
                    ),
                  ),
                )
                : const SizedBox.shrink()
          // DESTINATION LIST
          else
            Column(
              children: [
                ...day.destinations.asMap().entries.map((entry) {
                  final destIndex = entry.key;
                  final destination = entry.value;

                  return Column(
                    children: [
                      // ===== DESTINATION CARD =====
                      DestinationCard(
                        destination: destination,
                        dayIndex: dayIndex,
                        destinationIndex: destIndex,
                        canEdit: controller.state.canEdit,
                        visitDay: DateFormat(
                          'EEEE',
                        ).format(trip.itinerary[dayIndex].date),
                        isExpanded: controller.state.expandedDestinations
                            .contains(destination.name),
                        onToggleExpand:
                            () => controller.toggleExpand(destination.name),
                        onRemove: (dayIdx, destIdx) async {
                          final confirm =
                              await showConfirmRemoveDestinationDialog(context);
                          if (confirm != true) return;

                          final ok = await controller.removeDestination(
                            dayIdx,
                            destIdx,
                          );

                          if (ok) {
                            AppTheme.success('Destination removed');
                          } else {
                            AppTheme.error('Failed to remove destination');
                          }
                        },
                      ),

                      // ===== TRAVEL INFO BETWEEN DESTINATIONS =====
                      if (destIndex < day.destinations.length - 1)
                        TravelInfoBetween(
                          from: day.destinations[destIndex],
                          to: day.destinations[destIndex + 1],
                          initialTransport: trip.transportation,
                          controller: controller,
                        ),
                    ],
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );
  }

  // SMALL ICON ACTION BUILDER
  Widget _iconAction(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [AppTheme.defaultShadow],
      ),
      child: Icon(icon, color: color, size: AppTheme.largeIconFont),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:itinerme/features/trip/models/destination.dart';
import 'package:itinerme/core/theme/app_theme.dart';

class DestinationCard extends StatelessWidget {
  final Destination destination;
  final int dayIndex;
  final int destinationIndex;
  final Function(int, int) onRemove;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final String visitDay;
  final bool canEdit;

  const DestinationCard({
    super.key,
    required this.destination,
    required this.dayIndex,
    required this.destinationIndex,
    required this.onRemove,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.visitDay,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: InkWell(
        onTap: onToggleExpand,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: isExpanded ? double.infinity : 136,
          ),
          child: Padding(
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
                      child:
                          destination.imageUrl != null
                              ? Image.network(
                                destination.imageUrl!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholder(),
                              )
                              : _placeholder(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                destination.name,
                                style: const TextStyle(
                                  fontSize: AppTheme.defaultFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                destination.description,
                                style: const TextStyle(
                                  fontSize: AppTheme.smallFontSize,
                                  color: AppTheme.hintColor,
                                ),
                                maxLines: isExpanded ? null : 4,
                                overflow:
                                    isExpanded ? null : TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          if (canEdit)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: InkWell(
                                onTap:
                                    () => onRemove(dayIndex, destinationIndex),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [AppTheme.defaultShadow],
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: AppTheme.mediumIconFont,
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const Divider(),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (destination.types != null &&
                              destination.types!.isNotEmpty)
                            _buildTypesRow(destination.types!),
                          if (destination.rating != null)
                            _buildRatingRow(
                              destination.rating!,
                              destination.userRatingsTotal,
                            ),
                          if (destination.address.isNotEmpty)
                            _buildDetailRow(
                              Icons.location_on,
                              destination.address,
                            ),
                          if (destination.durationMinutes > 0)
                            _buildDetailRow(
                              Icons.timer,
                              'Should spend about ${destination.durationMinutes} minutes',
                            ),
                          if (destination.website != null)
                            _buildDetailRow(Icons.link, destination.website!),
                          if (destination.openingHours != null &&
                              destination.openingHours!.isNotEmpty)
                            _buildDaySpecificOpeningHours(
                              destination.openingHours!,
                              visitDay,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypesRow(List<String> types) {
    final filteredTypes = types.take(5).map((type) => type).toList();

    if (filteredTypes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.local_offer,
            size: AppTheme.mediumIconFont,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filteredTypes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final type = filteredTypes[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                      boxShadow: [AppTheme.defaultShadow],
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: AppTheme.smallFontSize,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(double rating, int? totalRatings) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.star,
            size: AppTheme.mediumIconFont,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: rating.toStringAsFixed(1),
                    style: TextStyle(fontSize: AppTheme.smallFontSize),
                  ),
                  if (totalRatings != null)
                    TextSpan(
                      text: ' ($totalRatings reviews)',
                      style: TextStyle(
                        color: AppTheme.hintColor,
                        fontSize: AppTheme.smallFontSize,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySpecificOpeningHours(
    List<String> openingHours,
    String visitDay,
  ) {
    final dayPattern = RegExp('^$visitDay:', caseSensitive: false);
    final dayHours = openingHours.firstWhere(
      (hours) => dayPattern.hasMatch(hours),
      orElse: () => '',
    );

    if (dayHours.isEmpty) {
      return _buildDetailRow(Icons.access_time_filled, 'Closed on $visitDay');
    }

    final hours = dayHours.replaceFirst(dayPattern, '').trim();

    return _buildDetailRow(Icons.access_time_filled, '$visitDay: $hours');
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: AppTheme.mediumIconFont,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: AppTheme.smallFontSize),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _placeholder() {
  return Container(
    width: 120,
    height: 120,
    color: AppTheme.secondaryColor.withOpacity(0.2),
    child: const Icon(Icons.image, color: AppTheme.hintColor),
  );
}

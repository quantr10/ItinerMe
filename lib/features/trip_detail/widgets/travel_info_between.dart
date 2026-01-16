import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/enums/transportation_enums.dart';
import '../../../core/models/destination.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/trip_detail_controller.dart';

class TravelInfoBetween extends StatefulWidget {
  final Destination from;
  final Destination to;
  final TransportationType initialTransport;
  final TripDetailController controller;

  const TravelInfoBetween({
    super.key,
    required this.from,
    required this.to,
    required this.initialTransport,
    required this.controller,
  });

  @override
  State<TravelInfoBetween> createState() => _TravelInfoBetweenState();
}

class _TravelInfoBetweenState extends State<TravelInfoBetween> {
  final transportModes = TransportationType.values;

  late List<TransportationType> options;
  late TransportationType selectedTransport;

  Future<Map<String, String>?>? travelFuture;
  final Map<TransportationType, Map<String, String>> transportInfo = {};
  bool expanded = false;

  @override
  void initState() {
    super.initState();
    options = TransportationType.values;
    selectedTransport = widget.initialTransport;
  }

  Future<void> _fetchAll() async {
    for (var t in options) {
      final info = await widget.controller.getTravelInfo(
        originLat: widget.from.latitude,
        originLng: widget.from.longitude,
        destLat: widget.to.latitude,
        destLng: widget.to.longitude,
        preferredTransport: t,
      );
      if (info != null) {
        transportInfo[t] = info;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    travelFuture ??= widget.controller.getTravelInfo(
      originLat: widget.from.latitude,
      originLng: widget.from.longitude,
      destLat: widget.to.latitude,
      destLng: widget.to.longitude,
      preferredTransport: selectedTransport,
    );

    return FutureBuilder<Map<String, String>?>(
      future: travelFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final info = snapshot.data!;
        final mode = selectedTransport.googleMode;
        final mapsUrl =
            'https://www.google.com/maps/dir/?api=1&origin=${widget.from.latitude},${widget.from.longitude}&destination=${widget.to.latitude},${widget.to.longitude}&travelmode=$mode';

        return Padding(
          padding: AppTheme.defaultPadding,
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      setState(() => expanded = !expanded);
                      if (expanded && transportInfo.isEmpty) {
                        await _fetchAll();
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          selectedTransport.icon,
                          size: AppTheme.largeIconFont,
                          color: AppTheme.hintColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${info['duration']} • ${info['distance']}',
                          style: const TextStyle(
                            color: AppTheme.hintColor,
                            fontSize: AppTheme.defaultFontSize,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.expand_more,
                          color: AppTheme.hintColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(mapsUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: const Text(
                      'Directions',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              if (expanded) ...[
                AppTheme.smallSpacing,
                Row(
                  children:
                      options.map((t) {
                        final option = transportInfo[t];
                        if (option == null) return const SizedBox.shrink();
                        final isSelected = t == selectedTransport;

                        return Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius,
                            ),
                            onTap: () {
                              setState(() {
                                selectedTransport = t;
                                travelFuture = widget.controller.getTravelInfo(
                                  originLat: widget.from.latitude,
                                  originLng: widget.from.longitude,
                                  destLat: widget.to.latitude,
                                  destLng: widget.to.longitude,
                                  preferredTransport: selectedTransport,
                                );
                                transportInfo.clear();
                                expanded = false;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? AppTheme.primaryColor.withOpacity(0.1)
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadius,
                                ),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.hintColor.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    t.icon,
                                    color:
                                        isSelected
                                            ? AppTheme.primaryColor
                                            : AppTheme.hintColor,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    option['duration'] ?? '',
                                    style: TextStyle(
                                      fontSize: AppTheme.smallFontSize,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color:
                                          isSelected
                                              ? AppTheme.primaryColor
                                              : AppTheme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

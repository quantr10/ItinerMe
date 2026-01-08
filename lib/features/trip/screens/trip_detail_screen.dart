import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_place/google_place.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:itinerme/features/trip/models/destination.dart';
import 'package:itinerme/features/trip/models/itinerary_day.dart';
import 'package:itinerme/features/trip/widgets/destination_card.dart';
import 'package:itinerme/features/trip/services/place_image_cache_service.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

import '../models/trip.dart';
import '../../../core/widgets/main_scaffold.dart';
import '../../../core/theme/app_theme.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  final int currentIndex;

  const TripDetailScreen({
    super.key,
    required this.trip,
    this.currentIndex = 0,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _dayKeys = {};
  final Set<String> _expandedDestinations = {};
  late GooglePlace _googlePlace;
  bool _canEdit = false;

  @override
  void initState() {
    super.initState();
    _checkEditPermission();
    for (int i = 0; i < widget.trip.itinerary.length; i++) {
      _dayKeys[i] = GlobalKey();
    }
    _googlePlace = GooglePlace(dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '');
  }

  Future<void> _checkEditPermission() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _canEdit = false);
      return;
    }

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final createdTripIds = List<String>.from(
      userDoc.data()?['createdTripIds'] ?? [],
    );

    setState(() {
      _canEdit = createdTripIds.contains(widget.trip.id);
    });
  }

  Future<Map<String, String>?> _getTravelInfo({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String preferredTransport,
  }) async {
    final mode = _mapTransportToMode(preferredTransport);
    Future<Map<String, String>?> fetch(String mode) async {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$originLat,$originLng&destination=$destLat,$destLng&mode=$mode&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}',
      );
      try {
        final res = await http.get(url);
        final data = json.decode(res.body);
        if (res.statusCode == 200 && data['status'] == 'OK') {
          final leg = data['routes'][0]['legs'][0];
          return {
            'distance': leg['distance']['text'],
            'duration': leg['duration']['text'],
            'mode': mode,
          };
        }
      } catch (_) {}
      return null;
    }

    final preferred = await fetch(mode);
    return preferred ?? await fetch('driving');
  }

  String _mapTransportToMode(String transport) {
    switch (transport.toLowerCase()) {
      case 'car':
        return 'driving';
      case 'motorbike':
        return 'two_wheeler';
      case 'bus/metro':
        return 'transit';
      case 'walking':
        return 'walking';
      default:
        return 'driving';
    }
  }

  IconData _getTransportationIcon(String mode) {
    switch (mode) {
      case 'driving':
        return Icons.directions_car;
      case 'transit':
        return Icons.directions_bus;
      case 'walking':
        return Icons.directions_walk;
      case 'two_wheeler':
        return Icons.motorcycle;
      case 'bicycling':
        return Icons.directions_bike;
      default:
        return Icons.directions;
    }
  }

  Widget _buildTravelInfoBetween(
    Destination from,
    Destination to,
    String initialTransport,
  ) {
    final transportModes = {
      'car': 'driving',
      'motorbike': 'two_wheeler',
      'bus/metro': 'transit',
      'walking': 'walking',
    };
    final options = transportModes.keys.toList();
    String selectedTransport = initialTransport.toLowerCase();
    Future<Map<String, String>?>? travelFuture;
    Map<String, Map<String, String>> transportInfo = {};
    bool expanded = false;

    return StatefulBuilder(
      builder: (context, setModalState) {
        Future<void> fetchAll() async {
          for (var t in options) {
            final info = await _getTravelInfo(
              originLat: from.latitude,
              originLng: from.longitude,
              destLat: to.latitude,
              destLng: to.longitude,
              preferredTransport: t,
            );
            if (info != null) {
              transportInfo[t] = info;
            }
          }
          setModalState(() {});
        }

        travelFuture ??= _getTravelInfo(
          originLat: from.latitude,
          originLng: from.longitude,
          destLat: to.latitude,
          destLng: to.longitude,
          preferredTransport: selectedTransport,
        );

        return FutureBuilder<Map<String, String>?>(
          future: travelFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final info = snapshot.data!;
            final mode = info['mode']!;
            final mapsUrl =
                'https://www.google.com/maps/dir/?api=1&origin=${from.latitude},${from.longitude}&destination=${to.latitude},${to.longitude}&travelmode=$mode';
            return Padding(
              padding: AppTheme.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () async {
                            setModalState(() => expanded = !expanded);
                            if (expanded && transportInfo.isEmpty)
                              await fetchAll();
                          },
                          child: Row(
                            children: [
                              Icon(
                                _getTransportationIcon(mode),
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
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.expand_more,
                                color: AppTheme.hintColor,
                                size: AppTheme.mediumIconFont,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
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
                              fontSize: AppTheme.defaultFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (expanded) ...[
                    AppTheme.smallSpacing,
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child:
                          expanded
                              ? Row(
                                children:
                                    options.map((t) {
                                      final option = transportInfo[t];
                                      final mode = transportModes[t]!;
                                      final isSelected = t == selectedTransport;
                                      if (option == null)
                                        return const SizedBox.shrink();

                                      return Expanded(
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.borderRadius,
                                          ),
                                          onTap: () {
                                            setModalState(() {
                                              selectedTransport = t;
                                              travelFuture = _getTravelInfo(
                                                originLat: from.latitude,
                                                originLng: from.longitude,
                                                destLat: to.latitude,
                                                destLng: to.longitude,
                                                preferredTransport:
                                                    selectedTransport,
                                              );
                                              expanded = false;
                                            });
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isSelected
                                                      ? AppTheme.primaryColor
                                                          .withOpacity(0.1)
                                                      : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.borderRadius,
                                                  ),
                                              border: Border.all(
                                                color:
                                                    isSelected
                                                        ? AppTheme.primaryColor
                                                        : AppTheme.hintColor
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getTransportationIcon(mode),
                                                  size: AppTheme.largeIconFont,
                                                  color:
                                                      isSelected
                                                          ? AppTheme
                                                              .primaryColor
                                                          : AppTheme.hintColor,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  option['duration'] ?? '',
                                                  style: TextStyle(
                                                    fontSize:
                                                        AppTheme.smallFontSize,
                                                    fontWeight:
                                                        isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                    color:
                                                        isSelected
                                                            ? AppTheme
                                                                .primaryColor
                                                            : AppTheme
                                                                .hintColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              )
                              : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _scrollToDay(int index) {
    final keyContext = _dayKeys[index]?.currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        duration: AppTheme.animationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _openDateRangePicker() async {
    List<DateTime?> selectedDates = [
      widget.trip.startDate,
      widget.trip.endDate,
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Select Date Range',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppTheme.largeFontSize,
            ),
          ),
          insetPadding: AppTheme.largePadding,
          content: SizedBox(
            height: 240,
            width: 350,
            child: CalendarDatePicker2(
              config: CalendarDatePicker2Config(
                calendarType: CalendarDatePicker2Type.range,
                selectedDayHighlightColor: AppTheme.primaryColor,
                centerAlignModePicker: true,
                dayTextStyle: const TextStyle(
                  fontSize: AppTheme.defaultFontSize,
                ),
                weekdayLabelTextStyle: const TextStyle(
                  fontSize: AppTheme.defaultFontSize,
                  fontWeight: FontWeight.bold,
                ),
                controlsHeight: 50,
                useAbbrLabelForMonthModePicker: true,
                daySplashColor: Colors.transparent,
                disabledDayTextStyle: const TextStyle(
                  color: AppTheme.hintColor,
                ),
                modePickersGap: 8,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              ),
              value: selectedDates,
              onValueChanged: (dates) {
                setState(() {
                  selectedDates = dates;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
              onPressed: () async {
                if (selectedDates.length == 2 &&
                    selectedDates[0] != null &&
                    selectedDates[1] != null) {
                  final newStart = DateTime(
                    selectedDates[0]!.year,
                    selectedDates[0]!.month,
                    selectedDates[0]!.day,
                    0,
                    0,
                  );
                  final newEnd = DateTime(
                    selectedDates[1]!.year,
                    selectedDates[1]!.month,
                    selectedDates[1]!.day,
                    23,
                    59,
                  );

                  final oldDays = widget.trip.itinerary;
                  final oldLength = oldDays.length;
                  final newLength = newEnd.difference(newStart).inDays + 1;

                  final newItinerary = List.generate(newLength, (i) {
                    final date = newStart.add(Duration(days: i));
                    if (i < oldLength) {
                      return ItineraryDay(
                        date: date,
                        destinations: oldDays[i].destinations,
                      );
                    } else {
                      return ItineraryDay(date: date, destinations: []);
                    }
                  });

                  setState(() {
                    widget.trip.startDate = newStart;
                    widget.trip.endDate = newEnd;
                    widget.trip.itinerary = newItinerary;
                  });

                  await FirebaseFirestore.instance
                      .collection('trips')
                      .doc(widget.trip.id)
                      .update({
                        'startDate': Timestamp.fromDate(newStart),
                        'endDate': Timestamp.fromDate(newEnd),
                        'itinerary':
                            newItinerary.map((e) => e.toJson()).toList(),
                      });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeDestination(int dayIndex, int destinationIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          title: const Text(
            'Delete Destination',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppTheme.largeFontSize,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this destination?',
            style: TextStyle(fontSize: AppTheme.defaultFontSize),
          ),
          actions: [
            TextButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final tripId = widget.trip.id;
      setState(() {
        widget.trip.itinerary[dayIndex].destinations.removeAt(destinationIndex);
      });

      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'itinerary': widget.trip.itinerary.map((d) => d.toJson()).toList(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Destinations removed'),
          backgroundColor: AppTheme.errorColor,
          duration: AppTheme.messageDuration,
        ),
      );
    }
  }

  Future<LatLon?> _getTripCoordinates() async {
    final geocode = await _googlePlace.search.getTextSearch(
      widget.trip.location,
    );
    if (geocode?.results?.isNotEmpty ?? false) {
      final lat = geocode!.results!.first.geometry!.location!.lat!;
      final lng = geocode.results!.first.geometry!.location!.lng!;
      return LatLon(lat, lng);
    }
    return null;
  }

  void _showAddDestinationDialog(int dayIndex) {
    String query = '';
    List<AutocompletePrediction> results = [];
    AutocompletePrediction? selectedPrediction;
    final TextEditingController _searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
              title: const Text(
                'Add Destination',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.largeFontSize,
                ),
              ),
              content: SizedBox(
                height: 200,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius,
                        ),
                        boxShadow: [AppTheme.defaultShadow],
                      ),
                      child: SizedBox(
                        height: AppTheme.fieldHeight,
                        child: TextField(
                          controller: _searchController,
                          decoration: AppTheme.inputDecoration(
                            'Type a place',
                            onClear: () => _searchController.clear(),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppTheme.primaryColor,
                              size: AppTheme.largeFontSize,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: AppTheme.defaultFontSize,
                          ),
                          onChanged: (value) async {
                            query = value.trim();

                            if (query.isEmpty) {
                              if (Navigator.of(context).canPop()) {
                                setModalState(() => results = []);
                              }
                              return;
                            }

                            final tripCoords = await _getTripCoordinates();
                            if (tripCoords == null) return;

                            if (!context.mounted ||
                                !Navigator.of(context).canPop())
                              return;

                            if (query.isEmpty) return;

                            final response = await _googlePlace.autocomplete
                                .get(
                                  query,
                                  location: LatLon(
                                    tripCoords.latitude,
                                    tripCoords.longitude,
                                  ),
                                  radius: 100000,
                                  strictbounds: true,
                                );

                            if (!context.mounted ||
                                !Navigator.of(context).canPop())
                              return;

                            setModalState(
                              () => results = response?.predictions ?? [],
                            );
                          },
                        ),
                      ),
                    ),
                    AppTheme.smallSpacing,
                    if (results.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (_, index) {
                            final prediction = results[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.place,
                                color: AppTheme.primaryColor,
                              ),
                              title: Text(
                                prediction.description ?? '',
                                style: TextStyle(
                                  fontSize: AppTheme.defaultFontSize,
                                  color: Colors.black,
                                ),
                              ),
                              selected: selectedPrediction == prediction,
                              onTap: () {
                                setModalState(() {
                                  selectedPrediction = prediction;
                                  _searchController.text =
                                      prediction.description ?? '';
                                  results = [];
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                    ),
                  ),
                  onPressed:
                      selectedPrediction == null
                          ? null
                          : () async {
                            final placeId = selectedPrediction!.placeId;
                            if (placeId == null) return;

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (_) => Stack(
                                    children: [
                                      Container(
                                        color: Colors.black.withOpacity(0.2),
                                      ),
                                      const Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppTheme.primaryColor,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                            );

                            try {
                              final details = await _googlePlace.details.get(
                                placeId,
                              );
                              final result = details?.result;
                              if (result == null) {
                                Navigator.of(context).pop();
                                return;
                              }

                              final aiResponse = await http.post(
                                Uri.parse(
                                  'https://api.openai.com/v1/chat/completions',
                                ),
                                headers: {
                                  'Authorization':
                                      'Bearer ${dotenv.env['OPENAI_API_KEY']}',
                                  'Content-Type': 'application/json',
                                },
                                body: jsonEncode({
                                  'model': 'gpt-4',
                                  'messages': [
                                    {
                                      'role': 'user',
                                      'content':
                                          'You are a travel planner. Provide a short description and estimated visit duration for the following place: ${result.name}, ${result.formattedAddress}. Return JSON like: {"description": "...", "durationMinutes": 60}',
                                    },
                                  ],
                                  'temperature': 0.7,
                                }),
                              );

                              final aiText = utf8.decode(aiResponse.bodyBytes);
                              final content =
                                  jsonDecode(
                                        aiText,
                                      )['choices'][0]['message']['content']
                                      .replaceAll('```json', '')
                                      .replaceAll('```', '')
                                      .trim();
                              final aiData = jsonDecode(content);
                              String? imageUrl;

                              if (result.photos?.isNotEmpty == true) {
                                imageUrl =
                                    await PlaceImageCacheService.cachePlacePhoto(
                                      photoReference:
                                          result.photos!.first.photoReference!,
                                      path:
                                          'destinations/${widget.trip.id}/${result.placeId}.jpg',
                                    );
                              }

                              final newDest = Destination(
                                placeId: result.placeId ?? '',
                                name: result.name ?? 'Unnamed',
                                address: result.formattedAddress ?? '',
                                description: aiData['description'],
                                durationMinutes: aiData['durationMinutes'],
                                imageUrl: imageUrl,
                                types: result.types,
                                latitude: result.geometry?.location?.lat ?? 0.0,
                                longitude:
                                    result.geometry?.location?.lng ?? 0.0,

                                website: result.website,
                                openingHours: result.openingHours?.weekdayText,
                                rating: result.rating,
                                userRatingsTotal: result.userRatingsTotal,
                                url: result.url,
                                startTime: DateTime.now(),
                                endTime: DateTime.now().add(
                                  Duration(
                                    minutes: aiData['durationMinutes'] ?? 60,
                                  ),
                                ),
                              );

                              setState(() {
                                widget.trip.itinerary[dayIndex].destinations
                                    .add(newDest);
                              });

                              await FirebaseFirestore.instance
                                  .collection('trips')
                                  .doc(widget.trip.id)
                                  .update({
                                    'itinerary':
                                        widget.trip.itinerary
                                            .map((d) => d.toJson())
                                            .toList(),
                                  });

                              Navigator.of(context).pop();
                              Navigator.of(context).pop();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Destination added'),
                                  backgroundColor: AppTheme.accentColor,
                                  duration: AppTheme.messageDuration,
                                ),
                              );
                            } catch (e) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error ${e.toString()}'),
                                  backgroundColor: AppTheme.errorColor,
                                  duration: AppTheme.messageDuration,
                                ),
                              );
                            }
                          },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteDayDestinations(int dayIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          title: const Text(
            'Delete Day',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppTheme.largeFontSize,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete all destinations in this day?',
            style: TextStyle(fontSize: AppTheme.defaultFontSize),
          ),
          actions: [
            TextButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        widget.trip.itinerary[dayIndex].destinations.clear();
      });

      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.trip.id)
          .update({
            'itinerary': widget.trip.itinerary.map((d) => d.toJson()).toList(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Destinations removed'),
          backgroundColor: AppTheme.errorColor,
          duration: AppTheme.messageDuration,
        ),
      );
    }
  }

  Future<void> _generateForSingleDay(int dayIndex) async {
    final existingNames = <String>{};

    for (int i = 0; i < widget.trip.itinerary.length; i++) {
      if (i == dayIndex) continue;
      for (final dest in widget.trip.itinerary[i].destinations) {
        existingNames.add(dest.name.toLowerCase());
      }
    }

    final prompt = '''
You are a professional travel planner.

Below is the trip information provided by a user. Bring me a list of 3–5 distinct destinations in ${widget.trip.location}.

Destination: ${widget.trip.location}
Budget: ${widget.trip.budget} USD
Transportation: ${widget.trip.transportation}

Do NOT include places that are duplicates, alternate spellings, or similar to any of these names: ${existingNames.join(', ')}
Make each day's destinations **geographically logical**. Cluster nearby locations together and do not split adjacent spots into different days.

Return a valid JSON array only, no explanation or markdown:
[
  {
    "name": "Place Name",
    "description": "Detail description",
    "durationMinutes": 90
  }
]
''';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Stack(
            children: [
              Container(color: Colors.black.withOpacity(0.2)),
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
    );

    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.8,
        }),
      );

      Navigator.of(context).pop();

      if (res.statusCode == 200) {
        final content =
            jsonDecode(
                  utf8.decode(res.bodyBytes),
                )['choices'][0]['message']['content']
                .replaceAll('```json', '')
                .replaceAll('```', '')
                .trim();

        final List<dynamic> places = jsonDecode(content);
        final List<Destination> newDestinations = [];

        for (final place in places) {
          final normalizedName = place['name'].toString().toLowerCase().trim();
          if (existingNames.contains(normalizedName)) continue;

          final query = '${place['name']}, ${widget.trip.location}';
          final search = await _googlePlace.search.getTextSearch(query);
          final match = search?.results?.first;
          if (match?.placeId == null) continue;

          final isDuplicatePlaceId = widget.trip.itinerary
              .expand((day) => day.destinations)
              .any((dest) => dest.placeId == match!.placeId);
          if (isDuplicatePlaceId) continue;

          final detail = await _googlePlace.details.get(match!.placeId!);
          final result = detail?.result;
          if (result == null) continue;

          String? imageUrl;

          if (result.photos?.isNotEmpty == true) {
            imageUrl = await PlaceImageCacheService.cachePlacePhoto(
              photoReference: result.photos!.first.photoReference!,
              path: 'destinations/${widget.trip.id}/${result.placeId}.jpg',
            );
          }

          newDestinations.add(
            Destination(
              placeId: result.placeId ?? '',
              name: place['name'],
              address: result.formattedAddress ?? '',
              description: place['description'],
              rating: result.rating,
              userRatingsTotal: result.userRatingsTotal,
              website: result.website,
              types: result.types ?? [],
              latitude: result.geometry?.location?.lat ?? 0.0,
              longitude: result.geometry?.location?.lng ?? 0.0,
              openingHours: result.openingHours?.weekdayText,
              durationMinutes: place['durationMinutes'],
              startTime: DateTime.now(),
              endTime: DateTime.now().add(
                Duration(minutes: place['durationMinutes'] ?? 90),
              ),
              imageUrl: imageUrl,
            ),
          );
        }

        setState(() {
          widget.trip.itinerary[dayIndex].destinations.addAll(newDestinations);
        });

        await FirebaseFirestore.instance
            .collection('trips')
            .doc(widget.trip.id)
            .update({
              'itinerary':
                  widget.trip.itinerary.map((d) => d.toJson()).toList(),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Itinerary generated'),
            backgroundColor: AppTheme.accentColor,
            duration: AppTheme.messageDuration,
          ),
        );
      } else {
        throw Exception('Failed to generate ${res.body}');
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          duration: AppTheme.messageDuration,
        ),
      );
    }
  }

  void _showCoverImageOptions() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            title: const Text(
              'Choose Cover Image',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppTheme.largeFontSize,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.image_search,
                    size: AppTheme.largeIconFont,
                  ),
                  title: const Text('Choose from Google'),
                  onTap: () {
                    Navigator.pop(context);
                    _selectCoverFromGooglePhotos();
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Upload from your phone'),
                  onTap: () {
                    Navigator.pop(context);
                    _selectCoverFromDevice();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _selectCoverFromGooglePhotos() async {
    try {
      final search = await _googlePlace.search.getTextSearch(
        widget.trip.location,
      );

      if (search?.results?.isEmpty ?? true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No locations found for this trip'),
            backgroundColor: AppTheme.errorColor,
            duration: AppTheme.messageDuration,
          ),
        );
        return;
      }

      final placeId = search!.results!.first.placeId;
      final detail = await _googlePlace.details.get(placeId!);
      final photos = detail?.result?.photos;

      if (photos == null || photos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No photos available for this location'),
            backgroundColor: AppTheme.errorColor,
            duration: AppTheme.messageDuration,
          ),
        );
        return;
      }

      String? selectedPhotoReference;

      await showDialog(
        context: context,
        builder:
            (_) => StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                  title: const Text(
                    'Choose Cover Image',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTheme.largeFontSize,
                    ),
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: GridView.builder(
                      shrinkWrap: true,
                      itemCount: photos.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 9,
                            mainAxisSpacing: 8,
                          ),
                      itemBuilder: (context, index) {
                        final ref = photos[index].photoReference;
                        final url =
                            'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=$ref&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}';

                        final isSelected = selectedPhotoReference == ref;

                        return GestureDetector(
                          onTap:
                              () => setState(() {
                                selectedPhotoReference = ref;
                              }),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  loadingBuilder: (context, child, progress) {
                                    return progress == null
                                        ? child
                                        : Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                progress.expectedTotalBytes !=
                                                        null
                                                    ? progress
                                                            .cumulativeBytesLoaded /
                                                        progress
                                                            .expectedTotalBytes!
                                                    : null,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppTheme.primaryColor,
                                                ),
                                          ),
                                        );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.broken_image),
                                    );
                                  },
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                        ),
                      ),
                      onPressed:
                          selectedPhotoReference == null
                              ? null
                              : () async {
                                try {
                                  // Loading
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder:
                                        (_) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                  );

                                  final firebaseUrl =
                                      await PlaceImageCacheService.cachePlacePhoto(
                                        photoReference: selectedPhotoReference!,
                                        path:
                                            'trip_covers/${widget.trip.id}.jpg',
                                      );

                                  if (firebaseUrl == null) {
                                    Navigator.of(context).pop();
                                    return;
                                  }

                                  await FirebaseFirestore.instance
                                      .collection('trips')
                                      .doc(widget.trip.id)
                                      .update({'coverImageUrl': firebaseUrl});

                                  setState(() {
                                    widget.trip.coverImageUrl = firebaseUrl;
                                  });

                                  // Close dialogs
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cover photo updated'),
                                      backgroundColor: AppTheme.accentColor,
                                    ),
                                  );
                                } catch (e) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error ${e.toString()}'),
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                  );
                                }
                              },
                      child: const Text('Select'),
                    ),
                  ],
                );
              },
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          duration: AppTheme.messageDuration,
        ),
      );
    }
  }

  Future<void> _selectCoverFromDevice() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final file = File(picked.path);
      final filename =
          '${widget.trip.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = FirebaseStorage.instance.ref().child('trip_covers/$filename');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.trip.id)
          .update({'coverImageUrl': downloadUrl});

      setState(() => widget.trip.coverImageUrl = downloadUrl);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cover photo updated'),
          backgroundColor: AppTheme.accentColor,
          duration: AppTheme.messageDuration,
        ),
      );
    } catch (e) {
      if (Navigator.of(context).canPop()) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          duration: AppTheme.messageDuration,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return MainScaffold(
      currentIndex: widget.currentIndex,
      body: Padding(
        padding: AppTheme.defaultPadding,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    child: Image.network(
                      trip.coverImageUrl,
                      height: 240,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Image.asset(
                            'assets/images/place_placeholder.jpg',
                          ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(
                        AppTheme.largeBorderRadius,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [AppTheme.defaultShadow],
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_left,
                          color: AppTheme.primaryColor,
                          size: AppTheme.largeIconFont,
                        ),
                      ),
                    ),
                  ),
                  if (_canEdit)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: InkWell(
                        onTap: _showCoverImageOptions,
                        borderRadius: BorderRadius.circular(
                          AppTheme.largeBorderRadius,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [AppTheme.defaultShadow],
                          ),
                          child: Icon(
                            Icons.photo_camera,
                            color: AppTheme.primaryColor,
                            size: AppTheme.largeIconFont,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              AppTheme.smallSpacing,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: const TextStyle(
                      fontSize: AppTheme.titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  AppTheme.smallSpacing,
                  Text(
                    trip.location,
                    style: const TextStyle(
                      fontSize: AppTheme.defaultFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.hintColor,
                    ),
                  ),
                  Text(
                    '${DateFormat('EEE, MMM d').format(trip.startDate)} - ${DateFormat('EEE, MMM d').format(trip.endDate)}',
                    style: TextStyle(
                      fontSize: AppTheme.defaultFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.hintColor,
                    ),
                  ),
                  AppTheme.mediumSpacing,
                  Row(
                    children: [
                      if (_canEdit)
                        Row(
                          children: [
                            InkWell(
                              onTap: _openDateRangePicker,
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
                      Expanded(
                        child: SizedBox(
                          height: 30,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: trip.itinerary.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final date = trip.itinerary[index].date;
                              return InkWell(
                                onTap: () => _scrollToDay(index),
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
                                    style: TextStyle(
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
              ),
              AppTheme.mediumSpacing,
              ...trip.itinerary.map((day) {
                final dayIndex = trip.itinerary.indexOf(day);
                return Container(
                  key: _dayKeys[dayIndex],
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                          if (_canEdit)
                            Row(
                              children: [
                                InkWell(
                                  onTap:
                                      () => _showAddDestinationDialog(dayIndex),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.largeBorderRadius,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [AppTheme.defaultShadow],
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: AppTheme.primaryColor,
                                      size: AppTheme.largeIconFont,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _deleteDayDestinations(dayIndex),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.largeBorderRadius,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [AppTheme.defaultShadow],
                                    ),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: AppTheme.errorColor,
                                      size: AppTheme.largeIconFont,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      AppTheme.mediumSpacing,
                      day.destinations.isEmpty
                          ? (_canEdit
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed:
                                        () => _generateForSingleDay(dayIndex),
                                    icon: const Icon(
                                      Icons.auto_mode,
                                      size: AppTheme.largeIconFont,
                                    ),
                                    label: const Text(
                                      'AUTOFILL DAY',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
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
                                    ),
                                  ),
                                ],
                              )
                              : const SizedBox.shrink())
                          : Column(
                            children: [
                              ...day.destinations.asMap().entries.map((entry) {
                                final destIndex = entry.key;
                                final destination = entry.value;

                                return Column(
                                  children: [
                                    DestinationCard(
                                      destination: destination,
                                      dayIndex: dayIndex,
                                      destinationIndex: destIndex,
                                      onRemove: _removeDestination,
                                      isExpanded: _expandedDestinations
                                          .contains(destination.name),
                                      onToggleExpand: () {
                                        setState(() {
                                          if (_expandedDestinations.contains(
                                            destination.name,
                                          )) {
                                            _expandedDestinations.remove(
                                              destination.name,
                                            );
                                          } else {
                                            _expandedDestinations.add(
                                              destination.name,
                                            );
                                          }
                                        });
                                      },
                                      visitDay: DateFormat('EEEE').format(
                                        widget.trip.itinerary[dayIndex].date,
                                      ),
                                      canEdit: _canEdit,
                                    ),
                                    if (destIndex < day.destinations.length - 1)
                                      _buildTravelInfoBetween(
                                        day.destinations[destIndex],
                                        day.destinations[destIndex + 1],
                                        widget.trip.transportation
                                            .toLowerCase(),
                                      ),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

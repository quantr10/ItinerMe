import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:google_place/google_place.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:itinerme/core/models/itinerary_day.dart';
import 'package:itinerme/features/trip_detail/widgets/destination_card.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import '../../../core/models/trip.dart';
import '../../../core/widgets/main_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/trip_detail_controller.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../widgets/travel_info_between.dart';

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

  late TripDetailController controller;

  @override
  void initState() {
    super.initState();
    controller = TripDetailController(widget.trip);

    for (int i = 0; i < widget.trip.itinerary.length; i++) {
      _dayKeys[i] = GlobalKey();
    }

    controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
            'Select Date',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppTheme.largeFontSize,
            ),
          ),
          insetPadding: AppTheme.largePadding,
          content: SizedBox(
            height: 250,
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

                  final ok = await controller.updateDateRange(newStart, newEnd);
                  if (ok) {
                    SnackBarHelper.success('Date range updated');
                  } else {
                    SnackBarHelper.error('Failed to update date');
                  }
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

  Future<LatLon?> _getTripCoordinates() async {
    final geocode = await controller.googlePlace.search.getTextSearch(
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
              title: const Text(
                'Add Destination',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.largeFontSize,
                ),
              ),
              insetPadding: AppTheme.largePadding,
              content: SizedBox(
                height: 250,
                width: 350,
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
                          autofocus: true,
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

                            final response = await controller
                                .googlePlace
                                .autocomplete
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
                  onPressed: () async {
                    if (selectedPrediction == null) {
                      SnackBarHelper.error('Please select a place');
                      return;
                    }
                    final ok = await controller.addDestinationFromSearch(
                      dayIndex,
                      selectedPrediction!,
                    );

                    if (ok) {
                      SnackBarHelper.success('Destination added');
                    } else {
                      SnackBarHelper.error('Destination already exists');
                    }

                    Navigator.pop(context);
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

  void _showCoverImageOptions() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Choose Cover Image',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppTheme.largeFontSize,
              ),
            ),
            insetPadding: AppTheme.largePadding,
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
                  onTap: () async {
                    Navigator.pop(context);
                    final ok = await controller.updateCoverFromDevice();
                    if (ok) {
                      SnackBarHelper.success('Cover photo updated');
                    } else {
                      SnackBarHelper.error('Failed to update cover photo');
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _selectCoverFromGooglePhotos() async {
    try {
      final search = await controller.googlePlace.search.getTextSearch(
        widget.trip.location,
      );

      if (search?.results?.isEmpty ?? true) {
        SnackBarHelper.error('No locations found for this trip');

        return;
      }

      final placeId = search!.results!.first.placeId;
      final detail = await controller.googlePlace.details.get(placeId!);
      final photos = detail?.result?.photos;

      if (photos == null || photos.isEmpty) {
        SnackBarHelper.error('No photos available for this location');

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
                                final ok = await controller
                                    .updateCoverFromGooglePhoto(
                                      selectedPhotoReference!,
                                    );
                                Navigator.pop(context);
                                if (ok) {
                                  SnackBarHelper.success('Cover photo updated');
                                } else {
                                  SnackBarHelper.error(
                                    'Failed to update cover photo',
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
      SnackBarHelper.error('Error ${e.toString()}');
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
                  if (controller.state.canEdit)
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
                      if (controller.state.canEdit)
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
                          if (controller.state.canEdit)
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
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (_) => AlertDialog(
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.borderRadius,
                                                  ),
                                            ),
                                            title: const Text(
                                              'Clear this day',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    AppTheme.largeFontSize,
                                              ),
                                            ),
                                            content: const Text(
                                              'This will remove all destinations from this day. Continue?',
                                            ),
                                            actions: [
                                              TextButton(
                                                style: ElevatedButton.styleFrom(
                                                  foregroundColor: Colors.black,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppTheme.borderRadius,
                                                        ),
                                                  ),
                                                ),
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppTheme.errorColor,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppTheme.borderRadius,
                                                        ),
                                                  ),
                                                ),
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                child: const Text('Clear'),
                                              ),
                                            ],
                                          ),
                                    );

                                    if (confirm != true) return;

                                    final ok = await controller.deleteDay(
                                      dayIndex,
                                    );
                                    if (ok) {
                                      SnackBarHelper.success(
                                        'All destinations removed',
                                      );
                                    } else {
                                      SnackBarHelper.error(
                                        'Failed to delete day',
                                      );
                                    }
                                  },

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
                          ? (controller.state.canEdit
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final ok = await controller
                                          .generateSingleDay(dayIndex);
                                      if (ok) {
                                        SnackBarHelper.success(
                                          'Itinerary generated',
                                        );
                                      } else {
                                        SnackBarHelper.error(
                                          'Failed to generate itinerary',
                                        );
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
                                      onRemove: (day, index) async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder:
                                              (_) => AlertDialog(
                                                backgroundColor: Colors.white,
                                                title: const Text(
                                                  'Remove destination',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        AppTheme.largeFontSize,
                                                  ),
                                                ),
                                                content: const Text(
                                                  'Are you sure you want to remove this destination from the trip?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    style: ElevatedButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.black,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              AppTheme
                                                                  .borderRadius,
                                                            ),
                                                      ),
                                                    ),
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          AppTheme.errorColor,
                                                      foregroundColor:
                                                          Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              AppTheme
                                                                  .borderRadius,
                                                            ),
                                                      ),
                                                    ),
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: const Text('Remove'),
                                                  ),
                                                ],
                                              ),
                                        );

                                        if (confirm != true) return;

                                        final ok = await controller
                                            .removeDestination(day, index);
                                        if (ok) {
                                          SnackBarHelper.success(
                                            'Destination removed',
                                          );
                                        } else {
                                          SnackBarHelper.error(
                                            'Failed to remove destination',
                                          );
                                        }
                                      },

                                      isExpanded: controller
                                          .state
                                          .expandedDestinations
                                          .contains(destination.name),
                                      onToggleExpand: () {
                                        controller.toggleExpand(
                                          destination.name,
                                        );
                                      },

                                      visitDay: DateFormat('EEEE').format(
                                        widget.trip.itinerary[dayIndex].date,
                                      ),
                                      canEdit: controller.state.canEdit,
                                    ),
                                    if (destIndex < day.destinations.length - 1)
                                      TravelInfoBetween(
                                        from: day.destinations[destIndex],
                                        to: day.destinations[destIndex + 1],
                                        initialTransport:
                                            widget.trip.transportation,
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
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

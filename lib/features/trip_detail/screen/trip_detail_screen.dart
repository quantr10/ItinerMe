import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/repositories/trip_repository.dart';
import '../../../core/widgets/main_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/trip.dart';
import '../../../core/services/google_place_service.dart';
import '../../../core/services/travel_service.dart';
import '../../../core/services/trip_ai_service.dart';
import '../../../core/services/trip_media_service.dart';

import '../controller/trip_detail_controller.dart';

import '../widgets/trip_cover_header.dart';
import '../widgets/trip_info_header.dart';
import '../widgets/itinerary_day_section.dart';
import '../widgets/data_range_dialog.dart';
import '../widgets/add_destination_dialog.dart';
import '../widgets/cover_option_dialog.dart';

class TripDetailScreen extends StatelessWidget {
  final Trip trip;
  final int currentIndex;

  const TripDetailScreen({
    super.key,
    required this.trip,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => TripDetailController(
            trip: trip,
            tripRepo: TripRepository(
              firestore: FirebaseFirestore.instance,
              auth: FirebaseAuth.instance,
            ),
            aiService: TripAIService(),
            placeService: GooglePlaceService(),
            travelService: TravelService(),
            coverService: TripMediaService(),
          ),
      child: _TripDetailView(currentIndex: currentIndex),
    );
  }
}

class _TripDetailView extends StatefulWidget {
  final int currentIndex;
  const _TripDetailView({required this.currentIndex});

  @override
  State<_TripDetailView> createState() => _TripDetailViewState();
}

class _TripDetailViewState extends State<_TripDetailView> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _dayKeys = {};
  int? _lastLength;

  // SYNC GLOBALKEYS
  void _syncDayKeys(Trip trip) {
    if (_lastLength == trip.itinerary.length) return;
    _lastLength = trip.itinerary.length;

    _dayKeys.clear();
    for (int i = 0; i < trip.itinerary.length; i++) {
      _dayKeys[i] = GlobalKey();
    }
  }

  // SCROLL SMOOTHLY TO A SELECTED DAY SECTION
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TripDetailController>();
    final state = controller.state;
    final trip = controller.trip;

    _syncDayKeys(trip);

    return Stack(
      children: [
        MainScaffold(
          currentIndex: widget.currentIndex,
          body: Padding(
            padding: AppTheme.defaultPadding,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // ===== TRIP COVER HEADER =====
                  TripCoverHeader(
                    trip: trip,
                    canEdit: state.canEdit,
                    onBack: () => Navigator.pop(context),
                    onChangeCover: () async {
                      await showCoverOptionDialog(context, controller);
                    },
                  ),

                  AppTheme.smallSpacing,

                  // ===== TRIP INFO HEADER =====
                  TripInfoHeader(
                    trip: trip,
                    canEdit: state.canEdit,
                    onPickDate: () async {
                      final ok = await showDateRangeDialog(
                        context,
                        trip,
                        controller,
                      );
                      if (ok == true) {
                        AppTheme.success('Date updated');
                      } else if (ok == false) {
                        AppTheme.error('Failed to update date');
                      }
                    },
                    onSelectDay: _scrollToDay,
                  ),

                  AppTheme.mediumSpacing,

                  // ===== ITINERARY DAY SECTIONS =====
                  ...trip.itinerary.asMap().entries.map((entry) {
                    final dayIndex = entry.key;
                    final day = entry.value;

                    return ItineraryDaySection(
                      trip: trip,
                      day: day,
                      dayIndex: dayIndex,
                      controller: controller,
                      sectionKey: _dayKeys[dayIndex]!,
                      onAddDestination: () async {
                        await showAddDestinationDialog(
                          context,
                          controller,
                          dayIndex,
                        );
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),

        // ===== LOADING OVERLAY =====
        if (state.isLoading)
          Positioned.fill(child: AppTheme.loadingScreen(overlay: true)),
      ],
    );
  }
}

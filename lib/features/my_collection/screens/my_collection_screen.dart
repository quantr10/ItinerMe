import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:itinerme/core/models/trip.dart';
import '../../../core/widgets/main_scaffold.dart';
import '../../../core/theme/app_theme.dart';

import '../controller/my_collection_controller.dart';
import '../state/my_collection_state.dart';

import '../widgets/trip_tab_button.dart';
import '../widgets/trip_search_bar.dart';
import '../widgets/empty_trip_state.dart';
import '../widgets/collection_trip_card.dart';
import '../../../core/utils/snackbar_helper.dart';

class MyCollectionScreen extends StatefulWidget {
  const MyCollectionScreen({super.key});

  @override
  State<MyCollectionScreen> createState() => _MyCollectionScreenState();
}

class _MyCollectionScreenState extends State<MyCollectionScreen> {
  late final MyCollectionController _controller;
  MyCollectionState _state = const MyCollectionState();

  final _searchController = TextEditingController();
  final _formatter = DateFormat('MMM d');

  @override
  void initState() {
    super.initState();
    _controller = MyCollectionController(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );
    _load();
  }

  Future<void> _load() async {
    final state = await _controller.loadTrips();
    if (mounted) setState(() => _state = state);
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 1,
      body: Padding(
        padding: AppTheme.defaultPadding,
        child: Column(
          children: [
            TripSearchBar(
              controller: _searchController,
              onChanged:
                  (q) => setState(() => _state = _controller.search(_state, q)),
            ),
            AppTheme.smallSpacing,
            Row(
              children: [
                Expanded(
                  child: TripTabButton(
                    label: 'MY TRIPS',
                    selected: _state.showingMyTrips,
                    onTap:
                        () => setState(() {
                          _state = _controller.toggleTab(_state, true);
                        }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TripTabButton(
                    label: 'SAVED',
                    selected: !_state.showingMyTrips,
                    onTap:
                        () => setState(() {
                          _state = _controller.toggleTab(_state, false);
                        }),
                  ),
                ),
              ],
            ),
            AppTheme.smallSpacing,
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_state.displayedTrips.isEmpty) {
      return EmptyTripState(showingMyTrips: _state.showingMyTrips);
    }

    return ListView.builder(
      itemCount: _state.displayedTrips.length,
      itemBuilder: (context, index) {
        final Trip trip = _state.displayedTrips[index];
        return TripCard(
          trip: trip,
          formatter: _formatter,

          onDelete:
              _state.showingMyTrips
                  ? () async {
                    if (_state.isLoading) return;

                    final tripId = trip.id;

                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: const Text(
                              'Delete Trip',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: AppTheme.largeFontSize,
                              ),
                            ),
                            content: const Text(
                              'Are you sure you want to permanently delete this trip?',
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
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.errorColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadius,
                                    ),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                    );

                    if (confirmed != true) return;

                    setState(() {
                      _state = _state.copyWith(isLoading: true);
                    });

                    setState(() {
                      _state = _state.copyWith(
                        createdTrips:
                            _state.createdTrips
                                .where((t) => t.id != tripId)
                                .toList(),
                        displayedTrips:
                            _state.displayedTrips
                                .where((t) => t.id != tripId)
                                .toList(),
                      );
                    });

                    try {
                      await _controller.deleteTrip(tripId);
                      SnackBarHelper.error('Trip deleted');
                    } catch (e) {
                      SnackBarHelper.error('Delete failed');
                    } finally {
                      if (!mounted) return;
                      setState(() {
                        _state = _state.copyWith(isLoading: false);
                      });
                    }
                  }
                  : null,

          // SAVED → UNSAVE
          onRemove:
              !_state.showingMyTrips
                  ? () async {
                    final tripId = trip.id;

                    // 1️⃣ Optimistic update (UI trước)
                    setState(() {
                      final updatedSaved = List<Trip>.from(_state.savedTrips)
                        ..removeWhere((t) => t.id == tripId);

                      final updatedDisplayed = List<Trip>.from(
                        _state.displayedTrips,
                      )..removeWhere((t) => t.id == tripId);

                      _state = _state.copyWith(
                        savedTrips: updatedSaved,
                        displayedTrips: updatedDisplayed,
                      );
                    });

                    try {
                      await _controller.unsaveTrip(tripId);
                      SnackBarHelper.error('Trip unsaved');
                    } catch (e) {
                      SnackBarHelper.error('Unsave failed');
                    }
                  }
                  : null,

          onCopy:
              !_state.showingMyTrips
                  ? () async {
                    if (_state.isLoading) return;

                    final String? newTripName = await showDialog<String>(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogContext) {
                        final controller = TextEditingController(
                          text: '${trip.name} Copy',
                        );
                        bool isValid = controller.text.trim().isNotEmpty;

                        return StatefulBuilder(
                          builder: (context, setLocalState) {
                            return AlertDialog(
                              backgroundColor: Colors.white,
                              // shape: RoundedRectangleBorder(
                              //   borderRadius: BorderRadius.circular(
                              //     AppTheme.borderRadius,
                              //   ),
                              // ),
                              title: const Text(
                                'Duplicate Trip',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppTheme.largeFontSize,
                                ),
                              ),
                              insetPadding: AppTheme.largePadding,
                              content: SizedBox(
                                // mainAxisSize: MainAxisSize.min,
                                height: AppTheme.fieldHeight,
                                child: TextField(
                                  controller: controller,
                                  autofocus: true,
                                  onChanged: (v) {
                                    setLocalState(() {
                                      isValid = v.trim().isNotEmpty;
                                    });
                                  },
                                  decoration: AppTheme.inputDecoration(
                                    'New Trip Name',
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
                                  onPressed:
                                      () => Navigator.pop(dialogContext, null),
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
                                      isValid
                                          ? () => Navigator.pop(
                                            dialogContext,
                                            controller.text.trim(),
                                          )
                                          : null,
                                  child: const Text('Create Copy'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );

                    if (newTripName == null) return;

                    setState(() => _state = _state.copyWith(isLoading: true));

                    try {
                      final newTrip = await _controller.copyTrip(
                        trip,
                        customName: newTripName,
                      );

                      setState(() {
                        _state = _state.copyWith(
                          createdTrips: [..._state.createdTrips, newTrip],
                          isLoading: false,
                        );
                      });

                      SnackBarHelper.success('Trip copied');
                    } catch (_) {
                      setState(
                        () => _state = _state.copyWith(isLoading: false),
                      );
                      SnackBarHelper.error('Copy failed');
                    }
                  }
                  : null,
        );
      },
    );
  }
}

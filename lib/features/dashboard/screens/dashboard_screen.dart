import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/main_scaffold.dart';
import '../../../core/theme/app_theme.dart';

import '../controller/dashboard_controller.dart';
import '../state/dashboard_state.dart';
import '../dashboard_enums.dart';

import '../widgets/dashboard_search_bar.dart';
import '../widgets/dashboard_sort_bar.dart';
import '../widgets/empty_dashboard_state.dart';
import '../widgets/dashboard_trip_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller;
  DashboardState _state = const DashboardState();

  final _searchController = TextEditingController();
  final _formatter = DateFormat('MMM d');

  @override
  void initState() {
    super.initState();
    _controller = DashboardController(
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
      currentIndex: 0,
      body: Padding(
        padding: AppTheme.defaultPadding,
        child: Column(
          children: [
            DashboardSearchBar(
              controller: _searchController,
              onChanged:
                  (q) => setState(() => _state = _controller.search(_state, q)),
            ),
            AppTheme.smallSpacing,
            DashboardSortBar(
              option: _state.sortOption,
              order: _state.sortOrder,
              onSortChange:
                  (o) => setState(
                    () =>
                        _state = _controller.sort(_state, o, _state.sortOrder),
                  ),
              onToggleOrder:
                  () => setState(
                    () =>
                        _state = _controller.sort(
                          _state,
                          _state.sortOption,
                          _state.sortOrder == SortOrder.ascending
                              ? SortOrder.descending
                              : SortOrder.ascending,
                        ),
                  ),
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
      return EmptyDashboardState(isSearching: _state.isSearching);
    }

    return ListView.builder(
      itemCount: _state.displayedTrips.length,
      itemBuilder: (_, i) {
        final trip = _state.displayedTrips[i];
        return TripCard(
          trip: trip,
          formatter: _formatter,
          isSaved: _state.savedTripIds.contains(trip.id),
          onToggleSave: () async {
            final isSaved = _state.savedTripIds.contains(trip.id);

            try {
              final updated = await _controller.toggleSave(
                _state.savedTripIds,
                trip.id,
              );

              if (!mounted) return;

              setState(() {
                _state = _state.copyWith(savedTripIds: updated);
              });

              if (isSaved) {
                SnackBarHelper.error('Trip unsaved');
              } else {
                SnackBarHelper.success('Trip saved');
              }
            } catch (e) {
              SnackBarHelper.error('Unsave failed');
            }
          },
        );
      },
    );
  }
}

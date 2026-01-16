import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/main_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/enums/sort_enums.dart';

import '../controllers/dashboard_controller.dart';
import '../state/dashboard_state.dart';

import '../widgets/dashboard_search_bar.dart';
import '../widgets/dashboard_sort_bar.dart';
import '../widgets/dashboard_trip_list.dart';

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
            AppTheme.mediumSpacing,
            Expanded(
              child: DashboardTripList(
                state: _state,
                controller: _controller,
                formatter: _formatter,
                onStateChanged: () => setState(() {}),
                updateState: (s) => setState(() => _state = s),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

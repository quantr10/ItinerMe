import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/enums/tab_enum.dart';
import '../../../core/widgets/main_scaffold.dart';
import '../../../core/theme/app_theme.dart';

import '../controllers/my_collection_controller.dart';
import '../state/my_collection_state.dart';

import '../widgets/my_collection_tab_button.dart';
import '../widgets/my_collection_search_bar.dart';
import '../widgets/my_collection_trip_list.dart';

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
                    selected: _state.currentTab == CollectionTab.myTrips,
                    onTap:
                        () => setState(() {
                          _searchController.clear();

                          _state = _controller.toggleTab(
                            _state,
                            CollectionTab.myTrips,
                          );
                        }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TripTabButton(
                    label: 'SAVED',
                    selected: _state.currentTab == CollectionTab.saved,
                    onTap:
                        () => setState(() {
                          _searchController.clear();

                          _state = _controller.toggleTab(
                            _state,
                            CollectionTab.saved,
                          );
                        }),
                  ),
                ),
              ],
            ),
            AppTheme.mediumSpacing,
            Expanded(
              child: MyCollectionTripList(
                state: _state,
                controller: _controller,
                formatter: _formatter,
                updateState: (s) => setState(() => _state = s),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

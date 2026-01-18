import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/repositories/trip_repository.dart';
import '../../../core/enums/tab_enum.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/main_scaffold.dart';

import '../controllers/my_collection_controller.dart';

import '../widgets/my_collection_search_bar.dart';
import '../widgets/my_collection_tab_button.dart';
import '../widgets/my_collection_trip_list.dart';

class MyCollectionScreen extends StatelessWidget {
  const MyCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => MyCollectionController(
            tripRepository: TripRepository(
              firestore: FirebaseFirestore.instance,
              auth: FirebaseAuth.instance,
            ),
          ),
      child: const _MyCollectionView(),
    );
  }
}

class _MyCollectionView extends StatefulWidget {
  const _MyCollectionView();

  @override
  State<_MyCollectionView> createState() => _MyCollectionViewState();
}

class _MyCollectionViewState extends State<_MyCollectionView> {
  final _searchController = TextEditingController();
  final _formatter = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MyCollectionController>();
    final state = controller.state;

    return Stack(
      children: [
        MainScaffold(
          currentIndex: 1,
          body: Padding(
            padding: AppTheme.defaultPadding,
            child: Column(
              children: [
                TripSearchBar(
                  controller: _searchController,
                  onChanged: controller.search,
                ),
                AppTheme.smallSpacing,
                Row(
                  children: [
                    Expanded(
                      child: TripTabButton(
                        label: 'MY TRIPS',
                        selected: state.currentTab == CollectionTab.myTrips,
                        onTap: () {
                          _searchController.clear();
                          controller.toggleTab(CollectionTab.myTrips);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TripTabButton(
                        label: 'SAVED',
                        selected: state.currentTab == CollectionTab.saved,
                        onTap: () {
                          _searchController.clear();
                          controller.toggleTab(CollectionTab.saved);
                        },
                      ),
                    ),
                  ],
                ),
                AppTheme.mediumSpacing,
                Expanded(
                  child: MyCollectionTripList(
                    state: state,
                    controller: controller,
                    formatter: _formatter,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (state.isLoading) Positioned.fill(child: AppTheme.loadingScreen()),
      ],
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/main_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/enums/sort_enums.dart';

import '../controllers/dashboard_controller.dart';

import '../widgets/dashboard_search_bar.dart';
import '../widgets/dashboard_sort_bar.dart';
import '../widgets/dashboard_trip_list.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => DashboardController(
            firestore: FirebaseFirestore.instance,
            auth: FirebaseAuth.instance,
          ),
      child: const _DashboardViewState(),
    );
  }
}

class _DashboardViewState extends StatefulWidget {
  const _DashboardViewState();

  @override
  State<_DashboardViewState> createState() => _DashboardViewStateState();
}

class _DashboardViewStateState extends State<_DashboardViewState> {
  final _searchController = TextEditingController();
  final _formatter = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();
    final state = controller.state;

    return Stack(
      children: [
        MainScaffold(
          currentIndex: 0,
          body: Padding(
            padding: AppTheme.defaultPadding,
            child: Column(
              children: [
                DashboardSearchBar(
                  controller: _searchController,
                  onChanged: controller.search,
                ),
                AppTheme.smallSpacing,
                DashboardSortBar(
                  option: state.sortOption,
                  order: state.sortOrder,
                  onSortChange: (o) => controller.sort(o, state.sortOrder),
                  onToggleOrder:
                      () => controller.sort(
                        state.sortOption,
                        state.sortOrder == SortOrder.ascending
                            ? SortOrder.descending
                            : SortOrder.ascending,
                      ),
                ),
                AppTheme.mediumSpacing,
                Expanded(
                  child: DashboardTripList(
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

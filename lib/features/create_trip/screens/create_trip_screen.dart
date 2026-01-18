import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/repositories/trip_repository.dart';
import '../../../core/services/google_place_service.dart';
import '../../../core/services/trip_ai_service.dart';
import 'package:provider/provider.dart';
import 'package:google_place/google_place.dart';

import '../../../core/enums/interest_tag_enums.dart';
import '../../../core/widgets/main_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/must_visit_place.dart';

import '../controllers/create_trip_controller.dart';

import '../widgets/date_range_picker.dart';
import '../widgets/prediction_list.dart';
import '../widgets/tag_chips.dart';
import '../widgets/transportation_dropdown.dart';
import '../widgets/interests_field.dart';

class CreateTripScreen extends StatelessWidget {
  const CreateTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => CreateTripController(
            googlePlaceService: GooglePlaceService(),
            tripAIService: TripAIService(),
            tripRepository: TripRepository(
              firestore: FirebaseFirestore.instance,
              auth: FirebaseAuth.instance,
            ),
          ),
      child: const _CreateTripView(),
    );
  }
}

class _CreateTripView extends StatefulWidget {
  const _CreateTripView();

  @override
  State<_CreateTripView> createState() => _CreateTripViewState();
}

class _CreateTripViewState extends State<_CreateTripView> {
  static final List<InterestTag> availableTags = InterestTag.values;
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _customTagController = TextEditingController();
  final _mustVisitController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CreateTripController>();
    final state = controller.state;

    if (state.submitSuccess) {
      _nameController.clear();
      _destinationController.clear();
      _budgetController.clear();
      _customTagController.clear();
      _mustVisitController.clear();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.submitSuccess) {
        controller.resetSubmitFlag();
      }
    });

    bool isFormReady =
        _nameController.text.trim().isNotEmpty &&
        state.selectedDestinationName != null &&
        state.startDate != null &&
        state.endDate != null &&
        !_budgetController.text.trim().isEmpty &&
        state.transportation != null;

    return Stack(
      children: [
        MainScaffold(
          currentIndex: 2,
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: AppTheme.defaultPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTheme.mediumSpacing,
                    const Center(
                      child: Text(
                        'Plan a New Trip',
                        style: TextStyle(
                          fontSize: AppTheme.titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    AppTheme.mediumSpacing,

                    // Trip Name
                    SizedBox(
                      height: AppTheme.fieldHeight,
                      child: TextField(
                        controller: _nameController,
                        autofocus: true,
                        decoration: AppTheme.inputDecoration(
                          'Trip Name',
                          onClear: () => _nameController.clear(),
                        ),
                        style: const TextStyle(
                          fontSize: AppTheme.defaultFontSize,
                        ),
                      ),
                    ),
                    AppTheme.smallSpacing,

                    // Destination
                    SizedBox(
                      height: AppTheme.fieldHeight,
                      child: TextField(
                        controller: _destinationController,
                        autofocus: true,
                        onChanged: controller.searchDestination,
                        decoration: AppTheme.inputDecoration(
                          'Destination',
                          onClear: () => _destinationController.clear(),
                        ),
                        style: const TextStyle(
                          fontSize: AppTheme.defaultFontSize,
                        ),
                      ),
                    ),

                    PredictionList<AutocompletePrediction>(
                      predictions: state.destinationPredictions,
                      icon: Icons.place,
                      itemText: (p) => p.description ?? '',
                      onSelect: (p) {
                        _destinationController.text = p.description ?? '';
                        controller.selectDestination(p);
                      },
                    ),

                    AppTheme.smallSpacing,

                    DateRangePicker(
                      startDate: state.startDate,
                      endDate: state.endDate,
                      onSelect: controller.setDateRange,
                    ),

                    AppTheme.smallSpacing,

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: AppTheme.fieldHeight,
                            child: TextField(
                              controller: _budgetController,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              decoration: AppTheme.inputDecoration(
                                'Budget',
                                onClear: () => _budgetController.clear(),
                              ),
                              style: const TextStyle(
                                fontSize: AppTheme.defaultFontSize,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: AppTheme.fieldHeight,
                            child: TransportationDropdown(
                              value: state.transportation,
                              onChanged: controller.setTransportation,
                            ),
                          ),
                        ),
                      ],
                    ),

                    AppTheme.smallSpacing,

                    InterestsField(
                      controller: _customTagController,
                      interestPredictions: state.interestPredictions,
                      interests: state.interests,
                      availableTags: availableTags,
                      onSearch:
                          (v) => controller.searchInterests(v, availableTags),
                      onAdd: controller.addInterest,
                      onRemove: controller.removeInterest,
                    ),

                    AppTheme.smallSpacing,

                    SizedBox(
                      height: AppTheme.fieldHeight,
                      child: TextField(
                        controller: _mustVisitController,
                        autofocus: true,
                        onChanged: controller.searchMustVisit,
                        decoration: AppTheme.inputDecoration(
                          'Add Must-Visit Places',
                          onClear: () => _mustVisitController.clear(),
                        ),
                        style: const TextStyle(
                          fontSize: AppTheme.defaultFontSize,
                        ),
                      ),
                    ),

                    PredictionList<AutocompletePrediction>(
                      predictions: state.mustVisitPredictions,
                      icon: Icons.place,
                      itemText: (p) => p.description ?? '',
                      onSelect: (p) {
                        controller.selectMustVisit(p);
                        _mustVisitController.clear();
                      },
                    ),

                    if (state.mustVisitPlaces.isNotEmpty) ...[
                      AppTheme.smallSpacing,
                      TagChips<MustVisitPlace>(
                        tags: state.mustVisitPlaces,
                        itemText: (p) => p.name,
                        onDelete: controller.removeMustVisit,
                      ),
                    ],

                    AppTheme.largeSpacing,

                    AppTheme.elevatedButton(
                      label: 'GENERATE TRIP',
                      isPrimary: true,
                      onPressed:
                          state.isLoading || !isFormReady
                              ? null
                              : () {
                                controller.submitTrip(
                                  tripName: _nameController.text.trim(),
                                  budget: int.parse(
                                    _budgetController.text.trim(),
                                  ),
                                );
                              },
                    ),
                    AppTheme.mediumSpacing,
                  ],
                ),
              ),
            ],
          ),
        ),
        if (state.isLoading)
          Positioned.fill(child: AppTheme.loadingScreen(overlay: true)),
      ],
    );
  }
}

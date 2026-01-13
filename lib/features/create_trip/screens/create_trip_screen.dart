// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:google_place/google_place.dart';
// import 'package:intl/intl.dart';
// import 'package:itinerme/core/models/must_visit_place.dart';
// import 'package:itinerme/features/trip/services/place_image_cache_service.dart';
// import '../../../core/models/trip.dart';
// import '../../../core/widgets/main_scaffold.dart';
// import '../../trip/services/generate_itinerary_service.dart';
// import '../../../core/theme/app_theme.dart';
// import 'package:calendar_date_picker2/calendar_date_picker2.dart';

// class CreateTripScreen extends StatefulWidget {
//   const CreateTripScreen({super.key});

//   @override
//   State<CreateTripScreen> createState() => _CreateTripScreenState();
// }

// class _CreateTripScreenState extends State<CreateTripScreen> {
//   static const List<String> _availableTags = [
//     'Museums',
//     'Nature',
//     'Culture',
//     'Hidden Gems',
//     'Adventure Travel',
//     'Sightseeing',
//     'Buildings & Landmarks',
//     'Galleries',
//     'Local Food',
//     'Road Trip',
//   ];

//   final _nameController = TextEditingController();
//   final _destinationSearchController = TextEditingController();
//   final _budgetController = TextEditingController();
//   final _customTagController = TextEditingController();
//   final _mustVisitSearchController = TextEditingController();
//   final _scrollController = ScrollController();

//   final FocusNode _destinationFocusNode = FocusNode();
//   final FocusNode _mustVisitFocusNode = FocusNode();
//   final FocusNode _interestsFocusNode = FocusNode();

//   List<String> _interests = [];
//   List<MustVisitPlace> _mustVisitPlaces = [];
//   List<AutocompletePrediction> _destinationPredictions = [];
//   List<AutocompletePrediction> _mustVisitPredictions = [];
//   List<String> _interestPredictions = [];
//   DateTime? _startDate;
//   DateTime? _endDate;
//   String? _transportation;
//   String? _coverPhotoReference;
//   bool _isLoading = false;
//   LatLon? _selectedDestinationCoordinates;
//   String? _selectedDestinationName;

//   late final GooglePlace _googlePlace;

//   @override
//   void initState() {
//     super.initState();
//     _initializeServices();
//     _nameController.addListener(_onFieldChanged);
//     _destinationSearchController.addListener(_onFieldChanged);
//     _budgetController.addListener(_onFieldChanged);
//     _customTagController.addListener(_onFieldChanged);
//   }

//   @override
//   void dispose() {
//     _nameController.removeListener(_onFieldChanged);
//     _destinationSearchController.removeListener(_onFieldChanged);
//     _budgetController.removeListener(_onFieldChanged);
//     _customTagController.removeListener(_onFieldChanged);
//     _disposeControllers();
//     _disposeFocusNodes();
//     super.dispose();
//   }

//   void _initializeServices() {
//     _googlePlace = GooglePlace(dotenv.env['GOOGLE_MAPS_API_KEY']!);
//   }

//   void _disposeControllers() {
//     _nameController.dispose();
//     _destinationSearchController.dispose();
//     _budgetController.dispose();
//     _customTagController.dispose();
//     _mustVisitSearchController.dispose();
//     _scrollController.dispose();
//   }

//   void _disposeFocusNodes() {
//     _destinationFocusNode.dispose();
//     _mustVisitFocusNode.dispose();
//     _interestsFocusNode.dispose();
//   }

//   Future<void> _submitTrip() async {
//     if (!isFormReadyToSubmit) return;
//     setState(() => _isLoading = true);
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) return;

//       final trip = await _createTrip(user.uid);
//       _showSuccessMessage(trip.name);
//       _resetForm();
//     } catch (e) {
//       _handleSubmissionError(e);
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<Trip> _createTrip(String userId) async {
//     final tripRef = FirebaseFirestore.instance.collection('trips').doc();
//     String coverImageUrl =
//         'https://images.unsplash.com/photo-1542038784456-1ea8e935640e?auto=format&fit=crop&w=800&q=60';

//     if (_coverPhotoReference != null) {
//       final cachedUrl = await PlaceImageCacheService.cachePlacePhoto(
//         photoReference: _coverPhotoReference!,
//         path: 'trip_covers/${tripRef.id}.jpg',
//       );

//       if (cachedUrl != null) {
//         coverImageUrl = cachedUrl;
//       }
//     }

//     final trip = Trip(
//       id: tripRef.id,
//       name: _nameController.text.trim(),
//       location: _selectedDestinationName!,
//       coverImageUrl: coverImageUrl, // ✅ FIREBASE URL
//       budget: int.parse(_budgetController.text.trim()),
//       startDate: _startDate!,
//       endDate: _endDate!,
//       transportation: _transportation!,
//       interests: _interests,
//       mustVisitPlaces: _mustVisitPlaces,
//       itinerary: [],
//     );

//     await tripRef.set(trip.toJson());
//     await _updateUserTrips(userId, tripRef.id);

//     final generatedItinerary =
//         await ItineraryGeneratorService.generateItinerary(trip);
//     await tripRef.update({
//       'itinerary': generatedItinerary.map((e) => e.toJson()).toList(),
//     });

//     return trip;
//   }

//   Future<void> _updateUserTrips(String userId, String tripId) async {
//     await FirebaseFirestore.instance.collection('users').doc(userId).update({
//       'createdTripIds': FieldValue.arrayUnion([tripId]),
//     });
//   }

//   void _resetForm() {
//     setState(() {
//       _nameController.clear();
//       _destinationSearchController.clear();
//       _budgetController.clear();
//       _customTagController.clear();
//       _mustVisitSearchController.clear();
//       _interests.clear();
//       _mustVisitPlaces.clear();
//       _startDate = null;
//       _endDate = null;
//       _transportation = null;
//       _selectedDestinationCoordinates = null;
//       _selectedDestinationName = null;
//     });
//   }

//   void _handleSubmissionError(dynamic e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Error ${e.toString()}'),
//         backgroundColor: AppTheme.errorColor,
//         duration: AppTheme.messageDuration,
//       ),
//     );
//   }

//   void _showSuccessMessage(String tripName) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Trip created'),
//         backgroundColor: AppTheme.accentColor,
//         duration: AppTheme.messageDuration,
//       ),
//     );
//   }

//   Future<void> _searchDestination(String value) async {
//     if (value.isEmpty) {
//       setState(() => _destinationPredictions = []);
//       return;
//     }

//     final result = await _googlePlace.autocomplete.get(
//       value,
//       types: '(regions)',
//     );

//     if (result?.predictions != null && mounted) {
//       setState(() => _destinationPredictions = result!.predictions!);
//     }
//   }

//   Future<void> _selectDestination(AutocompletePrediction prediction) async {
//     final placeId = prediction.placeId;
//     if (placeId == null) return;

//     setState(() => _isLoading = true);

//     try {
//       final details = await _googlePlace.details.get(placeId);
//       final result = details?.result;
//       if (result == null) return;

//       final name = result.name;
//       final lat = result.geometry?.location?.lat;
//       final lng = result.geometry?.location?.lng;

//       if (name != null && lat != null && lng != null) {
//         setState(() {
//           _selectedDestinationName = name;
//           _destinationSearchController.text = name;
//           _selectedDestinationCoordinates = LatLon(lat, lng);
//           _destinationPredictions = [];
//           _mustVisitPlaces.clear();
//           _mustVisitSearchController.clear();
//           _coverPhotoReference =
//               result.photos?.isNotEmpty == true
//                   ? result.photos!.first.photoReference
//                   : null;
//         });
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _searchMustVisit(String value) async {
//     if (value.isEmpty || _selectedDestinationCoordinates == null) {
//       setState(() => _mustVisitPredictions = []);
//       return;
//     }

//     final result = await _googlePlace.autocomplete.get(
//       value,
//       location: _selectedDestinationCoordinates!,
//       radius: 100000,
//       strictbounds: true,
//     );

//     if (result?.predictions != null && mounted) {
//       setState(() => _mustVisitPredictions = result!.predictions!);
//     }
//   }

//   Future<void> _selectMustVisit(AutocompletePrediction prediction) async {
//     setState(() => _isLoading = true);

//     try {
//       final details = await _googlePlace.details.get(prediction.placeId ?? '');
//       if (details?.result?.name == null) return;

//       setState(() {
//         _mustVisitPlaces.add(
//           MustVisitPlace(
//             name: details!.result!.name!,
//             placeId: prediction.placeId!,
//           ),
//         );
//         _mustVisitPredictions = [];
//         _mustVisitSearchController.clear();
//       });
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   void _searchInterests(String value) {
//     setState(() {
//       _interestPredictions =
//           value.isEmpty
//               ? []
//               : _availableTags
//                   .where(
//                     (tag) => tag.toLowerCase().contains(value.toLowerCase()),
//                   )
//                   .toList();
//     });
//   }

//   void _addInterest(String interest) {
//     final trimmed = interest.trim();
//     if (trimmed.isEmpty || _interests.contains(trimmed)) return;

//     setState(() {
//       _interests.add(trimmed);
//       _customTagController.clear();
//       _interestPredictions = [];
//     });
//   }

//   void _removeInterest(String interest) {
//     setState(() => _interests.remove(interest));
//   }

//   Future<void> _pickDateRange() async {
//     List<DateTime?> selectedDates = [_startDate, _endDate];

//     await showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text(
//             'Select Date',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: AppTheme.largeFontSize,
//             ),
//           ),

//           insetPadding: AppTheme.largePadding,
//           content: SizedBox(
//             height: 250,
//             width: 350,
//             child: CalendarDatePicker2(
//               config: CalendarDatePicker2Config(
//                 calendarType: CalendarDatePicker2Type.range,
//                 selectedDayHighlightColor: AppTheme.primaryColor,
//                 centerAlignModePicker: true,
//                 dayTextStyle: const TextStyle(
//                   fontSize: AppTheme.defaultFontSize,
//                 ),
//                 weekdayLabelTextStyle: const TextStyle(
//                   fontSize: AppTheme.defaultFontSize,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 controlsHeight: 50,
//                 useAbbrLabelForMonthModePicker: true,
//                 daySplashColor: Colors.transparent,
//                 disabledDayTextStyle: const TextStyle(
//                   color: AppTheme.hintColor,
//                 ),
//                 modePickersGap: 8,
//                 lastDate: DateTime.now().add(const Duration(days: 365)),
//               ),
//               value: selectedDates,
//               onValueChanged: (dates) {
//                 setState(() {
//                   selectedDates = dates;
//                 });
//               },
//             ),
//           ),
//           actions: [
//             TextButton(
//               style: ElevatedButton.styleFrom(
//                 foregroundColor: Colors.black,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(AppTheme.borderRadius),
//                 ),
//               ),
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppTheme.primaryColor,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(AppTheme.borderRadius),
//                 ),
//               ),
//               onPressed: () {
//                 if (selectedDates.length == 2 &&
//                     selectedDates[0] != null &&
//                     selectedDates[1] != null) {
//                   setState(() {
//                     _startDate = selectedDates[0]!;
//                     _endDate = selectedDates[1]!;
//                   });
//                 }
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Save'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   IconData _getTransportationIcon(String type) {
//     switch (type.toLowerCase()) {
//       case 'car':
//         return Icons.directions_car;
//       case 'bus/metro':
//         return Icons.directions_bus;
//       case 'motorbike':
//         return Icons.motorcycle;
//       default:
//         return Icons.directions;
//     }
//   }

//   Widget _buildPredictionList<T>(
//     List<T> predictions,
//     void Function(T) onSelect,
//     IconData icon,
//     String Function(T) itemText,
//   ) {
//     return AnimatedContainer(
//       duration: AppTheme.animationDuration,
//       margin: const EdgeInsets.only(top: 4),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(AppTheme.borderRadius),
//         boxShadow: [AppTheme.defaultShadow],
//       ),
//       child: ListView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         itemCount: predictions.length,
//         itemBuilder:
//             (context, index) => ListTile(
//               leading: Icon(icon, color: AppTheme.primaryColor),
//               title: Text(
//                 itemText(predictions[index]),
//                 style: TextStyle(
//                   fontSize: AppTheme.defaultFontSize,
//                   color: Colors.black,
//                 ),
//               ),
//               onTap: () => onSelect(predictions[index]),
//             ),
//       ),
//     );
//   }

//   Widget _buildTagChips<T>(
//     List<T> tags,
//     void Function(T) onDelete,
//     String Function(T) itemText,
//   ) {
//     return AnimatedSize(
//       duration: AppTheme.animationDuration,
//       child:
//           tags.isEmpty
//               ? const SizedBox()
//               : Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 children:
//                     tags.map((tag) {
//                       final tagText = itemText(tag);
//                       return Container(
//                         height: 24,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(
//                             AppTheme.borderRadius,
//                           ),
//                           color: AppTheme.primaryColor,
//                           border: Border.all(
//                             color: AppTheme.primaryColor,
//                             width: AppTheme.borderWidth,
//                           ),
//                           boxShadow: [AppTheme.defaultShadow],
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 4),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               const SizedBox(width: 8),
//                               Flexible(
//                                 child: Text(
//                                   tagText,
//                                   style: TextStyle(
//                                     fontSize: AppTheme.defaultFontSize,
//                                     color: Colors.white,
//                                   ),
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                               const SizedBox(width: 8),

//                               GestureDetector(
//                                 behavior: HitTestBehavior.opaque,
//                                 onTap: () => onDelete(tag),
//                                 child: Padding(
//                                   padding: EdgeInsets.zero,
//                                   child: Icon(
//                                     Icons.close,
//                                     size: AppTheme.mediumIconFont,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                             ],
//                           ),
//                         ),
//                       );
//                     }).toList(),
//               ),
//     );
//   }

//   Widget _buildTransportationDropdown() {
//     return SizedBox(
//       height: AppTheme.fieldHeight,
//       child: DropdownButtonFormField<String>(
//         value: _transportation,
//         isExpanded: true,
//         decoration: AppTheme.inputDecoration('Transportation').copyWith(
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 12,
//             vertical: 10,
//           ),
//           isDense: true,
//         ),
//         items:
//             ['Bus/Metro', 'Car', 'Motorbike']
//                 .map(
//                   (t) => DropdownMenuItem(
//                     value: t,
//                     child: Row(
//                       children: [
//                         SizedBox(
//                           width: 40,
//                           child: Icon(
//                             _getTransportationIcon(t),
//                             color: AppTheme.primaryColor,
//                             size: AppTheme.largeIconFont,
//                           ),
//                         ),
//                         Expanded(
//                           child: Text(
//                             t,
//                             style: const TextStyle(
//                               fontSize: AppTheme.defaultFontSize,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//                 .toList(),
//         onChanged: (value) {
//           setState(() => _transportation = value);
//         },
//         dropdownColor: Colors.white,
//         icon: const Icon(
//           Icons.arrow_drop_down,
//           size: AppTheme.largeIconFont,
//           color: AppTheme.primaryColor,
//         ),
//         style: const TextStyle(fontSize: AppTheme.defaultFontSize),
//         borderRadius: BorderRadius.circular(AppTheme.borderRadius),
//       ),
//     );
//   }

//   Widget _buildInterestsField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: SizedBox(
//                 height: AppTheme.fieldHeight,
//                 child: TextField(
//                   controller: _customTagController,
//                   focusNode: _interestsFocusNode,
//                   decoration: AppTheme.inputDecoration(
//                     'Add Interests',
//                     onClear: () {
//                       _customTagController.clear();
//                       setState(() => _interestPredictions = []);
//                     },
//                   ),
//                   style: TextStyle(fontSize: AppTheme.defaultFontSize),
//                   onChanged: _searchInterests,
//                   onSubmitted: _addInterest,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             SizedBox(
//               height: AppTheme.fieldHeight,
//               child: ElevatedButton(
//                 onPressed: () {
//                   if (_customTagController.text.trim().isNotEmpty) {
//                     _addInterest(_customTagController.text);
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppTheme.primaryColor,
//                   foregroundColor: Colors.white,
//                   padding: AppTheme.horizontalPadding,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(AppTheme.borderRadius),
//                   ),
//                 ),
//                 child: const Text(
//                   'Add',
//                   style: TextStyle(fontSize: AppTheme.defaultFontSize),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         if (_interestPredictions.isNotEmpty)
//           _buildPredictionList<String>(
//             _interestPredictions,
//             _addInterest,
//             Icons.label,
//             (interest) => interest,
//           ),
//         if (_interests.isNotEmpty) ...[
//           AppTheme.smallSpacing,
//           _buildTagChips<String>(
//             _interests,
//             _removeInterest,
//             (interest) => interest,
//           ),
//         ],
//       ],
//     );
//   }

//   bool get isFormReadyToSubmit {
//     return _nameController.text.trim().isNotEmpty &&
//         _selectedDestinationName != null &&
//         _selectedDestinationCoordinates != null &&
//         _startDate != null &&
//         _endDate != null &&
//         !_endDate!.isBefore(_startDate!) &&
//         _budgetController.text.trim().isNotEmpty &&
//         _transportation != null;
//   }

//   void _onFieldChanged() {
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MainScaffold(
//       currentIndex: 2,
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             controller: _scrollController,
//             padding: AppTheme.defaultPadding,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 AppTheme.mediumSpacing,
//                 const Center(
//                   child: Text(
//                     'Plan a New Trip',
//                     style: TextStyle(
//                       fontSize: AppTheme.titleFontSize,
//                       fontWeight: FontWeight.bold,
//                       color: AppTheme.primaryColor,
//                     ),
//                   ),
//                 ),
//                 AppTheme.mediumSpacing,

//                 SizedBox(
//                   height: AppTheme.fieldHeight,
//                   child: TextField(
//                     controller: _nameController,
//                     decoration: AppTheme.inputDecoration(
//                       'Trip Name',
//                       onClear: () => _nameController.clear(),
//                     ),
//                     style: TextStyle(fontSize: AppTheme.defaultFontSize),
//                   ),
//                 ),
//                 AppTheme.smallSpacing,

//                 SizedBox(
//                   height: AppTheme.fieldHeight,
//                   child: TextField(
//                     controller: _destinationSearchController,
//                     focusNode: _destinationFocusNode,
//                     decoration: AppTheme.inputDecoration(
//                       'Destination',
//                       onClear: () {
//                         _destinationSearchController.clear();
//                         setState(() {
//                           _destinationPredictions = [];
//                           _selectedDestinationName = null;
//                           _selectedDestinationCoordinates = null;
//                         });
//                       },
//                     ),
//                     style: TextStyle(fontSize: AppTheme.defaultFontSize),
//                     onChanged: _searchDestination,
//                   ),
//                 ),
//                 if (_destinationPredictions.isNotEmpty)
//                   _buildPredictionList<AutocompletePrediction>(
//                     _destinationPredictions,
//                     _selectDestination,
//                     Icons.place,
//                     (prediction) => prediction.description ?? '',
//                   ),

//                 AppTheme.smallSpacing,

//                 _DateRangePicker(
//                   startDate: _startDate,
//                   endDate: _endDate,
//                   onTap: _pickDateRange,
//                   onClear: () {
//                     setState(() {
//                       _startDate = null;
//                       _endDate = null;
//                     });
//                   },
//                 ),
//                 AppTheme.smallSpacing,

//                 Row(
//                   children: [
//                     Expanded(
//                       child: SizedBox(
//                         height: AppTheme.fieldHeight,
//                         child: TextField(
//                           controller: _budgetController,
//                           keyboardType: TextInputType.number,
//                           decoration: AppTheme.inputDecoration(
//                             'Budget',
//                             onClear: () => _budgetController.clear(),
//                           ),
//                           style: TextStyle(fontSize: AppTheme.defaultFontSize),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(child: _buildTransportationDropdown()),
//                   ],
//                 ),
//                 AppTheme.smallSpacing,

//                 _buildInterestsField(),
//                 AppTheme.smallSpacing,

//                 SizedBox(
//                   height: AppTheme.fieldHeight,
//                   child: TextField(
//                     controller: _mustVisitSearchController,
//                     focusNode: _mustVisitFocusNode,
//                     onChanged: _searchMustVisit,
//                     decoration: AppTheme.inputDecoration(
//                       'Add Must-Visit Places',
//                       onClear: () {
//                         _mustVisitSearchController.clear();
//                         setState(() => _mustVisitPredictions = []);
//                       },
//                     ),
//                     style: TextStyle(fontSize: AppTheme.defaultFontSize),
//                   ),
//                 ),
//                 if (_mustVisitPredictions.isNotEmpty)
//                   _buildPredictionList<AutocompletePrediction>(
//                     _mustVisitPredictions,
//                     _selectMustVisit,
//                     Icons.place,
//                     (prediction) => prediction.description ?? '',
//                   ),
//                 if (_mustVisitPlaces.isNotEmpty) ...[
//                   AppTheme.smallSpacing,
//                   _buildTagChips<MustVisitPlace>(
//                     _mustVisitPlaces,
//                     (place) => setState(() => _mustVisitPlaces.remove(place)),
//                     (place) => place.name,
//                   ),
//                 ],
//                 AppTheme.largeSpacing,

//                 SizedBox(
//                   width: double.infinity,
//                   height: AppTheme.fieldHeight,
//                   child: ElevatedButton(
//                     onPressed:
//                         _isLoading || !isFormReadyToSubmit ? null : _submitTrip,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppTheme.primaryColor,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(
//                           AppTheme.borderRadius,
//                         ),
//                       ),
//                       elevation: 2,
//                     ),
//                     child: const Text(
//                       'GENERATE TRIP',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: AppTheme.defaultFontSize,
//                       ),
//                     ),
//                   ),
//                 ),
//                 AppTheme.mediumSpacing,
//               ],
//             ),
//           ),
//           if (_isLoading)
//             Stack(
//               children: [
//                 Container(color: Colors.white.withOpacity(0.7)),
//                 const Center(
//                   child: CircularProgressIndicator(
//                     valueColor: AlwaysStoppedAnimation<Color>(
//                       AppTheme.primaryColor,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//         ],
//       ),
//     );
//   }
// }

// class _DateRangePicker extends StatelessWidget {
//   final DateTime? startDate;
//   final DateTime? endDate;
//   final VoidCallback onTap;
//   final VoidCallback onClear;

//   const _DateRangePicker({
//     required this.startDate,
//     required this.endDate,
//     required this.onTap,
//     required this.onClear,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(AppTheme.borderRadius),
//       child: AnimatedContainer(
//         duration: AppTheme.animationDuration,
//         padding: AppTheme.horizontalPadding,
//         height: AppTheme.fieldHeight,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(color: AppTheme.primaryColor, width: 1),
//           borderRadius: BorderRadius.circular(AppTheme.borderRadius),
//         ),
//         child: Row(
//           children: [
//             const Icon(
//               Icons.calendar_today,
//               color: AppTheme.primaryColor,
//               size: AppTheme.largeIconFont,
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child:
//                   (startDate != null && endDate != null)
//                       ? Text(
//                         '${DateFormat('MMM d, yyyy').format(startDate!)} - ${DateFormat('MMM d, yyyy').format(endDate!)}',
//                         style: const TextStyle(
//                           fontSize: AppTheme.defaultFontSize,
//                         ),
//                       )
//                       : Text(
//                         'Select Date',
//                         style: TextStyle(
//                           color: AppTheme.hintColor,
//                           fontSize: AppTheme.defaultFontSize,
//                         ),
//                       ),
//             ),
//             const Icon(
//               Icons.arrow_forward_ios,
//               color: AppTheme.primaryColor,
//               size: AppTheme.smallIconFont,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_place/google_place.dart';

import '../../../core/widgets/main_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/must_visit_place.dart';

import '../controller/create_trip_controller.dart';
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
      create: (_) => CreateTripController(),
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
  static const List<String> availableTags = [
    'Museums',
    'Nature',
    'Culture',
    'Hidden Gems',
    'Adventure Travel',
    'Sightseeing',
    'Buildings & Landmarks',
    'Galleries',
    'Local Food',
    'Road Trip',
  ];

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

    return MainScaffold(
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
                    style: const TextStyle(fontSize: AppTheme.defaultFontSize),
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
                    style: const TextStyle(fontSize: AppTheme.defaultFontSize),
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
                  onSearch: (v) => controller.searchInterests(v, availableTags),
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
                    style: const TextStyle(fontSize: AppTheme.defaultFontSize),
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

                SizedBox(
                  width: double.infinity,
                  height: AppTheme.fieldHeight,
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius,
                        ),
                      ),
                    ),
                    child: const Text(
                      'GENERATE TRIP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.defaultFontSize,
                      ),
                    ),
                  ),
                ),
                AppTheme.mediumSpacing,
              ],
            ),
          ),

          if (state.isLoading)
            Stack(
              children: [
                Container(color: Colors.white.withOpacity(0.7)),
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

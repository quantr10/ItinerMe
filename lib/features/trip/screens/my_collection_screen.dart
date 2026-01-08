import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:itinerme/features/trip/widgets/collection_trip_card.dart';

import '../models/trip.dart';
import '../../../core/widgets/main_scaffold.dart';
import '../../../core/theme/app_theme.dart';

class MyCollectionScreen extends StatefulWidget {
  const MyCollectionScreen({super.key});

  @override
  State<MyCollectionScreen> createState() => _MyCollectionScreenState();
}

class _MyCollectionScreenState extends State<MyCollectionScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final DateFormat _formatter = DateFormat('MMM d');

  List<Trip> createdTrips = [];
  List<Trip> savedTrips = [];
  List<Trip> displayedTrips = [];
  bool showingMyTrips = true;
  bool isLoading = true;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    fetchTrips();
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        setState(() => isSearching = true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> fetchTrips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final savedTripIds = List<String>.from(
        userDoc.data()?['savedTripIds'] ?? [],
      );
      final createdTripIds = List<String>.from(
        userDoc.data()?['createdTripIds'] ?? [],
      );

      final snapshot =
          await FirebaseFirestore.instance.collection('trips').get();
      final trips =
          snapshot.docs
              .map((doc) => Trip.fromJson({...doc.data(), 'id': doc.id}))
              .toList();

      if (!mounted) return;

      setState(() {
        createdTrips =
            trips.where((t) => createdTripIds.contains(t.id)).toList();
        savedTrips = trips.where((t) => savedTripIds.contains(t.id)).toList();
        displayedTrips = createdTrips;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: AppTheme.messageDuration,
          ),
        );
        setState(() => isLoading = false);
      }
    }
  }

  void _searchTrips(String query) {
    setState(() {
      isSearching = query.isNotEmpty;
      final lower = query.toLowerCase();
      final base = showingMyTrips ? createdTrips : savedTrips;

      displayedTrips =
          base
              .where(
                (trip) =>
                    trip.name.toLowerCase().contains(lower) ||
                    trip.location.toLowerCase().contains(lower),
              )
              .toList();
    });
  }

  void _toggleTripView(bool showMyTrips) {
    setState(() {
      showingMyTrips = showMyTrips;
      displayedTrips = showMyTrips ? createdTrips : savedTrips;
      if (!isSearching) _searchController.clear();
    });
  }

  Future<void> _removeSavedTrip(String tripId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'savedTripIds': FieldValue.arrayRemove([tripId]),
    });

    setState(() {
      savedTrips.removeWhere((trip) => trip.id == tripId);
      displayedTrips.removeWhere((trip) => trip.id == tripId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Trip unsaved'),
        backgroundColor: AppTheme.errorColor,
        duration: AppTheme.messageDuration,
      ),
    );
  }

  Future<void> _copyTrip(Trip original) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newNameController = TextEditingController(
      text: '${original.name} Copy',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          title: const Text(
            'Duplicate Trip',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppTheme.largeFontSize,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You’re about to create a copy of this trip. You can rename it below.',
                style: TextStyle(fontSize: AppTheme.defaultFontSize),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  boxShadow: [AppTheme.defaultShadow],
                ),
                child: SizedBox(
                  height: AppTheme.fieldHeight,
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: newNameController,
                    builder: (context, value, child) {
                      return TextField(
                        controller: newNameController,
                        decoration: AppTheme.inputDecoration(
                          'New Trip Name',
                          onClear: () => newNameController.clear(),
                          prefixIcon: const Icon(
                            Icons.edit,
                            color: AppTheme.primaryColor,
                            size: AppTheme.largeIconFont,
                          ),
                        ),
                        style: TextStyle(fontSize: AppTheme.defaultFontSize),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),

            ValueListenableBuilder<TextEditingValue>(
              valueListenable: newNameController,
              builder: (context, value, _) {
                final isValid = value.text.trim().isNotEmpty;

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isValid ? AppTheme.primaryColor : AppTheme.hintColor,
                    foregroundColor: isValid ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                    ),
                  ),
                  onPressed:
                      isValid ? () => Navigator.pop(context, true) : null,
                  child: const Text('Create Copy'),
                );
              },
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final newTripDoc = FirebaseFirestore.instance.collection('trips').doc();

      final newTrip = Trip(
        id: newTripDoc.id,
        name: newNameController.text,
        location: original.location,
        coverImageUrl: original.coverImageUrl,
        budget: original.budget,
        startDate: original.startDate,
        endDate: original.endDate,
        transportation: original.transportation,
        interests: List.from(original.interests),
        mustVisitPlaces: List.from(original.mustVisitPlaces),
        itinerary: List.from(original.itinerary),
      );

      await newTripDoc.set(newTrip.toJson());

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'createdTripIds': FieldValue.arrayUnion([newTrip.id]),
        },
      );

      setState(() {
        createdTrips.add(newTrip);
        if (showingMyTrips) displayedTrips.add(newTrip);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip copied'),
          backgroundColor: AppTheme.accentColor,
          duration: AppTheme.messageDuration,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          duration: AppTheme.messageDuration,
        ),
      );
    }
  }

  Future<void> _deleteCreatedTrip(String tripId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          title: const Text(
            'Delete Trip',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppTheme.largeFontSize,
            ),
          ),
          content: const Text(
            'Are you sure you want to permanently delete this trip? This action cannot be undone.',
            style: TextStyle(fontSize: AppTheme.defaultFontSize),
          ),
          actions: [
            TextButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
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
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).delete();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'createdTripIds': FieldValue.arrayRemove([tripId]),
        },
      );

      setState(() {
        createdTrips.removeWhere((trip) => trip.id == tripId);
        displayedTrips.removeWhere((trip) => trip.id == tripId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip deleted'),
          backgroundColor: AppTheme.errorColor,
          duration: AppTheme.messageDuration,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          duration: AppTheme.messageDuration,
        ),
      );
    }
  }

  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [AppTheme.defaultShadow],
      ),
      child: SizedBox(
        height: AppTheme.fieldHeight,
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _searchTrips,
          decoration: AppTheme.inputDecoration(
            'Search trips and locations...',
            onClear: () => _searchController.clear(),
            prefixIcon: const Icon(
              Icons.search,
              color: AppTheme.primaryColor,
              size: AppTheme.largeIconFont,
            ),
          ),
          style: TextStyle(fontSize: AppTheme.defaultFontSize),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 1,
      body: Padding(
        padding: AppTheme.defaultPadding,
        child: ListView(
          controller: _scrollController,
          children: [
            _buildSearch(),
            AppTheme.smallSpacing,
            Row(
              children: [
                Expanded(
                  child: _TripTabButton(
                    label: 'MY TRIPS',
                    isSelected: showingMyTrips,
                    onTap: () => _toggleTripView(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TripTabButton(
                    label: 'SAVED',
                    isSelected: !showingMyTrips,
                    onTap: () => _toggleTripView(false),
                  ),
                ),
              ],
            ),
            AppTheme.smallSpacing,
            if (isLoading)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                ),
              )
            else if (displayedTrips.isEmpty)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        showingMyTrips
                            ? Icons.travel_explore
                            : Icons.bookmark_border,
                        size: 60,
                        color: AppTheme.secondaryColor,
                      ),
                      AppTheme.mediumSpacing,
                      Text(
                        showingMyTrips
                            ? 'No trips created yet'
                            : 'No trips saved yet',
                        style: TextStyle(
                          fontSize: AppTheme.largeFontSize,
                          color: AppTheme.hintColor,
                        ),
                      ),
                      AppTheme.smallSpacing,
                      Text(
                        showingMyTrips
                            ? 'Start planning your first trip!'
                            : 'Save trips to see them here',
                        style: TextStyle(
                          fontSize: AppTheme.defaultFontSize,
                          color: AppTheme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...displayedTrips.map(
                (trip) => AnimatedSwitcher(
                  duration: AppTheme.animationDuration,
                  child: TripCard(
                    key: ValueKey(trip.id),
                    trip: trip,
                    formatter: _formatter,
                    onDelete:
                        showingMyTrips
                            ? () => _deleteCreatedTrip(trip.id)
                            : null,
                    onRemove:
                        showingMyTrips ? null : () => _removeSavedTrip(trip.id),
                    onCopy: showingMyTrips ? null : () => _copyTrip(trip),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TripTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TripTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: Container(
        height: AppTheme.fieldHeight,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: Colors.white, width: AppTheme.borderWidth),
          boxShadow: [AppTheme.defaultShadow],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

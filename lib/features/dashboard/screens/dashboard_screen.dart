import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:itinerme/features/trip/models/trip.dart';
import 'package:itinerme/features/trip/widgets/dashboard_trip_card.dart';
import '../../../core/widgets/main_scaffold.dart';
import '../../../core/theme/app_theme.dart';

enum SortOption { name, startDate, location }

enum SortOrder { ascending, descending }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final DateFormat _formatter = DateFormat('MMM d');

  List<Trip> allTrips = [];
  List<Trip> displayedTrips = [];
  Set<String> savedTripIds = {};
  bool isLoading = true;
  bool isSearching = false;
  SortOption _currentSort = SortOption.name;
  SortOrder _currentOrder = SortOrder.ascending;

  @override
  void initState() {
    super.initState();
    _fetchTrips();
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

  Future<void> _fetchTrips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      savedTripIds = Set<String>.from(userDoc.data()?['savedTripIds'] ?? []);
      final createdTripIds = Set<String>.from(
        userDoc.data()?['createdTripIds'] ?? [],
      );

      final snapshot =
          await FirebaseFirestore.instance.collection('trips').get();
      final trips =
          snapshot.docs
              .map((doc) => Trip.fromJson({...doc.data(), 'id': doc.id}))
              .where((trip) => !createdTripIds.contains(trip.id))
              .toList();

      if (!mounted) return;

      setState(() {
        allTrips = trips;
        displayedTrips = trips;
        _sortTrips(_currentSort, _currentOrder);
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

  Future<void> _toggleSavedTrip(Trip trip) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final isSaved = savedTripIds.contains(trip.id);

    setState(() {
      isSaved ? savedTripIds.remove(trip.id) : savedTripIds.add(trip.id);
    });

    await userRef.update({
      'savedTripIds':
          isSaved
              ? FieldValue.arrayRemove([trip.id])
              : FieldValue.arrayUnion([trip.id]),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSaved ? 'Trip unsaved' : 'Trip saved'),
        backgroundColor: isSaved ? AppTheme.errorColor : AppTheme.accentColor,
        duration: AppTheme.messageDuration,
      ),
    );
  }

  void _searchTrips(String query) {
    setState(() {
      isSearching = query.isNotEmpty;
      final lower = query.toLowerCase();
      displayedTrips =
          allTrips.where((trip) {
            return trip.name.toLowerCase().contains(lower) ||
                trip.location.toLowerCase().contains(lower);
          }).toList();
      _sortTrips(_currentSort, _currentOrder);
    });
  }

  void _sortTrips(SortOption option, SortOrder order) {
    _currentSort = option;
    _currentOrder = order;
    displayedTrips.sort((a, b) {
      int comparison;
      switch (option) {
        case SortOption.name:
          comparison = a.name.compareTo(b.name);
          break;
        case SortOption.startDate:
          comparison = a.startDate.compareTo(b.startDate);
          break;
        case SortOption.location:
          comparison = a.location.compareTo(b.location);
          break;
      }
      return order == SortOrder.ascending ? comparison : -comparison;
    });
  }

  Widget _buildSearchAndSort() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            boxShadow: [AppTheme.defaultShadow],
          ),
          child: SizedBox(
            height: AppTheme.fieldHeight,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _searchTrips,
                  decoration: AppTheme.inputDecoration(
                    'Search trips and locations...',
                    onClear: () {
                      _searchController.clear();
                      _searchTrips('');
                    },
                    prefixIcon: const Icon(
                      Icons.search,
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
        AppTheme.smallSpacing,
        Row(
          children: [
            Expanded(
              child: Container(
                height: AppTheme.fieldHeight,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  boxShadow: [AppTheme.defaultShadow],
                  border: Border.all(
                    color: Colors.white,
                    width: AppTheme.borderWidth,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sort,
                      size: AppTheme.largeIconFont,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<SortOption>(
                          value: _currentSort,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            size: AppTheme.largeIconFont,
                            color: AppTheme.primaryColor,
                          ),
                          decoration: const InputDecoration.collapsed(
                            hintText: '',
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                          style: const TextStyle(
                            fontSize: AppTheme.defaultFontSize,
                            color: Colors.black,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: SortOption.name,
                              child: Text('Name'),
                            ),
                            DropdownMenuItem(
                              value: SortOption.startDate,
                              child: Text('Start Date'),
                            ),
                            DropdownMenuItem(
                              value: SortOption.location,
                              child: Text('Location'),
                            ),
                          ],
                          onChanged: (SortOption? newValue) {
                            if (newValue != null) {
                              setState(
                                () => _sortTrips(newValue, _currentOrder),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _currentOrder =
                              _currentOrder == SortOrder.ascending
                                  ? SortOrder.descending
                                  : SortOrder.ascending;
                          _sortTrips(_currentSort, _currentOrder);
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.zero,
                        child: Icon(
                          _currentOrder == SortOrder.ascending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: AppTheme.largeIconFont,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      body: Padding(
        padding: AppTheme.defaultPadding,
        child: ListView(
          controller: _scrollController,
          children: [
            _buildSearchAndSort(),
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
                        isSearching ? Icons.search_off : Icons.travel_explore,
                        size: 60,
                        color: AppTheme.secondaryColor,
                      ),
                      AppTheme.mediumSpacing,
                      Text(
                        isSearching ? 'No results found' : 'No trips available',
                        style: TextStyle(
                          fontSize: AppTheme.largeFontSize,
                          color: AppTheme.hintColor,
                        ),
                      ),
                      AppTheme.smallSpacing,
                      Text(
                        isSearching
                            ? 'Try a different search term'
                            : 'Check back later for new trips',
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
                    key: ValueKey(
                      trip.id + savedTripIds.contains(trip.id).toString(),
                    ),
                    trip: trip,
                    formatter: _formatter,
                    isSaved: savedTripIds.contains(trip.id),
                    onToggleSave: () => _toggleSavedTrip(trip),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

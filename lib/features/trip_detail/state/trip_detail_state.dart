class TripDetailState {
  final bool canEdit;
  final Set<String> expandedDestinations;
  final bool isLoading;

  const TripDetailState({
    this.canEdit = false,
    this.expandedDestinations = const {},
    this.isLoading = false,
  });

  TripDetailState copyWith({
    bool? canEdit,
    Set<String>? expandedDestinations,
    bool? isLoading,
  }) {
    return TripDetailState(
      canEdit: canEdit ?? this.canEdit,
      expandedDestinations: expandedDestinations ?? this.expandedDestinations,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

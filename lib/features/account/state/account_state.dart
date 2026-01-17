class AccountState {
  final bool isUploading;
  final String? avatarUrl;

  const AccountState({this.isUploading = false, this.avatarUrl});

  AccountState copyWith({bool? isUploading, String? avatarUrl}) {
    return AccountState(
      isUploading: isUploading ?? this.isUploading,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

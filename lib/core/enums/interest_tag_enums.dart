enum InterestTag {
  museums,
  nature,
  culture,
  hiddenGems,
  adventureTravel,
  sightseeing,
  landmarks,
  galleries,
  localFood,
  roadTrip,
}

extension InterestTagX on InterestTag {
  String get label {
    switch (this) {
      case InterestTag.museums:
        return 'Museums';
      case InterestTag.nature:
        return 'Nature';
      case InterestTag.culture:
        return 'Culture';
      case InterestTag.hiddenGems:
        return 'Hidden Gems';
      case InterestTag.adventureTravel:
        return 'Adventure Travel';
      case InterestTag.sightseeing:
        return 'Sightseeing';
      case InterestTag.landmarks:
        return 'Buildings & Landmarks';
      case InterestTag.galleries:
        return 'Galleries';
      case InterestTag.localFood:
        return 'Local Food';
      case InterestTag.roadTrip:
        return 'Road Trip';
    }
  }
}

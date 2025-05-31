enum Rank {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  master,
  grandMaster;

  Rank get nextRank {
    const values = Rank.values;
    final nextIndex = index + 1;
    return nextIndex < values.length ? values[nextIndex] : this;
  }

  Rank get previousRank {
    const values = Rank.values;
    final prevIndex = index - 1;
    return prevIndex >= 0 ? values[prevIndex] : this;
  }

  bool get isHighestRank => this == Rank.grandMaster;
  bool get isLowestRank => this == Rank.bronze;

  int get positiveMultiplier {
    return ((Rank.values.length - 1) /*6*/ - index) %
        (Rank.values
            .length) /*7*/; //this function will return 6,5,4,3,2,1,0 so in opposite order
  }

  int get negativeMultiplier {
    return index;
  }

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}


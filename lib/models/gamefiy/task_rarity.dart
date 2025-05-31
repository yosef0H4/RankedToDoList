import 'package:flutter/material.dart';

enum TaskRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic;

  int get multiplier {
    return index;
  }

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}

class RarityProperties {
  final Color color;
  final String label;

  const RarityProperties({required this.color, required this.label});

  static Map<TaskRarity, RarityProperties> rarityMap = {
    TaskRarity.common: RarityProperties(
      color: Colors.grey.shade400,
      label: 'Common',
    ),
    TaskRarity.uncommon: RarityProperties(
      color: Colors.green.shade500,
      label: 'Uncommon',
    ),
    TaskRarity.rare: RarityProperties(
      color: Colors.blue.shade500,
      label: 'Rare',
    ),
    TaskRarity.epic: RarityProperties(
      color: Colors.purple.shade500,
      label: 'Epic',
    ),
    TaskRarity.legendary: RarityProperties(
      color: Colors.orange.shade600,
      label: 'Legendary',
    ),
    TaskRarity.mythic: RarityProperties(
      color: Colors.red.shade600,
      label: 'Mythic',
    ),
  };

  static RarityProperties getPropertiesForRarity(TaskRarity rarity) {
    return rarityMap[rarity]!;
  }
}


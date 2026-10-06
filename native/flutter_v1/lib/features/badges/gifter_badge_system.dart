class FvGifterBadgeTier {
  const FvGifterBadgeTier({
    required this.id,
    required this.label,
    required this.icon,
    required this.minLevel,
    required this.maxLevel,
  });

  final String id;
  final String label;
  final String icon;
  final int minLevel;
  final int maxLevel;
}

const fvGifterBadgeTiers = <FvGifterBadgeTier>[
  FvGifterBadgeTier(
    id: 'spark',
    label: 'Spark Gifter',
    icon: '✦',
    minLevel: 1,
    maxLevel: 4,
  ),
  FvGifterBadgeTier(
    id: 'bronze',
    label: 'Bronze Gifter',
    icon: '◆',
    minLevel: 5,
    maxLevel: 9,
  ),
  FvGifterBadgeTier(
    id: 'silver',
    label: 'Silver Gifter',
    icon: '✧',
    minLevel: 10,
    maxLevel: 19,
  ),
  FvGifterBadgeTier(
    id: 'gold',
    label: 'Gold Gifter',
    icon: '★',
    minLevel: 20,
    maxLevel: 29,
  ),
  FvGifterBadgeTier(
    id: 'platinum',
    label: 'Platinum Gifter',
    icon: '⬢',
    minLevel: 30,
    maxLevel: 49,
  ),
  FvGifterBadgeTier(
    id: 'diamond',
    label: 'Diamond Gifter',
    icon: '◇',
    minLevel: 50,
    maxLevel: 69,
  ),
  FvGifterBadgeTier(
    id: 'royal',
    label: 'Royal Gifter',
    icon: '♛',
    minLevel: 70,
    maxLevel: 84,
  ),
  FvGifterBadgeTier(
    id: 'legendary',
    label: 'Legendary Gifter',
    icon: '✪',
    minLevel: 85,
    maxLevel: 98,
  ),
  FvGifterBadgeTier(
    id: 'fame-icon',
    label: 'Fame Icon',
    icon: '♕',
    minLevel: 99,
    maxLevel: 99,
  ),
];

const fvGifterLevelThresholds = <int>[
  0,
  100,
  250,
  500,
  1000,
  2000,
  3500,
  5000,
  7500,
  10000,
  15000,
  22500,
  32500,
  45000,
  60000,
  72500,
  87500,
  105000,
  125000,
  150000,
  170000,
  190000,
  215000,
  245000,
  275000,
  310000,
  350000,
  395000,
  445000,
  500000,
  540000,
  585000,
  635000,
  690000,
  750000,
  810000,
  880000,
  950000,
  1025000,
  1125000,
  1200000,
  1325000,
  1425000,
  1550000,
  1675000,
  1800000,
  1975000,
  2125000,
  2300000,
  2500000,
  2650000,
  2800000,
  2950000,
  3125000,
  3300000,
  3475000,
  3675000,
  3900000,
  4125000,
  4350000,
  4600000,
  4875000,
  5150000,
  5425000,
  5750000,
  6075000,
  6425000,
  6775000,
  7175000,
  7575000,
  8000000,
  8475000,
  8950000,
  9450000,
  10000000,
  10700000,
  11400000,
  12200000,
  13100000,
  14000000,
  15000000,
  16000000,
  17100000,
  18300000,
  19600000,
  20900000,
  22400000,
  23900000,
  25600000,
  27300000,
  29200000,
  31300000,
  33400000,
  35800000,
  38200000,
  40900000,
  43700000,
  46800000,
  50000000,
];

class FvGifterProgress {
  const FvGifterProgress({
    required this.level,
    required this.currentRequirement,
    required this.nextLevel,
    required this.nextRequirement,
    required this.coinsToNext,
    required this.progress,
    required this.isMaxLevel,
  });

  final int level;
  final int currentRequirement;
  final int? nextLevel;
  final int nextRequirement;
  final int coinsToNext;
  final double progress;
  final bool isMaxLevel;
}

bool fvIsPrivilegedIdentityRole(String? role) {
  final normalized = (role ?? '').trim().toLowerCase();
  return normalized == 'owner' || normalized == 'admin';
}

int fvGifterLevelRequirement(int level) {
  final normalized = level.clamp(1, 99);
  return fvGifterLevelThresholds[normalized - 1];
}

int fvComputeGifterLevel(int totalCoinsSent) {
  final normalizedCoins = totalCoinsSent < 0 ? 0 : totalCoinsSent;
  var low = 0;
  var high = fvGifterLevelThresholds.length - 1;
  var matchedIndex = 0;

  while (low <= high) {
    final middle = (low + high) ~/ 2;
    if (fvGifterLevelThresholds[middle] <= normalizedCoins) {
      matchedIndex = middle;
      low = middle + 1;
    } else {
      high = middle - 1;
    }
  }

  return matchedIndex + 1;
}

FvGifterBadgeTier fvGifterBadgeForLevel(int level) {
  final normalized = level.clamp(1, 99);
  for (final tier in fvGifterBadgeTiers) {
    if (normalized >= tier.minLevel && normalized <= tier.maxLevel) {
      return tier;
    }
  }
  return fvGifterBadgeTiers.first;
}

FvGifterBadgeTier? fvEarnedGifterBadge(int totalCoinsSent) {
  if (totalCoinsSent <= 0) return null;
  return fvGifterBadgeForLevel(fvComputeGifterLevel(totalCoinsSent));
}

FvGifterProgress fvGifterProgress(int totalCoinsSent) {
  final normalizedCoins = totalCoinsSent < 0 ? 0 : totalCoinsSent;
  final level = fvComputeGifterLevel(normalizedCoins);
  final currentRequirement = fvGifterLevelRequirement(level);
  final isMaxLevel = level >= 99;
  if (isMaxLevel) {
    return FvGifterProgress(
      level: level,
      currentRequirement: currentRequirement,
      nextLevel: null,
      nextRequirement: currentRequirement,
      coinsToNext: 0,
      progress: 1,
      isMaxLevel: true,
    );
  }

  final nextLevel = level + 1;
  final nextRequirement = fvGifterLevelRequirement(nextLevel);
  final range = (nextRequirement - currentRequirement).clamp(1, nextRequirement);
  final progress =
      ((normalizedCoins - currentRequirement) / range).clamp(0.0, 1.0);

  return FvGifterProgress(
    level: level,
    currentRequirement: currentRequirement,
    nextLevel: nextLevel,
    nextRequirement: nextRequirement,
    coinsToNext: (nextRequirement - normalizedCoins).clamp(0, nextRequirement),
    progress: progress,
    isMaxLevel: false,
  );
}

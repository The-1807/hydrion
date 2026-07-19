enum BingoTileKind { automatic, hydrationAction, checkIn, free }

class BingoTileDefinition {
  final String id;
  final String title;
  final String instruction;
  final BingoTileKind kind;
  final double? goalFraction;
  final int? logCount;

  const BingoTileDefinition({
    required this.id,
    required this.title,
    required this.instruction,
    required this.kind,
    this.goalFraction,
    this.logCount,
  });
}

class BottleBingoBoard {
  static const centerIndex = 12;
  static const lineIndexes = <List<int>>[
    [0, 1, 2, 3, 4],
    [5, 6, 7, 8, 9],
    [10, 11, 12, 13, 14],
    [15, 16, 17, 18, 19],
    [20, 21, 22, 23, 24],
    [0, 5, 10, 15, 20],
    [1, 6, 11, 16, 21],
    [2, 7, 12, 17, 22],
    [3, 8, 13, 18, 23],
    [4, 9, 14, 19, 24],
    [0, 6, 12, 18, 24],
    [4, 8, 12, 16, 20],
  ];
  static const free = BingoTileDefinition(
    id: 'free-drop',
    title: 'Free Drop',
    instruction: 'A welcoming space in the center of your board.',
    kind: BingoTileKind.free,
  );

  static const pool = <BingoTileDefinition>[
    BingoTileDefinition(
        id: 'goal-25',
        title: 'First Quarter',
        instruction: 'Reach 25% of today’s hydration goal.',
        kind: BingoTileKind.automatic,
        goalFraction: .25),
    BingoTileDefinition(
        id: 'goal-50',
        title: 'Halfway Flow',
        instruction: 'Reach 50% of today’s hydration goal.',
        kind: BingoTileKind.automatic,
        goalFraction: .5),
    BingoTileDefinition(
        id: 'goal-75',
        title: 'Three Quarters',
        instruction: 'Reach 75% of today’s hydration goal.',
        kind: BingoTileKind.automatic,
        goalFraction: .75),
    BingoTileDefinition(
        id: 'goal-100',
        title: 'Goal Day',
        instruction: 'Complete today’s hydration goal.',
        kind: BingoTileKind.automatic,
        goalFraction: 1),
    BingoTileDefinition(
        id: 'logs-2',
        title: 'Two Moments',
        instruction: 'Record water at two separate times today.',
        kind: BingoTileKind.automatic,
        logCount: 2),
    BingoTileDefinition(
        id: 'logs-3',
        title: 'Three Moments',
        instruction: 'Record water at three separate times today.',
        kind: BingoTileKind.automatic,
        logCount: 3),
    BingoTileDefinition(
        id: 'logs-4',
        title: 'Four Moments',
        instruction: 'Record water at four separate times today.',
        kind: BingoTileKind.automatic,
        logCount: 4),
    BingoTileDefinition(
        id: 'before-lunch',
        title: 'Before Lunch',
        instruction: 'Log water before your lunch cutoff.',
        kind: BingoTileKind.automatic),
    BingoTileDefinition(
        id: 'morning-water',
        title: 'Morning Water',
        instruction: 'Log water before noon.',
        kind: BingoTileKind.automatic),
    BingoTileDefinition(
        id: 'afternoon-water',
        title: 'Afternoon Water',
        instruction: 'Log water between noon and 5 PM.',
        kind: BingoTileKind.automatic),
    BingoTileDefinition(
        id: 'planned-sip',
        title: 'Planned Sip',
        instruction: 'Choose and log your configured challenge amount.',
        kind: BingoTileKind.hydrationAction),
    BingoTileDefinition(
        id: 'meal-drink',
        title: 'Meal-Time Drink',
        instruction: 'Log your configured amount with a meal.',
        kind: BingoTileKind.hydrationAction),
    BingoTileDefinition(
        id: 'evening-sip',
        title: 'Evening Sip',
        instruction: 'Log your configured amount this evening if comfortable.',
        kind: BingoTileKind.hydrationAction),
    BingoTileDefinition(
        id: 'refill',
        title: 'Refill Ready',
        instruction: 'Refill your bottle, then check in.',
        kind: BingoTileKind.checkIn),
    BingoTileDefinition(
        id: 'prepare-infusion',
        title: 'Flavor Prep',
        instruction: 'Prepare a no-added-sugar infusion.',
        kind: BingoTileKind.checkIn),
    BingoTileDefinition(
        id: 'food',
        title: 'Water-Rich Food',
        instruction: 'Include a water-rich food with a meal.',
        kind: BingoTileKind.checkIn),
    BingoTileDefinition(
        id: 'review',
        title: 'Progress Pause',
        instruction: 'Review today’s hydration progress.',
        kind: BingoTileKind.checkIn),
    BingoTileDefinition(
        id: 'bottle-visible',
        title: 'Within Reach',
        instruction: 'Place your bottle somewhere easy to reach.',
        kind: BingoTileKind.checkIn),
    BingoTileDefinition(
        id: 'wash-bottle',
        title: 'Fresh Bottle',
        instruction: 'Clean your reusable bottle.',
        kind: BingoTileKind.checkIn),
    BingoTileDefinition(
        id: 'plan-tomorrow',
        title: 'Tomorrow Ready',
        instruction: 'Plan where water will fit tomorrow.',
        kind: BingoTileKind.checkIn),
    BingoTileDefinition(
        id: 'desk-reset',
        title: 'Desk Reset',
        instruction: 'Refresh your water spot.',
        kind: BingoTileKind.checkIn),
    BingoTileDefinition(
        id: 'meal-plan',
        title: 'Meal Plan',
        instruction: 'Choose a meal-time hydration moment.',
        kind: BingoTileKind.checkIn),
    BingoTileDefinition(
        id: 'bottle-check',
        title: 'Bottle Check',
        instruction: 'Check that your bottle is ready for use.',
        kind: BingoTileKind.checkIn),
    BingoTileDefinition(
        id: 'gentle-break',
        title: 'Gentle Break',
        instruction: 'Take a comfortable hydration break.',
        kind: BingoTileKind.checkIn),
  ];

  final List<BingoTileDefinition> tiles;

  const BottleBingoBoard._(this.tiles);

  factory BottleBingoBoard.forInstance(int instanceId) {
    final offset = instanceId.abs() % pool.length;
    final rotated = [...pool.skip(offset), ...pool.take(offset)];
    final tiles = <BingoTileDefinition>[];
    for (var index = 0; index < 25; index++) {
      tiles.add(index == centerIndex
          ? free
          : rotated[index < centerIndex ? index : index - 1]);
    }
    return BottleBingoBoard._(List.unmodifiable(tiles));
  }

  Set<int> completedLines(Set<int> completedIndexes) {
    final complete = {...completedIndexes, centerIndex};
    return {
      for (var i = 0; i < lineIndexes.length; i++)
        if (lineIndexes[i].every(complete.contains)) i
    };
  }
}

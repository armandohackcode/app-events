import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_symbol.dart';

/// Demo seed data for Phase 1 of GDG SPIN (deleted once Firestore is wired).
class GdgSpinDemoData {
  const GdgSpinDemoData._();

  static List<SpinPrize> createPrizes() => const [
    SpinPrize(
      id: 'stickers',
      name: AppStrings.spinPrizeStickers,
      symbol: SpinSymbol.cherries,
      initialStock: 30,
      remainingStock: 30,
      rarity: PrizeRarity.common,
    ),
    SpinPrize(
      id: 'mug',
      name: AppStrings.spinPrizeMug,
      symbol: SpinSymbol.bell,
      initialStock: 5,
      remainingStock: 5,
      rarity: PrizeRarity.rare,
    ),
    SpinPrize(
      id: 'shirt',
      name: AppStrings.spinPrizeShirt,
      symbol: SpinSymbol.bar,
      initialStock: 4,
      remainingStock: 4,
      rarity: PrizeRarity.rare,
    ),
    SpinPrize(
      id: 'sparky',
      name: AppStrings.spinPrizeSparky,
      symbol: SpinSymbol.star,
      initialStock: 2,
      remainingStock: 2,
      rarity: PrizeRarity.epic,
    ),
    SpinPrize(
      id: 'dash',
      name: AppStrings.spinPrizeDash,
      symbol: SpinSymbol.diamond,
      initialStock: 2,
      remainingStock: 2,
      rarity: PrizeRarity.epic,
    ),
    SpinPrize(
      id: 'android',
      name: AppStrings.spinPrizeAndroid,
      symbol: SpinSymbol.seven,
      initialStock: 1,
      remainingStock: 1,
      rarity: PrizeRarity.legendary,
    ),
  ];

  static List<SpinMission> createMissions() => const [
    SpinMission(
      id: 'check_in',
      title: AppStrings.spinMissionCheckIn,
      reward: 1,
      done: true,
    ),
    SpinMission(
      id: 'qr_3',
      title: AppStrings.spinMissionQr,
      reward: 1,
      done: true,
    ),
    SpinMission(
      id: 'ask',
      title: AppStrings.spinMissionAsk,
      reward: 1,
      done: false,
      actionLabel: AppStrings.spinActionAsk,
    ),
    SpinMission(
      id: 'rate',
      title: AppStrings.spinMissionRate,
      reward: 1,
      done: false,
      actionLabel: AppStrings.spinActionRate,
    ),
    SpinMission(
      id: 'trivia',
      title: AppStrings.spinMissionTrivia,
      reward: 1,
      done: false,
      actionLabel: AppStrings.spinActionPlay,
      isTrivia: true,
    ),
  ];
}

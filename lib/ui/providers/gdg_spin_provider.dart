import 'dart:async';
import 'dart:math';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/spin_combo.dart';
import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_player.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:app_events/domain/repositories/spin_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

export 'package:app_events/domain/models/spin_result.dart'
    show SpinBonusOutcome, SpinOutcome, SpinPrizeOutcome;

enum SpinPhase { idle, requesting, spinning, win, bonus, nearMiss }

enum SpinMessage {
  pullHint,
  connecting,
  spinning,
  tease,
  win,
  bonus,
  lose,
  outOfTickets,
  noTickets,
  paused,
  closed,
  soldOut,
  cooldown,
  prizeCapReached,
  networkError,
  noActiveEvent,
  trayHint,
  coinsCollected,
  missionDone,
  triviaRight,
  triviaWrong,
  codeRedeemed,
  codeError,
  requirementNotMet,
  ticketCapReached,
  triviaClosed,
  missionInactive,
}

class CoinDrop {
  final double leftFraction;
  final double bottom;
  final double rotation;
  final int delayMs;
  final bool isNew;

  const CoinDrop({
    required this.leftFraction,
    required this.bottom,
    required this.rotation,
    required this.delayMs,
    required this.isNew,
  });

  CoinDrop copyWith({bool? isNew}) => CoinDrop(
    leftFraction: leftFraction,
    bottom: bottom,
    rotation: rotation,
    delayMs: delayMs,
    isNew: isNew ?? this.isNew,
  );
}

/// Real player-facing state for GDG SPIN with live stream buffering during spins.
class GdgSpinProvider extends ChangeNotifier {
  static const int _maxCoinsInTray = 46;
  static const int _bonusCoins = 8;

  static const List<SpinSymbol> fillSymbols = [
    SpinSymbol.cherries,
    SpinSymbol.cherries,
    SpinSymbol.lemon,
    SpinSymbol.lemon,
    SpinSymbol.bell,
    SpinSymbol.bar,
    SpinSymbol.star,
    SpinSymbol.diamond,
    SpinSymbol.diamond,
    SpinSymbol.wild,
    SpinSymbol.mysteryBox,
    SpinSymbol.seven,
  ];

  final SpinRepository _repository;
  final Random _random;
  final Uuid _uuid;

  String? _eventId;
  String? _uid;
  bool _disposed = false;
  bool _isLoading = false;
  bool _isMissionBusy = false;
  bool _prizesLoaded = false;
  int _attachedViewCount = 0;
  SpinException? _bindError;

  SpinConfig? _config;
  SpinPlayer? _player;
  List<SpinPrize> prizes = const [];
  List<SpinMission> missions = const [];
  List<SpinMission> _rawMissions = const [];
  List<SpinMissionClaim> _missionClaims = const [];
  List<SpinWin> myWins = const [];

  int _tickets = 0;
  int _spins = 0;
  int spinId = 0;

  List<List<SpinSymbol>> visible = [
    [SpinSymbol.lemon, SpinSymbol.seven, SpinSymbol.bell],
    [SpinSymbol.seven, SpinSymbol.cherries, SpinSymbol.bar],
    [SpinSymbol.diamond, SpinSymbol.lemon, SpinSymbol.seven],
  ];

  List<SpinSymbol>? pendingCombo;
  bool teasing = false;
  SpinPhase phase = SpinPhase.idle;
  SpinOutcome? lastOutcome;
  List<CoinDrop> coins = [];
  SpinMessage message = SpinMessage.pullHint;
  String? openTriviaMissionId;
  String? customStatusMessage;

  SpinPullResult? _pendingResult;
  SpinSymbol? _lastWinSymbol;
  String? _pendingRetryRequestId;

  // Stream buffering state while reels are spinning so stock and wins reveal
  // at the exact moment reelsStop().
  bool _deferStreamUpdates = false;
  SpinPlayer? _bufferedPlayer;
  bool _hasBufferedPlayer = false;
  List<SpinPrize>? _bufferedPrizes;
  bool _hasBufferedPrizes = false;
  List<SpinWin>? _bufferedWins;
  bool _hasBufferedWins = false;

  StreamSubscription<SpinConfig?>? _configSub;
  StreamSubscription<List<SpinPrize>>? _prizesSub;
  StreamSubscription<List<SpinMission>>? _missionsSub;
  StreamSubscription<SpinPlayer?>? _playerSub;
  StreamSubscription<List<SpinWin>>? _winsSub;
  StreamSubscription<List<SpinMissionClaim>>? _claimsSub;

  GdgSpinProvider(this._repository, {Random? random, Uuid? uuid})
    : _random = random ?? Random.secure(),
      _uuid = uuid ?? const Uuid();

  SpinConfig? get config => _config;
  SpinPlayer? get player => _player;
  int get tickets => _tickets;
  int get spins => _spins;
  int get ticketCost => _config?.ticketCostPerSpin ?? 1;
  bool get isLoading => _isLoading;
  bool get isMissionBusy => _isMissionBusy;
  bool get isBound => _eventId != null && _uid != null;
  String? get boundEventId => _eventId;
  String? get boundUid => _uid;
  SpinException? get bindError => _bindError;
  bool get isPaused => _config?.status == SpinGameStatus.paused;
  bool get isClosed => _config?.status == SpinGameStatus.closed;

  /// True once the active prize catalog has loaded and every prize in it is
  /// out of stock. The server rejects spins (without charging) and closes
  /// the game in that state, so the lever is blocked right away.
  bool get isSoldOut =>
      _prizesLoaded &&
      prizes.isNotEmpty &&
      !prizes.any((prize) => prize.remainingStock > 0);
  bool get isBlockedByPrizeCap =>
      _config != null &&
      _config!.maxPrizesPerUser > 0 &&
      !_config!.allowPlayAfterCap &&
      (_player?.totalPrizesWon ?? 0) >= _config!.maxPrizesPerUser;
  bool get canPull =>
      isBound &&
      phase == SpinPhase.idle &&
      !isPaused &&
      !isClosed &&
      !isBlockedByPrizeCap &&
      // A pending retry replays a spin the server may already have applied
      // (possibly the last prize), so it stays allowed even when sold out.
      (hasPendingNetworkRetry || (!isSoldOut && _tickets >= ticketCost));
  bool get hasPendingNetworkRetry => _pendingRetryRequestId != null;
  SpinSymbol? get lastWinSymbol => _lastWinSymbol;

  /// Binds all live Firestore streams for `(eventId, uid)` and initializes the
  /// player wallet. Idempotent when already bound without error.
  Future<void> bind({required String eventId, required String uid}) async {
    if (eventId.isEmpty || uid.isEmpty) return;
    if (_eventId == eventId && _uid == uid && _bindError == null) {
      return;
    }

    await _cancelSubscriptions();
    _resetStateForNewBinding(notify: false);
    _eventId = eventId;
    _uid = uid;
    _isLoading = true;
    _bindError = null;
    if (!_disposed) notifyListeners();

    _configSub = _repository
        .watchConfig(eventId)
        .listen(_onConfigUpdate, onError: _onStreamError);
    _prizesSub = _repository
        .watchPrizes(eventId, activeOnly: true)
        .listen(_onPrizesUpdate, onError: _onStreamError);
    _missionsSub = _repository
        .watchMissions(eventId, activeOnly: true)
        .listen(_onMissionsUpdate, onError: _onStreamError);
    _playerSub = _repository
        .watchPlayer(eventId, uid)
        .listen(_onPlayerUpdate, onError: _onStreamError);
    _winsSub = _repository
        .watchMyWins(eventId, uid)
        .listen(_onWinsUpdate, onError: _onStreamError);
    _claimsSub = _repository
        .watchMyMissionClaims(eventId, uid)
        .listen(_onClaimsUpdate, onError: _onStreamError);

    try {
      final initResult = await _repository.initPlayer(eventId);
      if (_disposed || _eventId != eventId || _uid != uid) return;
      _bindError = null;
      if (_player == null && !_hasBufferedPlayer) {
        _applyPlayer(initResult.player);
      }
    } on SpinException catch (e) {
      if (_disposed || _eventId != eventId || _uid != uid) return;
      _bindError = e;
      _mapErrorToMessage(e.reason);
    } catch (e) {
      if (_disposed || _eventId != eventId || _uid != uid) return;
      _bindError = SpinException(
        reason: SpinErrorReason.network,
        code: 'unknown',
        message: e.toString(),
      );
      customStatusMessage = null;
      message = SpinMessage.networkError;
    } finally {
      if (!_disposed && _eventId == eventId && _uid == uid) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Applies a fresh ticket balance returned by an external mission action
  /// (such as talk Q&A) when this provider is bound to [eventId].
  void syncTicketsFromExternalAward({
    required String eventId,
    required int ticketsAfter,
  }) {
    if (_disposed || _eventId != eventId || _deferStreamUpdates) return;
    _tickets = ticketsAfter;
    if (_player != null) {
      _player = _player!.copyWith(tickets: ticketsAfter);
    }
    notifyListeners();
  }

  /// Cancels all stream subscriptions and clears event-scoped state.
  void unbind() {
    unawaited(_cancelSubscriptions());
    _resetStateForNewBinding(notify: true);
  }

  /// Registers an active cabinet screen so unmounted pulls can self-settle.
  void attachView() {
    _attachedViewCount++;
  }

  /// Unregisters an active cabinet screen and settles any in-flight spin.
  void detachView() {
    if (_attachedViewCount > 0) {
      _attachedViewCount--;
    }
    if (_attachedViewCount == 0) {
      settleInterruptedSpin(notify: false);
    }
  }

  /// Emits a post-frame notification after a host screen settles on dispose.
  void notifyViewSettled() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Pulls the lever via `spinPull`, using an idempotent `spinRequestId`.
  Future<void> pull() async {
    if (!canPull) {
      showBlockedPullHint();
      return;
    }
    final eventId = _eventId;
    if (eventId == null) {
      showBlockedPullHint();
      return;
    }

    final isRetry = _pendingRetryRequestId != null;
    final requestId = _pendingRetryRequestId ?? _uuid.v4();
    final startedWithAttachedView = _attachedViewCount > 0;
    phase = SpinPhase.requesting;
    message = SpinMessage.connecting;
    customStatusMessage = null;
    notifyListeners();

    try {
      final result = await _repository.pull(
        eventId: eventId,
        spinRequestId: requestId,
      );
      if (_disposed || _eventId != eventId) return;

      final alreadyAppliedOnStream =
          isRetry && _spins >= result.spinsCountAfter;
      _pendingRetryRequestId = null;

      if (startedWithAttachedView && _attachedViewCount == 0) {
        _applyImmediateResult(result);
        return;
      }

      _deferStreamUpdates = true;
      if (!alreadyAppliedOnStream) {
        _tickets = max(0, _tickets - ticketCost);
      }
      _spins = max(_spins, result.spinsCountAfter);
      _pendingResult = result;
      pendingCombo = List<SpinSymbol>.from(result.combo);
      spinId++;
      teasing = false;
      phase = SpinPhase.spinning;
      message = SpinMessage.spinning;
      notifyListeners();
    } on SpinException catch (e) {
      if (_disposed || _eventId != eventId) return;
      // Keep the same spinRequestId for any failure without a business reason
      // from the server. Offline errors reach Flutter as `internal`/`unknown`
      // on Android and iOS, and replaying the same id is always safe because
      // spinPull is idempotent (the ticket is never charged twice).
      _pendingRetryRequestId =
          e.reason == SpinErrorReason.network ||
              e.reason == SpinErrorReason.unknown
          ? requestId
          : null;
      _mapErrorToMessage(e.reason);
      phase = SpinPhase.idle;
      notifyListeners();
    } catch (_) {
      if (_disposed || _eventId != eventId) return;
      _pendingRetryRequestId = requestId;
      customStatusMessage = null;
      message = SpinMessage.networkError;
      phase = SpinPhase.idle;
      notifyListeners();
    }
  }

  /// Shows a helpful LCD message when a blocked lever is tapped while idle.
  void showBlockedPullHint() {
    if (phase != SpinPhase.idle) return;
    if (!isBound) {
      customStatusMessage = null;
      message = SpinMessage.noActiveEvent;
      notifyListeners();
      return;
    }
    if (isPaused) {
      customStatusMessage = _nonEmpty(_config?.pauseMessage);
      message = SpinMessage.paused;
      notifyListeners();
      return;
    }
    if (isSoldOut) {
      customStatusMessage = null;
      message = SpinMessage.soldOut;
      notifyListeners();
      return;
    }
    if (isClosed) {
      customStatusMessage = null;
      message = SpinMessage.closed;
      notifyListeners();
      return;
    }
    if (isBlockedByPrizeCap) {
      customStatusMessage = null;
      message = SpinMessage.prizeCapReached;
      notifyListeners();
      return;
    }
    if (_tickets < ticketCost) {
      customStatusMessage = null;
      message = SpinMessage.noTickets;
      notifyListeners();
    }
  }

  /// Evaluates near-win suspense once the second reel stops.
  void secondReelStopped({bool reducedMotion = false}) {
    if (phase != SpinPhase.spinning || pendingCombo == null) return;
    if (pendingCombo!.length < 2) return;
    final nextTeasing =
        SpinCombo.canStillWin(pendingCombo![0], pendingCombo![1]) &&
        !reducedMotion;
    if (nextTeasing == teasing) return;
    teasing = nextTeasing;
    if (teasing) {
      message = SpinMessage.tease;
    }
    notifyListeners();
  }

  /// Applies the server outcome once all three reels stop and flushes streams.
  void reelsStopped({List<List<SpinSymbol>>? finalVisible}) {
    final result = _pendingResult;
    final combo = pendingCombo;
    if (phase != SpinPhase.spinning || combo == null || result == null) {
      return;
    }

    _pendingResult = null;
    teasing = false;

    if (finalVisible != null && finalVisible.length == 3) {
      visible = finalVisible;
    } else {
      for (var r = 0; r < 3; r++) {
        if (r < combo.length) {
          visible[r][1] = combo[r];
        }
      }
    }

    switch (result.outcomeType) {
      case SpinOutcomeType.bonus:
        lastOutcome = SpinBonusOutcome(result.bonusTickets);
        _lastWinSymbol = SpinSymbol.mysteryBox;
        _addCoins(_bonusCoins);
        phase = SpinPhase.bonus;
        message = SpinMessage.bonus;
      case SpinOutcomeType.prize when result.wonPrize != null:
        final wonPrize = result.wonPrize!;
        final prizeModel = _resolveWonPrizeModel(wonPrize);
        lastOutcome = SpinPrizeOutcome(prizeModel);
        _lastWinSymbol = wonPrize.symbol;
        _addCoins(_coinsForRarity(wonPrize.rarity));
        phase = SpinPhase.win;
        message = SpinMessage.win;
      case SpinOutcomeType.prize:
      case SpinOutcomeType.lose:
        _lastWinSymbol = null;
        lastOutcome = null;
        final canTease =
            combo.length >= 2 && SpinCombo.canStillWin(combo[0], combo[1]);
        phase = canTease ? SpinPhase.nearMiss : SpinPhase.idle;
        message = result.ticketsAfter <= 0
            ? SpinMessage.outOfTickets
            : SpinMessage.lose;
    }

    _tickets = result.ticketsAfter;
    _spins = result.spinsCountAfter;

    _flushBufferedStreams(result);
    _deferStreamUpdates = false;
    pendingCombo = null;
    notifyListeners();
  }

  /// Settles an interrupted spin or celebration back to `idle` safely so
  /// buffered streams flush and the slot machine never remains stuck.
  void settleInterruptedSpin({bool notify = true}) {
    if (phase == SpinPhase.win ||
        phase == SpinPhase.bonus ||
        phase == SpinPhase.nearMiss) {
      teasing = false;
      phase = SpinPhase.idle;
      if (notify && !_disposed) notifyListeners();
      return;
    }

    if (phase != SpinPhase.spinning) {
      if (_deferStreamUpdates) {
        _flushBufferedStreamsWithoutResult();
        _deferStreamUpdates = false;
        if (notify && !_disposed) notifyListeners();
      }
      return;
    }

    final result = _pendingResult;
    if (result != null) {
      _applyImmediateResult(result, notify: notify);
    } else {
      pendingCombo = null;
      teasing = false;
      _flushBufferedStreamsWithoutResult();
      _deferStreamUpdates = false;
      phase = SpinPhase.idle;
      if (notify && !_disposed) notifyListeners();
    }
  }

  void _applyImmediateResult(SpinPullResult result, {bool notify = true}) {
    final combo = pendingCombo ?? result.combo;
    _pendingResult = null;
    pendingCombo = null;
    teasing = false;

    for (var r = 0; r < 3; r++) {
      if (r < combo.length) {
        visible[r][1] = combo[r];
      }
    }

    switch (result.outcomeType) {
      case SpinOutcomeType.bonus:
        lastOutcome = SpinBonusOutcome(result.bonusTickets);
        _lastWinSymbol = SpinSymbol.mysteryBox;
        _addCoins(_bonusCoins);
        message = SpinMessage.bonus;
      case SpinOutcomeType.prize when result.wonPrize != null:
        final wonPrize = result.wonPrize!;
        final prizeModel = _resolveWonPrizeModel(wonPrize);
        lastOutcome = SpinPrizeOutcome(prizeModel);
        _lastWinSymbol = wonPrize.symbol;
        _addCoins(_coinsForRarity(wonPrize.rarity));
        message = SpinMessage.win;
      case SpinOutcomeType.prize:
      case SpinOutcomeType.lose:
        _lastWinSymbol = null;
        lastOutcome = null;
        message = result.ticketsAfter <= 0
            ? SpinMessage.outOfTickets
            : SpinMessage.lose;
    }

    _tickets = result.ticketsAfter;
    _spins = result.spinsCountAfter;
    _flushBufferedStreams(result);
    _deferStreamUpdates = false;
    phase = SpinPhase.idle;
    if (notify && !_disposed) notifyListeners();
  }

  /// Returns the machine from win/bonus/near-miss celebration back to idle.
  void celebrationDone() {
    if (phase != SpinPhase.win &&
        phase != SpinPhase.bonus &&
        phase != SpinPhase.nearMiss) {
      return;
    }
    phase = SpinPhase.idle;
    notifyListeners();
  }

  /// Opens or closes the inline options panel for a trivia mission.
  void toggleTrivia(String missionId) {
    openTriviaMissionId = openTriviaMissionId == missionId ? null : missionId;
    notifyListeners();
  }

  /// Claims a verified non-trivia mission. Rethrows [SpinException] so the UI
  /// can redirect to profile/events when requirements are not met.
  Future<SpinClaimMissionResult?> claimMission(String missionId) async {
    final eventId = _eventId;
    if (eventId == null) return null;

    _isMissionBusy = true;
    notifyListeners();
    try {
      final result = await _repository.claimMission(
        eventId: eventId,
        missionId: missionId,
      );
      if (!_disposed && _eventId == eventId) {
        if (!_deferStreamUpdates) {
          _tickets = result.ticketsAfter;
          if (_player != null) {
            _player = _player!.copyWith(tickets: result.ticketsAfter);
          }
        }
        customStatusMessage = null;
        message = SpinMessage.missionDone;
      }
      return result;
    } on SpinException catch (e) {
      if (!_disposed && _eventId == eventId) {
        _mapErrorToMessage(e.reason);
      }
      rethrow;
    } finally {
      _isMissionBusy = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Submits an answer for a live trivia mission.
  Future<SpinSubmitTriviaResult?> submitTrivia(
    String missionId,
    int selectedIndex,
  ) async {
    final eventId = _eventId;
    if (eventId == null) return null;

    _isMissionBusy = true;
    notifyListeners();
    try {
      final result = await _repository.submitTrivia(
        eventId: eventId,
        missionId: missionId,
        selectedIndex: selectedIndex,
      );
      if (!_disposed && _eventId == eventId) {
        openTriviaMissionId = null;
        if (!_deferStreamUpdates) {
          _tickets = result.ticketsAfter;
          if (_player != null) {
            _player = _player!.copyWith(tickets: result.ticketsAfter);
          }
        }
        customStatusMessage = _nonEmpty(result.explanation);
        message = result.correct
            ? SpinMessage.triviaRight
            : SpinMessage.triviaWrong;
      }
      return result;
    } on SpinException catch (e) {
      if (!_disposed && _eventId == eventId) {
        if (e.reason == SpinErrorReason.triviaClosed ||
            e.reason == SpinErrorReason.alreadyExists) {
          openTriviaMissionId = null;
        }
        _mapErrorToMessage(e.reason);
      }
      rethrow;
    } finally {
      _isMissionBusy = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Redeems a sponsor/stand code or QR payload for extra tickets.
  Future<SpinRedeemTicketCodeResult?> redeemTicketCode(String code) async {
    final eventId = _eventId;
    if (eventId == null) return null;

    _isMissionBusy = true;
    notifyListeners();
    try {
      final result = await _repository.redeemTicketCode(
        eventId: eventId,
        code: code,
      );
      if (!_disposed && _eventId == eventId) {
        if (!_deferStreamUpdates) {
          _tickets = result.ticketsAfter;
          if (_player != null) {
            _player = _player!.copyWith(tickets: result.ticketsAfter);
          }
        }
        customStatusMessage = AppStrings.spinCodeRedeemed(
          result.label,
          result.ticketsAwarded,
        );
        message = SpinMessage.codeRedeemed;
      }
      return result;
    } on SpinException catch (e) {
      if (!_disposed && _eventId == eventId) {
        _mapCodeErrorToMessage(e.reason);
      }
      rethrow;
    } finally {
      _isMissionBusy = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Collects all coins in the tray or shows a hint when already empty.
  void collectCoins() {
    customStatusMessage = null;
    if (coins.isEmpty) {
      message = SpinMessage.trayHint;
      notifyListeners();
      return;
    }
    coins = [];
    message = SpinMessage.coinsCollected;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_cancelSubscriptions());
    super.dispose();
  }

  void _onConfigUpdate(SpinConfig? nextConfig) {
    if (_disposed) return;
    _config = nextConfig;
    if (phase == SpinPhase.idle &&
        (message == SpinMessage.pullHint ||
            message == SpinMessage.paused ||
            message == SpinMessage.closed)) {
      if (nextConfig?.status == SpinGameStatus.paused) {
        customStatusMessage = _nonEmpty(nextConfig?.pauseMessage);
        message = SpinMessage.paused;
      } else if (nextConfig?.status == SpinGameStatus.closed) {
        customStatusMessage = null;
        message = SpinMessage.closed;
      } else if (nextConfig?.status == SpinGameStatus.active) {
        customStatusMessage = null;
        message = SpinMessage.pullHint;
      }
    }
    notifyListeners();
  }

  void _onPrizesUpdate(List<SpinPrize> nextPrizes) {
    if (_disposed) return;
    _prizesLoaded = true;
    if (_deferStreamUpdates) {
      _bufferedPrizes = nextPrizes;
      _hasBufferedPrizes = true;
      return;
    }
    prizes = nextPrizes;
    notifyListeners();
  }

  void _onMissionsUpdate(List<SpinMission> nextMissions) {
    if (_disposed) return;
    _rawMissions = nextMissions;
    _rebuildMissions();
    notifyListeners();
  }

  void _onClaimsUpdate(List<SpinMissionClaim> nextClaims) {
    if (_disposed) return;
    _missionClaims = nextClaims;
    _rebuildMissions();
    notifyListeners();
  }

  void _onPlayerUpdate(SpinPlayer? nextPlayer) {
    if (_disposed) return;
    if (_deferStreamUpdates) {
      _bufferedPlayer = nextPlayer;
      _hasBufferedPlayer = true;
      return;
    }
    _applyPlayer(nextPlayer);
    notifyListeners();
  }

  void _onWinsUpdate(List<SpinWin> nextWins) {
    if (_disposed) return;
    if (_deferStreamUpdates) {
      _bufferedWins = nextWins;
      _hasBufferedWins = true;
      return;
    }
    myWins = nextWins;
    notifyListeners();
  }

  void _onStreamError(Object error) {
    if (_disposed) return;
    if (error is SpinException) {
      _mapErrorToMessage(error.reason);
    } else {
      customStatusMessage = null;
      message = SpinMessage.networkError;
    }
    notifyListeners();
  }

  void _applyPlayer(SpinPlayer? nextPlayer) {
    _player = nextPlayer;
    if (nextPlayer != null) {
      _tickets = nextPlayer.tickets;
      _spins = nextPlayer.spinsCount;
    } else {
      _tickets = 0;
      _spins = 0;
    }
  }

  void _flushBufferedStreamsWithoutResult() {
    if (_hasBufferedPrizes) {
      prizes = _bufferedPrizes ?? const [];
      _bufferedPrizes = null;
      _hasBufferedPrizes = false;
    }

    if (_hasBufferedPlayer) {
      final buffered = _bufferedPlayer;
      _bufferedPlayer = null;
      _hasBufferedPlayer = false;
      if (buffered != null) {
        _applyPlayer(buffered);
      } else {
        _player = null;
      }
    }

    if (_hasBufferedWins) {
      myWins = List<SpinWin>.from(_bufferedWins ?? const []);
      _bufferedWins = null;
      _hasBufferedWins = false;
    }
  }

  void _flushBufferedStreams(SpinPullResult result) {
    final hadBufferedPlayer = _hasBufferedPlayer;
    _flushBufferedStreamsWithoutResult();

    if (!hadBufferedPlayer && _player != null) {
      final wonIncrement =
          result.outcomeType == SpinOutcomeType.prize && result.wonPrize != null
          ? 1
          : 0;
      _player = _player!.copyWith(
        tickets: result.ticketsAfter,
        spinsCount: result.spinsCountAfter,
        totalPrizesWon: _player!.totalPrizesWon + wonIncrement,
      );
    }

    // Ensure a newly won prize is visible immediately even if the Firestore
    // snapshot for `spinWins` has not arrived yet.
    if (result.outcomeType == SpinOutcomeType.prize &&
        result.wonPrize != null) {
      final won = result.wonPrize!;
      final alreadyListed = myWins.any((w) => w.id == won.winId);
      if (!alreadyListed) {
        myWins = [
          SpinWin(
            id: won.winId,
            eventId: _eventId ?? '',
            uid: _uid ?? '',
            prizeId: won.prizeId,
            prizeName: won.name,
            prizeSymbol: won.symbol,
            prizeImageUrl: won.imageUrl,
            prizeRarity: won.rarity,
            code: won.code,
            status: SpinWinStatus.pending,
            spinRequestId: result.spinRequestId,
            wonAt: won.wonAt,
          ),
          ...myWins,
        ];
      }
    }
  }

  void _rebuildMissions() {
    final claimById = <String, SpinMissionClaim>{
      for (final claim in _missionClaims) claim.missionId: claim,
    };
    missions = _rawMissions
        .map((mission) {
          final claim = claimById[mission.id];
          final completions = claim?.completions ?? mission.completions;
          final maxComp = max(1, mission.maxCompletionsPerUser);
          return mission.copyWith(
            completions: completions,
            done: completions >= maxComp,
          );
        })
        .toList(growable: false);
  }

  SpinPrize _resolveWonPrizeModel(SpinPullWonPrize wonPrize) {
    for (final p in prizes) {
      if (p.id == wonPrize.prizeId) {
        return _nonEmpty(wonPrize.imageUrl) != null
            ? p.copyWith(imageUrl: wonPrize.imageUrl)
            : p;
      }
    }
    return SpinPrize(
      id: wonPrize.prizeId,
      name: wonPrize.name,
      symbol: wonPrize.symbol,
      imageUrl: wonPrize.imageUrl,
      initialStock: 1,
      remainingStock: 0,
      rarity: wonPrize.rarity,
    );
  }

  void _mapErrorToMessage(SpinErrorReason reason) {
    customStatusMessage = null;
    switch (reason) {
      case SpinErrorReason.gamePaused:
        customStatusMessage = _nonEmpty(_config?.pauseMessage);
        message = SpinMessage.paused;
      case SpinErrorReason.gameClosed:
        message = SpinMessage.closed;
      case SpinErrorReason.cooldownActive:
        message = SpinMessage.cooldown;
      case SpinErrorReason.prizeCapReached:
        message = SpinMessage.prizeCapReached;
      case SpinErrorReason.insufficientTickets:
        message = SpinMessage.noTickets;
      case SpinErrorReason.configNotFound:
        message = SpinMessage.noActiveEvent;
      case SpinErrorReason.requirementNotMet:
        message = SpinMessage.requirementNotMet;
      case SpinErrorReason.ticketCapReached:
        message = SpinMessage.ticketCapReached;
      case SpinErrorReason.triviaClosed:
        message = SpinMessage.triviaClosed;
      case SpinErrorReason.missionInactive:
      case SpinErrorReason.alreadyExists:
        message = SpinMessage.missionInactive;
      case SpinErrorReason.codeDepleted:
      case SpinErrorReason.codeExpired:
      case SpinErrorReason.codeAlreadyExists:
      case SpinErrorReason.invalidCodeFormat:
      case SpinErrorReason.notFound:
        message = SpinMessage.codeError;
      case SpinErrorReason.network:
      case SpinErrorReason.unauthenticated:
      case SpinErrorReason.permissionDenied:
      case SpinErrorReason.playerNotInitialized:
      case SpinErrorReason.rateLimited:
      case SpinErrorReason.questionLimitReached:
      case SpinErrorReason.alreadyRedeemed:
      case SpinErrorReason.alreadyRevoked:
      case SpinErrorReason.invalidStockAdjustment:
      case SpinErrorReason.stockImmutableOnUpdate:
      case SpinErrorReason.manualGrantCapReached:
      case SpinErrorReason.eventMismatch:
      case SpinErrorReason.invalidSecret:
      case SpinErrorReason.unknown:
        message = SpinMessage.networkError;
    }
  }

  void _mapCodeErrorToMessage(SpinErrorReason reason) {
    customStatusMessage = null;
    switch (reason) {
      case SpinErrorReason.ticketCapReached:
        message = SpinMessage.ticketCapReached;
      case SpinErrorReason.network:
        message = SpinMessage.networkError;
      default:
        message = SpinMessage.codeError;
    }
  }

  void _addCoins(int count) {
    final aged = coins.map((c) => c.copyWith(isNew: false)).toList();
    final added = List<CoinDrop>.generate(
      count,
      (index) => CoinDrop(
        leftFraction: 0.08 + _random.nextDouble() * 0.84,
        bottom: 2 + _random.nextDouble() * 16,
        rotation: _random.nextDouble() * 50 - 25,
        delayMs: index * 45,
        isNew: true,
      ),
    );
    final combined = [...aged, ...added];
    if (combined.length > _maxCoinsInTray) {
      coins = combined.sublist(combined.length - _maxCoinsInTray);
    } else {
      coins = combined;
    }
  }

  int _coinsForRarity(PrizeRarity rarity) => switch (rarity) {
    PrizeRarity.common => 6,
    PrizeRarity.rare => 10,
    PrizeRarity.epic => 16,
    PrizeRarity.legendary => 26,
  };

  Future<void> _cancelSubscriptions() async {
    await Future.wait([
      ?_configSub?.cancel(),
      ?_prizesSub?.cancel(),
      ?_missionsSub?.cancel(),
      ?_playerSub?.cancel(),
      ?_winsSub?.cancel(),
      ?_claimsSub?.cancel(),
    ]);
    _configSub = null;
    _prizesSub = null;
    _missionsSub = null;
    _playerSub = null;
    _winsSub = null;
    _claimsSub = null;
  }

  void _resetStateForNewBinding({required bool notify}) {
    _eventId = null;
    _uid = null;
    _isLoading = false;
    _isMissionBusy = false;
    _prizesLoaded = false;
    _bindError = null;
    _config = null;
    _player = null;
    prizes = const [];
    missions = const [];
    _rawMissions = const [];
    _missionClaims = const [];
    myWins = const [];
    _tickets = 0;
    _spins = 0;
    pendingCombo = null;
    teasing = false;
    phase = SpinPhase.idle;
    lastOutcome = null;
    coins = [];
    message = SpinMessage.pullHint;
    openTriviaMissionId = null;
    customStatusMessage = null;
    _pendingResult = null;
    _lastWinSymbol = null;
    _pendingRetryRequestId = null;
    _deferStreamUpdates = false;
    _bufferedPlayer = null;
    _hasBufferedPlayer = false;
    _bufferedPrizes = null;
    _hasBufferedPrizes = false;
    _bufferedWins = null;
    _hasBufferedWins = false;
    if (notify && !_disposed) notifyListeners();
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

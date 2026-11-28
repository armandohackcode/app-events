import 'dart:async';

import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_dashboard.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_ticket_code.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:app_events/domain/repositories/spin_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Admin-panel state and mutations for managing GDG SPIN in live events.
class SpinAdminProvider extends ChangeNotifier {
  final SpinRepository _repository;
  final Uuid _uuid;

  String? _eventId;
  bool _disposed = false;
  bool _isLoadingDashboard = false;
  bool _isSubmitting = false;
  bool _adminStreamsFailed = false;

  SpinDashboardStats? _dashboard;
  SpinConfig? _config;
  List<SpinPrize> _prizes = const [];
  List<SpinMission> _missions = const [];
  List<SpinWin> _wins = const [];
  List<SpinTicketCode> _ticketCodes = const [];
  SpinWinStatus? _winFilter;
  AdminLookupWinResult? _lookupResult;
  SpinException? _lastError;

  StreamSubscription<SpinConfig?>? _configSub;
  StreamSubscription<List<SpinPrize>>? _prizesSub;
  StreamSubscription<List<SpinMission>>? _missionsSub;
  StreamSubscription<List<SpinWin>>? _winsSub;
  StreamSubscription<List<SpinTicketCode>>? _ticketCodesSub;

  SpinAdminProvider(this._repository, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  String? get boundEventId => _eventId;
  bool get isBound => _eventId != null;
  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isSubmitting => _isSubmitting;
  SpinDashboardStats? get dashboard => _dashboard;
  SpinConfig? get config => _config ?? _dashboard?.config;
  List<SpinPrize> get prizes => _prizes;
  List<SpinMission> get missions => _missions;
  List<SpinWin> get wins => _wins;
  List<SpinTicketCode> get ticketCodes => _ticketCodes;
  SpinWinStatus? get winFilter => _winFilter;
  AdminLookupWinResult? get lookupResult => _lookupResult;
  SpinException? get lastError => _lastError;

  /// Binds admin streams to [eventId] and loads dashboard KPIs.
  /// Idempotent when already bound to the same [eventId].
  Future<void> bind(String eventId) async {
    if (eventId.isEmpty) return;
    if (_eventId == eventId) return;

    await _cancelSubscriptions();
    _resetState(notify: false);
    _eventId = eventId;
    if (!_disposed) notifyListeners();

    _configSub = _repository
        .watchConfig(eventId)
        .listen(_onConfigUpdate, onError: _onStreamError);
    _prizesSub = _repository
        .watchPrizes(eventId, activeOnly: false)
        .listen(_onPrizesUpdate, onError: _onStreamError);
    _missionsSub = _repository
        .watchMissions(eventId, activeOnly: false)
        .listen(_onMissionsUpdate, onError: _onStreamError);

    // The dashboard callable runs first: the server verifies the admin and
    // normalizes users-admin/{uid}, which firestore.rules needs before the
    // admin-only streams below can be read.
    try {
      await refreshDashboard();
    } catch (_) {
      // lastError is captured by refreshDashboard() so UI can render a retry banner.
    }
    if (_disposed || _eventId != eventId) return;
    _subscribeAdminOnlyStreams(eventId);
  }

  /// Cancels active admin streams and clears event-scoped state.
  void unbind() {
    unawaited(_cancelSubscriptions());
    _resetState(notify: true);
  }

  /// Updates the win-list status filter and re-subscribes `watchAllWins`.
  void setWinFilter(SpinWinStatus? status) {
    if (_winFilter == status) return;
    _winFilter = status;
    final eventId = _eventId;
    if (eventId != null) {
      unawaited(_winsSub?.cancel());
      _winsSub = _repository
          .watchAllWins(eventId, status: _winFilter)
          .listen(_onWinsUpdate, onError: _onAdminStreamError);
    }
    if (!_disposed) notifyListeners();
  }

  void _subscribeAdminOnlyStreams(String eventId) {
    _adminStreamsFailed = false;
    unawaited(_winsSub?.cancel());
    unawaited(_ticketCodesSub?.cancel());
    _winsSub = _repository
        .watchAllWins(eventId, status: _winFilter)
        .listen(_onWinsUpdate, onError: _onAdminStreamError);
    _ticketCodesSub = _repository
        .watchTicketCodes(eventId)
        .listen(_onTicketCodesUpdate, onError: _onAdminStreamError);
  }

  /// Loads aggregated dashboard metrics, prizes, and config.
  Future<void> refreshDashboard() async {
    final eventId = _requireEventId();
    _isLoadingDashboard = true;
    _lastError = null;
    if (!_disposed) notifyListeners();

    try {
      final stats = await _repository.getDashboard(eventId);
      if (_disposed || _eventId != eventId) return;
      _dashboard = stats;
      _config ??= stats.config;
      if (_prizes.isEmpty && stats.prizes.isNotEmpty) {
        _prizes = stats.prizes;
      }
      _lastError = null;
      if (_adminStreamsFailed) {
        // Retry admin-only streams that were denied before the server
        // normalized this admin's users-admin/{uid} document.
        _subscribeAdminOnlyStreams(eventId);
      }
    } catch (e) {
      if (_disposed || _eventId != eventId) return;
      _lastError = _toSpinException(e);
      rethrow;
    } finally {
      if (!_disposed && _eventId == eventId) {
        _isLoadingDashboard = false;
        notifyListeners();
      }
    }
  }

  Future<SpinConfig> updateConfig(Map<String, dynamic> patch) {
    return _runSubmit((eventId) async {
      final updated = await _repository.updateConfig(
        eventId: eventId,
        patch: patch,
      );
      if (_disposed || _eventId != eventId) return updated;
      _config = updated;
      await _refreshDashboardAfterMutation(eventId);
      return updated;
    });
  }

  Future<SpinConfig> setGameStatus(
    SpinGameStatus status, {
    String? pauseMessage,
  }) {
    return updateConfig({
      'status': status.value,
      'pauseMessage': ?pauseMessage,
    });
  }

  Future<SpinConfig> setRushMode(bool enabled) {
    return updateConfig({'rushMode': enabled});
  }

  Future<AdminUpsertPrizeResult> upsertPrize(
    Map<String, dynamic> prizeData, {
    String? imagePath,
  }) {
    return _runSubmit((eventId) async {
      final result = await _repository.upsertPrize(
        eventId: eventId,
        prizeData: prizeData,
        imagePath: imagePath,
      );
      if (_disposed || _eventId != eventId) return result;
      _upsertLocalPrize(result.prize);
      await _refreshDashboardAfterMutation(eventId);
      return result;
    });
  }

  Future<SpinPrize> adjustPrizeStock({
    required String prizeId,
    required int delta,
    int? releasedDelta,
    required String reason,
  }) {
    return _runSubmit((eventId) async {
      final updated = await _repository.adjustPrizeStock(
        eventId: eventId,
        prizeId: prizeId,
        delta: delta,
        releasedDelta: releasedDelta,
        reason: reason,
      );
      if (_disposed || _eventId != eventId) return updated;
      _upsertLocalPrize(updated);
      await _refreshDashboardAfterMutation(eventId);
      return updated;
    });
  }

  Future<AdminUpsertMissionResult> upsertMission(
    Map<String, dynamic> missionData, {
    int? correctOptionIndex,
    String? explanation,
  }) {
    return _runSubmit((eventId) async {
      final result = await _repository.upsertMission(
        eventId: eventId,
        missionData: missionData,
        correctOptionIndex: correctOptionIndex,
        explanation: explanation,
      );
      if (_disposed || _eventId != eventId) return result;
      _upsertLocalMission(result.mission);
      await _refreshDashboardAfterMutation(eventId);
      return result;
    });
  }

  Future<AdminUpsertMissionResult> toggleMissionActive(
    SpinMission mission,
    bool active,
  ) {
    return upsertMission(<String, dynamic>{'id': mission.id, 'active': active});
  }

  Future<AdminUpsertTicketCodeResult> upsertTicketCode(
    Map<String, dynamic> codeData,
  ) {
    return _runSubmit((eventId) async {
      final result = await _repository.upsertTicketCode(
        eventId: eventId,
        codeData: codeData,
      );
      if (_disposed || _eventId != eventId) return result;
      _upsertLocalTicketCode(result.ticketCode);
      await _refreshDashboardAfterMutation(eventId);
      return result;
    });
  }

  Future<AdminGrantTicketsResult> grantTickets({
    required String targetUid,
    required int amount,
    required String reason,
  }) {
    return _runSubmit((eventId) async {
      final result = await _repository.grantTickets(
        eventId: eventId,
        targetUid: targetUid,
        amount: amount,
        reason: reason,
        requestId: _uuid.v4(),
      );
      if (_disposed || _eventId != eventId) return result;
      await _refreshDashboardAfterMutation(eventId);
      return result;
    });
  }

  Future<AdminImportRegistrationsResult> importRegistrations(
    List<SpinRegistrationRow> rows, {
    bool replaceAll = false,
  }) {
    return _runSubmit((eventId) async {
      final result = await _repository.importRegistrations(
        eventId: eventId,
        rows: rows,
        replaceAll: replaceAll,
      );
      if (_disposed || _eventId != eventId) return result;
      await _refreshDashboardAfterMutation(eventId);
      return result;
    });
  }

  Future<AdminLookupWinResult> lookupWinByCode(String codeOrQr) {
    return _runSubmit((eventId) async {
      final result = await _repository.lookupWinByCode(
        eventId: eventId,
        codeOrQr: codeOrQr,
      );
      if (_disposed || _eventId != eventId) return result;
      _lookupResult = result;
      return result;
    });
  }

  void selectWinForReview(SpinWin win) {
    SpinPrize? matchedPrize;
    for (final prize in _prizes) {
      if (prize.id == win.prizeId) {
        matchedPrize = prize;
        break;
      }
    }
    final existingPlayer = _lookupResult?.win.id == win.id
        ? _lookupResult?.player
        : null;
    _lookupResult = AdminLookupWinResult(
      win: win,
      prize: matchedPrize,
      player: existingPlayer,
    );
    if (!_disposed) notifyListeners();
  }

  void clearLookup() {
    if (_lookupResult == null) return;
    _lookupResult = null;
    if (!_disposed) notifyListeners();
  }

  Future<SpinWin> redeemWin(String winId) {
    return _runSubmit((eventId) async {
      final updated = await _repository.redeemWin(
        eventId: eventId,
        winId: winId,
      );
      if (_disposed || _eventId != eventId) return updated;
      _applyUpdatedWin(updated);
      await _refreshDashboardAfterMutation(eventId);
      return updated;
    });
  }

  Future<SpinWin> revokeWin({
    required String winId,
    required bool returnToStock,
    required String reason,
  }) {
    return _runSubmit((eventId) async {
      final updated = await _repository.revokeWin(
        eventId: eventId,
        winId: winId,
        returnToStock: returnToStock,
        reason: reason,
      );
      if (_disposed || _eventId != eventId) return updated;
      _applyUpdatedWin(updated);
      await _refreshDashboardAfterMutation(eventId);
      return updated;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_cancelSubscriptions());
    super.dispose();
  }

  Future<T> _runSubmit<T>(Future<T> Function(String eventId) action) async {
    final eventId = _requireEventId();
    _isSubmitting = true;
    _lastError = null;
    if (!_disposed) notifyListeners();

    try {
      return await action(eventId);
    } catch (e) {
      if (!_disposed) {
        _lastError = _toSpinException(e);
      }
      rethrow;
    } finally {
      _isSubmitting = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _refreshDashboardAfterMutation(String eventId) async {
    try {
      final stats = await _repository.getDashboard(eventId);
      if (_disposed || _eventId != eventId) return;
      _dashboard = stats;
      _config ??= stats.config;
    } catch (_) {
      // Do not fail a completed mutation if dashboard KPI refresh fails transiently.
    }
  }

  String _requireEventId() {
    final eventId = _eventId;
    if (eventId == null || eventId.isEmpty) {
      throw const SpinException(
        reason: SpinErrorReason.configNotFound,
        code: 'unbound',
        message: 'SpinAdminProvider is not bound to an event.',
      );
    }
    return eventId;
  }

  SpinException _toSpinException(Object error) {
    if (error is SpinException) return error;
    return SpinException(
      reason: SpinErrorReason.network,
      code: 'unknown',
      message: error.toString(),
    );
  }

  void _onConfigUpdate(SpinConfig? nextConfig) {
    if (_disposed) return;
    _config = nextConfig;
    notifyListeners();
  }

  void _onPrizesUpdate(List<SpinPrize> nextPrizes) {
    if (_disposed) return;
    _prizes = nextPrizes;
    notifyListeners();
  }

  void _onMissionsUpdate(List<SpinMission> nextMissions) {
    if (_disposed) return;
    _missions = nextMissions;
    notifyListeners();
  }

  void _onWinsUpdate(List<SpinWin> nextWins) {
    if (_disposed) return;
    _wins = nextWins;
    final currentLookup = _lookupResult;
    if (currentLookup != null) {
      for (final win in nextWins) {
        if (win.id == currentLookup.win.id) {
          _lookupResult = AdminLookupWinResult(
            win: win,
            prize: currentLookup.prize,
            player: currentLookup.player,
          );
          break;
        }
      }
    }
    notifyListeners();
  }

  void _onTicketCodesUpdate(List<SpinTicketCode> nextCodes) {
    if (_disposed) return;
    _ticketCodes = nextCodes;
    notifyListeners();
  }

  void _onStreamError(Object error) {
    if (_disposed) return;
    _lastError = _toSpinException(error);
    notifyListeners();
  }

  void _onAdminStreamError(Object error) {
    _adminStreamsFailed = true;
    _onStreamError(error);
  }

  void _upsertLocalPrize(SpinPrize prize) {
    final updated = List<SpinPrize>.from(_prizes);
    final idx = updated.indexWhere((p) => p.id == prize.id);
    if (idx >= 0) {
      updated[idx] = prize;
    } else {
      updated.add(prize);
    }
    updated.sort((a, b) => a.order.compareTo(b.order));
    _prizes = updated;
  }

  void _upsertLocalMission(SpinMission mission) {
    final updated = List<SpinMission>.from(_missions);
    final idx = updated.indexWhere((m) => m.id == mission.id);
    if (idx >= 0) {
      updated[idx] = mission;
    } else {
      updated.add(mission);
    }
    updated.sort((a, b) => a.order.compareTo(b.order));
    _missions = updated;
  }

  void _upsertLocalTicketCode(SpinTicketCode code) {
    final updated = List<SpinTicketCode>.from(_ticketCodes);
    final idx = updated.indexWhere((c) => c.id == code.id);
    if (idx >= 0) {
      updated[idx] = code;
    } else {
      updated.insert(0, code);
    }
    _ticketCodes = updated;
  }

  void _applyUpdatedWin(SpinWin updatedWin) {
    if (_lookupResult?.win.id == updatedWin.id) {
      _lookupResult = AdminLookupWinResult(
        win: updatedWin,
        prize: _lookupResult?.prize,
        player: _lookupResult?.player,
      );
    }
    final idx = _wins.indexWhere((w) => w.id == updatedWin.id);
    if (idx >= 0) {
      final copy = List<SpinWin>.from(_wins);
      if (_winFilter != null && updatedWin.status != _winFilter) {
        copy.removeAt(idx);
      } else {
        copy[idx] = updatedWin;
      }
      _wins = copy;
    }
  }

  Future<void> _cancelSubscriptions() async {
    await Future.wait([
      ?_configSub?.cancel(),
      ?_prizesSub?.cancel(),
      ?_missionsSub?.cancel(),
      ?_winsSub?.cancel(),
      ?_ticketCodesSub?.cancel(),
    ]);
    _configSub = null;
    _prizesSub = null;
    _missionsSub = null;
    _winsSub = null;
    _ticketCodesSub = null;
  }

  void _resetState({required bool notify}) {
    _eventId = null;
    _isLoadingDashboard = false;
    _isSubmitting = false;
    _dashboard = null;
    _config = null;
    _prizes = const [];
    _missions = const [];
    _wins = const [];
    _ticketCodes = const [];
    _winFilter = null;
    _lookupResult = null;
    _lastError = null;
    _adminStreamsFailed = false;
    if (notify && !_disposed) notifyListeners();
  }
}

import 'dart:async';

import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/domain/repositories/schedule_repository.dart';
import 'package:flutter/foundation.dart';

class ScheduleProvider with ChangeNotifier {
  final ScheduleRepository _repository;
  ScheduleProvider(this._repository);

  Speaker? _currentSpeaker;
  List<Speaker> _schedule = [];
  bool _loadingSchedule = false;
  bool _loadingNewSchedule = false;

  StreamSubscription<List<Speaker>>? _scheduleSubscription;
  String? _watchedEventId;

  bool get loadingSchedule => _loadingSchedule;
  set loadingSchedule(bool state) {
    _loadingSchedule = state;
    notifyListeners();
  }

  Speaker? get currentSpeaker => _currentSpeaker;
  set currentSpeaker(Speaker? data) {
    _currentSpeaker = data;
    notifyListeners();
  }

  List<Speaker> get schedule => _schedule;
  set schedule(List<Speaker> list) {
    _schedule = list;
    notifyListeners();
  }

  bool get loadingNewSchedule => _loadingNewSchedule;
  set loadingNewSchedule(bool state) {
    _loadingNewSchedule = state;
    notifyListeners();
  }

  Future<void> loadSchedule(String eventId) async {
    try {
      loadingSchedule = true;
      schedule = await _repository.getListSchedule(eventId);
      loadingSchedule = false;
    } catch (e) {
      loadingSchedule = false;
      rethrow;
    }
  }

  /// Keeps [schedule] updated with the changes of the event's schedule, until
  /// [stopWatchingSchedule] is called or another event is watched.
  void watchSchedule(String eventId) {
    _scheduleSubscription?.cancel();
    // Never show the schedule of the previously watched event.
    if (_watchedEventId != eventId) _schedule = [];
    _watchedEventId = eventId;
    loadingSchedule = true;
    _scheduleSubscription = _repository
        .getListScheduleStream(eventId)
        .listen(
          (list) {
            _schedule = list;
            loadingSchedule = false;
          },
          onError: (Object error) {
            if (kDebugMode) debugPrint('watchSchedule failed: $error');
            loadingSchedule = false;
          },
        );
  }

  /// Stops listening to the schedule of [eventId]. It does nothing if another
  /// event is being watched by then.
  void stopWatchingSchedule(String eventId) {
    if (_watchedEventId != eventId) return;
    _scheduleSubscription?.cancel();
    _scheduleSubscription = null;
  }

  @override
  void dispose() {
    _scheduleSubscription?.cancel();
    super.dispose();
  }

  Stream<Speaker?> speakerStream(String eventId, String speakerUuid) =>
      _repository.speakerStream(eventId, speakerUuid);

  Future<void> addNewSchedule(
    String eventId,
    Speaker speaker, {
    String? imagePath,
  }) async {
    try {
      loadingNewSchedule = true;
      await _repository.addNewSchedule(eventId, speaker, imagePath: imagePath);
      loadingNewSchedule = false;
    } catch (e) {
      loadingNewSchedule = false;
      rethrow;
    }
  }

  Future<void> updateSchedule(
    String eventId,
    Speaker speaker, {
    String? imagePath,
  }) async {
    try {
      loadingNewSchedule = true;
      await _repository.updateSchedule(eventId, speaker, imagePath: imagePath);
      await loadSchedule(eventId);
      loadingNewSchedule = false;
    } catch (e) {
      loadingNewSchedule = false;
      rethrow;
    }
  }

  Future<void> deleteSchedule(String eventId, String speakerUuid) async {
    try {
      await _repository.deleteSchedule(eventId, speakerUuid);
      schedule = schedule.where((s) => s.uuid != speakerUuid).toList();
    } catch (e) {
      rethrow;
    }
  }
}

import 'dart:async';

import 'package:app_events/domain/models/event.dart';
import 'package:app_events/domain/models/live_activity.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/domain/repositories/event_repository.dart';
import 'package:app_events/domain/repositories/schedule_repository.dart';
import 'package:flutter/foundation.dart';

/// Follows, in real time, the activity marked as live in any event that is not
/// finished. The active events go first, so the home screen shows the same
/// activity the schedule of its event marks as live, even if nobody has
/// activated that event yet.
class LiveActivityProvider with ChangeNotifier {
  final EventRepository _eventRepository;
  final ScheduleRepository _scheduleRepository;
  LiveActivityProvider(this._eventRepository, this._scheduleRepository);

  StreamSubscription<List<Event>>? _eventsSubscription;
  final Map<String, StreamSubscription<List<Speaker>>> _schedules = {};

  /// Events that may have a live activity, the most relevant first.
  List<String> _candidates = [];

  /// Live activity of each event whose schedule has already answered.
  final Map<String, Speaker?> _answers = {};

  String? _eventId;
  Speaker? _activity;
  bool _loading = false;

  /// The live activity, or null when there is none.
  Speaker? get activity => _activity;

  /// Event that [activity] belongs to.
  String? get eventId => _eventId;

  /// True until the first answer about the live activity arrives.
  bool get loading => _loading;

  /// Starts listening. If it is already listening, it only retries the
  /// schedules that failed.
  void start() {
    if (_eventsSubscription != null) {
      _watchSchedules();
      return;
    }
    _loading = true;
    notifyListeners();
    _eventsSubscription = _eventRepository.getEventsStream().listen(
      _followEvents,
      onError: _stopWithError,
    );
  }

  void _followEvents(List<Event> events) {
    _candidates = [
      for (final status in [EventStatus.active, EventStatus.upcoming])
        for (final event in events)
          if (event.status == status) event.id,
    ];
    final gone = _schedules.keys
        .where((id) => !_candidates.contains(id))
        .toList();
    for (final id in gone) {
      _schedules.remove(id)?.cancel();
    }
    _answers.removeWhere((id, _) => !_candidates.contains(id));
    _watchSchedules();
    _update();
  }

  /// Listens to the schedule of every candidate that is not being followed.
  void _watchSchedules() {
    for (final id in _candidates) {
      if (_schedules.containsKey(id)) continue;
      _schedules[id] = _scheduleRepository
          .getListScheduleStream(id)
          .listen(
            (schedule) {
              _answers[id] = schedule.liveActivity;
              _update();
            },
            onError: (Object error) {
              // The other events keep working.
              _log(error);
              _schedules.remove(id)?.cancel();
              _answers[id] = null;
              _update();
            },
          );
    }
  }

  void _update() {
    String? eventId;
    Speaker? activity;
    for (final id in _candidates) {
      final answer = _answers[id];
      if (answer != null) {
        eventId = id;
        activity = answer;
        break;
      }
    }
    _eventId = eventId;
    _activity = activity;
    _loading = activity == null && !_candidates.every(_answers.containsKey);
    notifyListeners();
  }

  void _stopWithError(Object error) {
    _log(error);
    _cancel();
    _candidates = [];
    _answers.clear();
    _eventId = null;
    _activity = null;
    _loading = false;
    notifyListeners();
  }

  void _log(Object error) {
    if (kDebugMode) debugPrint('Live activity failed: $error');
  }

  void _cancel() {
    for (final subscription in _schedules.values) {
      subscription.cancel();
    }
    _schedules.clear();
    _eventsSubscription?.cancel();
    _eventsSubscription = null;
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }
}

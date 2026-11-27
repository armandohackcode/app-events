import 'dart:async';

import 'package:app_events/domain/models/event.dart';
import 'package:app_events/domain/models/live_activity.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/domain/repositories/event_repository.dart';
import 'package:app_events/domain/repositories/schedule_repository.dart';
import 'package:flutter/foundation.dart';

/// Follows, in real time, the activity marked as live in the active event.
class LiveActivityProvider with ChangeNotifier {
  final EventRepository _eventRepository;
  final ScheduleRepository _scheduleRepository;
  LiveActivityProvider(this._eventRepository, this._scheduleRepository);

  StreamSubscription<List<Event>>? _eventsSubscription;
  StreamSubscription<List<Speaker>>? _scheduleSubscription;
  String? _eventId;
  Speaker? _activity;
  bool _loading = false;

  /// The live activity, or null when there is none.
  Speaker? get activity => _activity;

  /// Event that [activity] belongs to.
  String? get eventId => _eventId;

  /// True until the first answer about the live activity arrives.
  bool get loading => _loading;

  /// Starts listening. It does nothing if it is already listening; after an
  /// error it tries again.
  void start() {
    if (_eventsSubscription != null) return;
    _loading = true;
    notifyListeners();
    _eventsSubscription = _eventRepository.getEventsStream().listen(
      _followActiveEvent,
      onError: _stopWithError,
    );
  }

  void _followActiveEvent(List<Event> events) {
    String? active;
    for (final event in events) {
      if (event.status == EventStatus.active) {
        active = event.id;
        break;
      }
    }
    if (active != null && active == _eventId && _scheduleSubscription != null) {
      return;
    }

    _scheduleSubscription?.cancel();
    _scheduleSubscription = null;
    _eventId = active;
    // Nothing of the previous event may stay on screen.
    _activity = null;
    _loading = active != null;
    notifyListeners();
    if (active == null) return;

    _scheduleSubscription = _scheduleRepository
        .getListScheduleStream(active)
        .listen((schedule) {
          _activity = schedule.liveActivity;
          _loading = false;
          notifyListeners();
        }, onError: _stopWithError);
  }

  void _stopWithError(Object error) {
    if (kDebugMode) debugPrint('Live activity failed: $error');
    _cancel();
    _eventId = null;
    _activity = null;
    _loading = false;
    notifyListeners();
  }

  void _cancel() {
    _scheduleSubscription?.cancel();
    _scheduleSubscription = null;
    _eventsSubscription?.cancel();
    _eventsSubscription = null;
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }
}

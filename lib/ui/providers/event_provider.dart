import 'dart:async';

import 'package:app_events/domain/models/event.dart';
import 'package:app_events/domain/repositories/event_repository.dart';
import 'package:flutter/material.dart';

class EventProvider with ChangeNotifier {
  final EventRepository _repository;
  EventProvider(this._repository);

  List<Event> _events = [];
  bool _loading = false;
  bool _disposed = false;
  StreamSubscription<List<Event>>? _eventsSub;

  List<Event> get events => _events;
  bool get loading => _loading;

  Event? get activeEvent {
    try {
      return _events.firstWhere((e) => e.status == EventStatus.active);
    } catch (_) {
      return null;
    }
  }

  Stream<List<Event>> get eventsStream => _repository.getEventsStream();

  Future<void> loadEvents() async {
    _loading = true;
    notifyListeners();
    try {
      _events = await _repository.getEvents();
      _ensureEventsStreamSubscription();
    } finally {
      _loading = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  void _ensureEventsStreamSubscription() {
    if (_eventsSub != null || _disposed) return;
    try {
      _eventsSub = _repository.getEventsStream().listen((nextEvents) {
        if (_disposed) return;
        _events = nextEvents;
        notifyListeners();
      }, onError: (_) {});
    } catch (_) {
      // Keep getEvents() fallback when mock repositories do not stub streams.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_eventsSub?.cancel());
    _eventsSub = null;
    super.dispose();
  }

  Future<void> addEvent(Event event, {String? imagePath}) async {
    await _repository.addEvent(event, imagePath: imagePath);
    await loadEvents();
  }

  Future<void> updateEvent(Event event, {String? imagePath}) async {
    await _repository.updateEvent(event, imagePath: imagePath);
    await loadEvents();
  }

  Future<void> updateEventStatus(String eventId, EventStatus status) async {
    await _repository.updateEventStatus(eventId, status);
    await loadEvents();
  }
}

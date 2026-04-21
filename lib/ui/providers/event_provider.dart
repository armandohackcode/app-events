import 'package:app_events/domain/models/event.dart';
import 'package:app_events/domain/repositories/event_repository.dart';
import 'package:flutter/material.dart';

class EventProvider with ChangeNotifier {
  final EventRepository _repository;
  EventProvider(this._repository);

  List<Event> _events = [];
  bool _loading = false;

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
    _events = await _repository.getEvents();
    _loading = false;
    notifyListeners();
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

import 'package:app_events/domain/datasources/event_datasource.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:app_events/domain/repositories/event_repository.dart';

class EventRepositoryImpl implements EventRepository {
  final EventDatasource _db;
  EventRepositoryImpl(this._db);

  @override
  Future<List<Event>> getEvents() => _db.getEvents();

  @override
  Stream<List<Event>> getEventsStream() => _db.getEventsStream();

  @override
  Future<void> addEvent(Event event, {String? imagePath}) =>
      _db.addEvent(event, imagePath: imagePath);

  @override
  Future<void> updateEvent(Event event, {String? imagePath}) =>
      _db.updateEvent(event, imagePath: imagePath);

  @override
  Future<void> updateEventStatus(String eventId, EventStatus status) =>
      _db.updateEventStatus(eventId, status);
}

import 'package:app_events/domain/models/event.dart';
import 'package:app_events/domain/repositories/event_repository.dart';
import 'package:app_events/ui/providers/event_provider.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Manual mock — no external packages required (ISP: only implements what
// tests need; DIP: EventProvider depends on the abstract EventRepository).
// ---------------------------------------------------------------------------
class _FakeEventRepository implements EventRepository {
  final List<Event> _store;
  bool addCalled = false;
  bool updateCalled = false;
  bool updateStatusCalled = false;
  String? lastUpdatedStatus;

  _FakeEventRepository([List<Event>? initial])
      : _store = initial ?? [];

  @override
  Future<List<Event>> getEvents() async => List.unmodifiable(_store);

  @override
  Stream<List<Event>> getEventsStream() => Stream.value(List.unmodifiable(_store));

  @override
  Future<void> addEvent(Event event, {String? imagePath}) async {
    addCalled = true;
    _store.add(event);
  }

  @override
  Future<void> updateEvent(Event event, {String? imagePath}) async {
    updateCalled = true;
    final idx = _store.indexWhere((e) => e.id == event.id);
    if (idx != -1) _store[idx] = event;
  }

  @override
  Future<void> updateEventStatus(String eventId, EventStatus status) async {
    updateStatusCalled = true;
    lastUpdatedStatus = status.value;
    final idx = _store.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      _store[idx] = _store[idx].copyWith(status: status);
    }
  }
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------
Event _makeEvent({
  String id = 'evt-1',
  String title = 'GDG DevFest',
  EventStatus status = EventStatus.upcoming,
}) =>
    Event(
      id: id,
      title: title,
      description: 'Descripción',
      startDate: DateTime(2025, 11, 15),
      endDate: DateTime(2025, 11, 15, 23),
      locationUrl: '',
      imageUrl: '',
      status: status,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  group('EventProvider', () {
    late _FakeEventRepository repo;
    late EventProvider provider;

    setUp(() {
      repo = _FakeEventRepository();
      provider = EventProvider(repo);
    });

    tearDown(() => provider.dispose());

    test('initial state: empty events, not loading', () {
      expect(provider.events, isEmpty);
      expect(provider.loading, isFalse);
      expect(provider.activeEvent, isNull);
    });

    test('loadEvents populates events list', () async {
      repo = _FakeEventRepository([_makeEvent()]);
      provider = EventProvider(repo);

      await provider.loadEvents();

      expect(provider.events, hasLength(1));
      expect(provider.events.first.title, 'GDG DevFest');
      expect(provider.loading, isFalse);
    });

    test('addEvent delegates to repository and refreshes list', () async {
      final event = _makeEvent();

      await provider.addEvent(event);

      expect(repo.addCalled, isTrue);
      expect(provider.events, hasLength(1));
    });

    test('addEvent passes imagePath to repository', () async {
      String? capturedPath;
      final capturingRepo = _CapturingRepo(onAdd: (path) => capturedPath = path);
      final p = EventProvider(capturingRepo);

      await p.addEvent(_makeEvent(), imagePath: '/tmp/image.jpg');

      expect(capturedPath, '/tmp/image.jpg');
      p.dispose();
    });

    test('updateEvent delegates to repository and refreshes list', () async {
      final event = _makeEvent();
      repo = _FakeEventRepository([event]);
      provider = EventProvider(repo);
      await provider.loadEvents();

      final updated = event.copyWith(title: 'Updated Title');
      await provider.updateEvent(updated);

      expect(repo.updateCalled, isTrue);
      expect(provider.events.first.title, 'Updated Title');
    });

    test('updateEventStatus changes status and refreshes', () async {
      final event = _makeEvent(status: EventStatus.upcoming);
      repo = _FakeEventRepository([event]);
      provider = EventProvider(repo);
      await provider.loadEvents();

      await provider.updateEventStatus('evt-1', EventStatus.active);

      expect(repo.updateStatusCalled, isTrue);
      expect(repo.lastUpdatedStatus, 'active');
      expect(provider.events.first.status, EventStatus.active);
    });

    group('activeEvent', () {
      test('returns null when no active event', () async {
        repo = _FakeEventRepository([_makeEvent(status: EventStatus.upcoming)]);
        provider = EventProvider(repo);
        await provider.loadEvents();

        expect(provider.activeEvent, isNull);
      });

      test('returns the active event when present', () async {
        repo = _FakeEventRepository([
          _makeEvent(id: 'evt-1', status: EventStatus.upcoming),
          _makeEvent(id: 'evt-2', status: EventStatus.active, title: 'Active'),
        ]);
        provider = EventProvider(repo);
        await provider.loadEvents();

        expect(provider.activeEvent, isNotNull);
        expect(provider.activeEvent!.id, 'evt-2');
        expect(provider.activeEvent!.title, 'Active');
      });

      test('returns null after active event is closed', () async {
        final active = _makeEvent(id: 'evt-1', status: EventStatus.active);
        repo = _FakeEventRepository([active]);
        provider = EventProvider(repo);
        await provider.loadEvents();

        expect(provider.activeEvent, isNotNull);

        await provider.updateEventStatus('evt-1', EventStatus.finished);

        expect(provider.activeEvent, isNull);
      });
    });

    test('eventsStream emits the repository stream', () async {
      repo = _FakeEventRepository([_makeEvent()]);
      provider = EventProvider(repo);

      final events = await provider.eventsStream.first;
      expect(events, hasLength(1));
    });
  });
}

// Helper to capture imagePath without full fake implementation
class _CapturingRepo implements EventRepository {
  final void Function(String? path) onAdd;
  _CapturingRepo({required this.onAdd});

  @override
  Future<List<Event>> getEvents() async => [];
  @override
  Stream<List<Event>> getEventsStream() => const Stream.empty();
  @override
  Future<void> addEvent(Event event, {String? imagePath}) async => onAdd(imagePath);
  @override
  Future<void> updateEvent(Event event, {String? imagePath}) async {}
  @override
  Future<void> updateEventStatus(String eventId, EventStatus status) async {}
}

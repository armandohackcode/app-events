import 'package:app_events/domain/models/event.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/domain/models/speed_run_challenge.dart';
import 'package:app_events/domain/models/sponsor.dart';

// ---------------------------------------------------------------------------
// Test data builders shared across unit, data and widget tests.
// Only override the fields a test cares about.
// ---------------------------------------------------------------------------

Event makeEvent({
  String id = 'evt-1',
  String title = 'GDG DevFest',
  EventStatus status = EventStatus.upcoming,
  DateTime? startDate,
}) => Event(
  id: id,
  title: title,
  description: 'Description',
  startDate: startDate ?? DateTime(2025, 11, 15),
  endDate: DateTime(2025, 11, 15, 23),
  locationUrl: '',
  imageUrl: '',
  status: status,
);

SpeedRunChallenge makeChallenge({
  String id = 'ch-1',
  String title = 'Build a widget',
  ChallengeState state = ChallengeState.active,
  int position = 1,
  String imageUrl = '',
}) => SpeedRunChallenge(
  id: id,
  imageUrl: imageUrl,
  title: title,
  challenge: 'Make it fast',
  state: state,
  position: position,
);

Speaker makeSpeaker({String uuid = 'spk-1', String name = 'Ada'}) => Speaker(
  uuid: uuid,
  title: 'Flutter Clean Architecture',
  description: 'Talk',
  name: name,
  profession: 'GDE',
  aboutMe: '',
  photoUrl: '',
  technologyType: 'Mobile',
  type: 'conference',
  color: 'blue',
  schedule: '10:00',
  position: 1,
  socialNetwork: [SocialNetwork(type: 'github', link: 'https://github.com')],
);

Sponsor makeSponsor({String id = 'sp-1', String name = 'Google'}) =>
    Sponsor(id: id, name: name, photoUrl: '', link: 'https://google.com');

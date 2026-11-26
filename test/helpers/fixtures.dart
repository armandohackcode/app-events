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

Speaker makeSpeaker({
  String uuid = 'spk-1',
  String name = 'Ada',
  String title = 'Flutter Clean Architecture',
  String schedule = '10:00',
  String type = 'conference',
  String technologyType = 'Mobile',
  String profession = 'GDE',
  String description = 'Talk',
  int position = 1,
  bool isLive = false,
  List<SocialNetwork>? socialNetwork,
}) => Speaker(
  uuid: uuid,
  title: title,
  description: description,
  name: name,
  profession: profession,
  aboutMe: '',
  photoUrl: '',
  technologyType: technologyType,
  type: type,
  color: 'blue',
  schedule: schedule,
  position: position,
  isLive: isLive,
  socialNetwork:
      socialNetwork ??
      [SocialNetwork(type: 'github', link: 'https://github.com')],
);

Sponsor makeSponsor({String id = 'sp-1', String name = 'Google'}) =>
    Sponsor(id: id, name: name, photoUrl: '', link: 'https://google.com');

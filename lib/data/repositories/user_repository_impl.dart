import 'package:app_events/domain/datasources/user_datasource.dart';
import 'package:app_events/domain/models/event_badge.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserDatasource _db;
  UserRepositoryImpl(this._db);

  @override
  Future<UserCompetitor?> joinEvent(String eventId, UserCompetitor user) =>
      _db.joinEvent(eventId, user);

  @override
  Future<UserCompetitor?> addNewFriend(
    String token,
    UserCompetitor userCompetitor,
  ) =>
      _db.addNewFriend(token, userCompetitor);

  @override
  Future<void> addScoreAdmin(String uuid) => _db.addScoreAdmin(uuid);

  @override
  Future<bool> addWorkshop(
    String eventId,
    String speakerUuid,
    UserCompetitor userCompetitor,
  ) =>
      _db.addWorkshop(eventId, speakerUuid, userCompetitor);

  @override
  Future<UserCompetitor?> addCompetitor(UserCompetitor user) =>
      _db.addCompetitor(user);

  @override
  Future<void> editCompetitor(UserCompetitor user) =>
      _db.editCompetitor(user);

  @override
  Future<List<UserCompetitor>> getAttendees() => _db.getAttendees();

  @override
  Future<UserCompetitor?> getUserInfo(String uuid) => _db.getUserInfo(uuid);

  @override
  Future<List<UserCompetitor>> searchAttendees({String? param}) =>
      _db.searchAttendees(param: param);

  @override
  Future<bool> searchUserInWorkShop(
    String eventId,
    String speakerUuid,
    UserCompetitor userCompetitor,
  ) =>
      _db.searchUserInWorkShop(eventId, speakerUuid, userCompetitor);

  @override
  Stream<UserCompetitor?> streamInfoUser(UserCompetitor userCompetitor) =>
      _db.streamInfoUser(userCompetitor);

  @override
  Future<void> updateToken(String token) => _db.updateToken(token);

  @override
  Future<bool> validateIsAdmin(String uuid) => _db.validateIsAdmin(uuid);

  @override
  Future<UserCompetitor?> addItemTreasure(UserCompetitor userCompetitor) =>
      _db.addItemTreasure(userCompetitor);

  @override
  Future<void> awardBadge(String competitorUuid, EventBadge badge) =>
      _db.awardBadge(competitorUuid, badge);

  @override
  Future<void> resetAllCompetitors() => _db.resetAllCompetitors();
}

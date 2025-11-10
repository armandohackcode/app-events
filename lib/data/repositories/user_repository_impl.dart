import 'package:app_events/domain/datasources/user_datasource.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserDatasource _db;
  UserRepositoryImpl(this._db);

  @override
  Future<UserCompetitor?> addNewFriend(
    String token,
    UserCompetitor userCompetitor,
  ) async {
    return _db.addNewFriend(token, userCompetitor);
  }

  @override
  Future<void> addScoreAdmin(String uuid) async {
    return _db.addScoreAdmin(uuid);
  }

  @override
  Future<bool> addWorkshop(String uuid, UserCompetitor userCompetitor) async {
    return _db.addWorkshop(uuid, userCompetitor);
  }

  @override
  Future<UserCompetitor?> addCompetitor(UserCompetitor user) {
    return _db.addCompetitor(user);
  }

  @override
  Future<void> editCompetitor(UserCompetitor user) async {
    return _db.editCompetitor(user);
  }

  @override
  Future<List<UserCompetitor>> getAttendees() async {
    return _db.getAttendees();
  }

  @override
  Future<UserCompetitor?> getUserInfo(String uuid) async {
    return _db.getUserInfo(uuid);
  }

  @override
  Future<List<UserCompetitor>> searchAttendees({String? param}) async {
    return _db.searchAttendees(param: param);
  }

  @override
  Future<bool> searchUserInWorkShop(
    String uuid,
    UserCompetitor userCompetitor,
  ) async {
    return _db.searchUserInWorkShop(uuid, userCompetitor);
  }

  @override
  Stream<UserCompetitor?> streamInfoUser(UserCompetitor userCompetitor) async* {
    yield* _db.streamInfoUser(userCompetitor);
  }

  @override
  Future<void> updateToken(String token) async {
    return _db.updateToken(token);
  }

  @override
  Future<bool> validateIsAdmin(String uuid) async {
    return _db.validateIsAdmin(uuid);
  }

  @override
  Future<UserCompetitor?> addItemTreasure(UserCompetitor userCompetitor) {
    return _db.addItemTreasure(userCompetitor);
  }
}

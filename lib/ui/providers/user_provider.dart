import 'package:app_events/domain/models/event_badge.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier {
  final UserRepository _repository;
  UserProvider(this._repository);

  UserCompetitor? _userCompetitor;
  List<UserCompetitor> _attendees = [];
  bool _isAdmin = false;
  bool _loadingAttendees = false;

  bool get loadingAttendees => _loadingAttendees;
  set loadingAttendees(bool state) {
    _loadingAttendees = state;
    notifyListeners();
  }

  List<UserCompetitor> get attendees => _attendees;
  set attendees(List<UserCompetitor> list) {
    _attendees = list;
    notifyListeners();
  }

  bool get isAdmin => _isAdmin;
  set isAdmin(bool state) {
    _isAdmin = state;
    notifyListeners();
  }

  UserCompetitor? get userCompetitor => _userCompetitor;
  set userCompetitor(UserCompetitor? data) {
    _userCompetitor = data;
    notifyListeners();
  }

  Future<void> validateIsAdmin(String uuid) async {
    try {
      var res = await _repository.validateIsAdmin(uuid);
      if (res) isAdmin = true;
      var data = await _repository.getUserInfo(uuid);
      if (data != null) userCompetitor = data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateToken(String token) async {
    try {
      await _repository.updateToken(token);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCompetitor?> joinEvent(String eventId) async {
    try {
      if (userCompetitor == null) return null;
      final updated = await _repository.joinEvent(eventId, userCompetitor!);
      if (updated != null) userCompetitor = updated;
      return updated;
    } catch (e) {
      if (kDebugMode) print(e);
      return null;
    }
  }

  Future<UserCompetitor?> addNewFriend(String token) async {
    try {
      var user = await _repository.addNewFriend(token, userCompetitor!);
      return user;
    } catch (e) {
      if (kDebugMode) print(e);
      return null;
    }
  }

  Future<bool> addWorkshop(String eventId, String speakerUuid) async {
    try {
      if (userCompetitor == null) return false;
      return await _repository.addWorkshop(eventId, speakerUuid, userCompetitor!);
    } catch (e) {
      if (kDebugMode) print(e);
      return false;
    }
  }

  Future<bool> searchUserInWorkshop(String eventId, String speakerUuid) async {
    try {
      if (userCompetitor == null) return false;
      return await _repository.searchUserInWorkShop(
          eventId, speakerUuid, userCompetitor!);
    } catch (e) {
      return false;
    }
  }

  Future<void> addCompetitor({
    required String name,
    required String token,
    required String photoUrl,
  }) async {
    try {
      var user = UserCompetitor(
        uuid: '',
        name: name,
        photoUrl: photoUrl,
        profession: '',
        aboutMe: '',
        tokenAuthorization: token,
        score: 0,
        socialNetwork: [],
        friends: [],
      );
      await _repository.addCompetitor(user);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCompetitor?> getUserInfo(String uuid) async {
    try {
      return await _repository.getUserInfo(uuid);
    } catch (e) {
      if (kDebugMode) print(e);
      return null;
    }
  }

  Stream<UserCompetitor?> streamInfoUser() {
    if (userCompetitor == null) throw Exception('UserCompetitor is null');
    return _repository.streamInfoUser(userCompetitor!);
  }

  Future<void> editCompetitor(UserCompetitor user) async {
    try {
      await _repository.editCompetitor(user);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> getAttendees() async {
    try {
      loadingAttendees = true;
      attendees = await _repository.getAttendees();
      loadingAttendees = false;
    } catch (e) {
      loadingAttendees = false;
      rethrow;
    }
  }

  Future<void> searchAttendees({String? param}) async {
    try {
      attendees = await _repository.searchAttendees(param: param);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addScoreAdmin(String uuid) async {
    try {
      await _repository.addScoreAdmin(uuid);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> addItemTreasure(String itemId) async {
    try {
      if (userCompetitor == null) return false;
      var updatedTreasures = List<String>.from(userCompetitor!.treasures);
      if (!updatedTreasures.contains(itemId)) {
        updatedTreasures.add(itemId);
        var result = await _repository
            .addItemTreasure(userCompetitor!.copyWith(treasures: updatedTreasures));
        if (result != null) {
          userCompetitor = result;
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) print(e);
      return false;
    }
  }

  /// Admin: awards a badge to a specific competitor
  Future<void> awardBadge(String competitorUuid, EventBadge badge) async {
    try {
      await _repository.awardBadge(competitorUuid, badge);
    } catch (e) {
      rethrow;
    }
  }

  /// Admin: resets all competitors after badges have been awarded
  Future<void> resetAllCompetitors() async {
    try {
      await _repository.resetAllCompetitors();
    } catch (e) {
      rethrow;
    }
  }
}

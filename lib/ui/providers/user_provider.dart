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
      if (res) {
        isAdmin = true;
      }
      var data = await _repository.getUserInfo(uuid);
      if (data != null) {
        userCompetitor = data;
      }
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

  Future<UserCompetitor?> addNewFriend(String token) async {
    try {
      var user = await _repository.addNewFriend(token, userCompetitor!);
      return user;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }

  Future<bool> addWorkshop(String uuid) async {
    try {
      if (userCompetitor == null) return false;
      var res = await _repository.addWorkshop(uuid, userCompetitor!);
      return res;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  Future<bool> searchUserInWorkshop(String uuid) async {
    try {
      if (userCompetitor == null) return false;
      var res = await _repository.searchUserInWorkShop(uuid, userCompetitor!);
      return res;
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
        profession: "",
        aboutMe: "",
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
      var data = await _repository.getUserInfo(uuid);
      return data;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }

  Stream<UserCompetitor?> streamInfoUser() {
    if (userCompetitor == null) {
      throw Exception("UserCompetitor is null");
    }
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
      var data = await _repository.getAttendees();
      attendees = data;
      loadingAttendees = false;
    } catch (e) {
      loadingAttendees = false;
      rethrow;
    }
  }

  Future<void> searchAttendees({String? param}) async {
    try {
      var data = await _repository.searchAttendees(param: param);
      attendees = data;
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
        var updatedUser = userCompetitor!.copyWith(treasures: updatedTreasures);
        var result = await _repository.addItemTreasure(updatedUser);
        if (result != null) {
          userCompetitor = result;
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return false;
  }
}

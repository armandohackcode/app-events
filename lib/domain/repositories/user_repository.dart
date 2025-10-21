import 'package:app_events/domain/models/user_competitor.dart';

abstract class UserRepository {
  /// Searches for user information in the admin list
  Future<bool> validateIsAdmin(String uuid);

  /// Updates the authorization token
  Future<void> updateToken(String token);

  /// Method to add a new friend
  Future<UserCompetitor?> addNewFriend(
      String token, UserCompetitor userCompetitor);

  /// Adds a workshop participant
  Future<bool> addWorkshop(String uuid, UserCompetitor userCompetitor);

  /// Monitors changes in speaker data
  Future<bool> searchUserInWorkShop(String uuid, UserCompetitor userCompetitor);

  /// Retrieves information about a user by their UUID
  Future<UserCompetitor?> getUserInfo(String uuid);

  /// Streams user information
  Stream<UserCompetitor?> streamInfoUser(UserCompetitor userCompetitor);

  /// creates a new competitor user
  Future<UserCompetitor?> addCompetitor(UserCompetitor user);

  /// Updates and edits user information
  Future<void> editCompetitor(UserCompetitor user);

  /// Awards 10 points for participating in quizzes
  Future<void> addScoreAdmin(String uuid);

  /// Searches for a resource in the library
  Future<List<UserCompetitor>> searchAttendees({String? param});

  /// Lists the attendees
  Future<List<UserCompetitor>> getAttendees();
}

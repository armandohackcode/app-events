import 'package:app_events/domain/models/event_badge.dart';
import 'package:app_events/domain/models/user_competitor.dart';

abstract class UserRepository {
  /// Searches for user information in the admin list
  Future<bool> validateIsAdmin(String uuid);

  /// Updates the authorization token
  Future<void> updateToken(String token);

  /// Joins the user to an active event, creating competitor record if needed
  Future<UserCompetitor?> joinEvent(String eventId, UserCompetitor user);

  /// Method to add a new friend
  Future<UserCompetitor?> addNewFriend(
    String token,
    UserCompetitor userCompetitor,
  );

  /// Adds a workshop participant
  Future<bool> addWorkshop(
    String eventId,
    String speakerUuid,
    UserCompetitor userCompetitor,
  );

  /// Checks if user is already registered in a workshop
  Future<bool> searchUserInWorkShop(
    String eventId,
    String speakerUuid,
    UserCompetitor userCompetitor,
  );

  /// Retrieves information about a user by their UUID
  Future<UserCompetitor?> getUserInfo(String uuid);

  /// Streams user information
  Stream<UserCompetitor?> streamInfoUser(UserCompetitor userCompetitor);

  /// Creates a new competitor user
  Future<UserCompetitor?> addCompetitor(UserCompetitor user);

  /// Updates and edits user information
  Future<void> editCompetitor(UserCompetitor user);

  /// Awards 10 points for participating in quizzes
  Future<void> addScoreAdmin(String uuid);

  /// Searches attendees by name
  Future<List<UserCompetitor>> searchAttendees({String? param});

  /// Lists the attendees
  Future<List<UserCompetitor>> getAttendees();

  /// Adds a treasure item to the user's collection
  Future<UserCompetitor?> addItemTreasure(UserCompetitor userCompetitor);

  /// Awards an event badge to a competitor (admin action)
  Future<void> awardBadge(String competitorUuid, EventBadge badge);

  /// Resets all competitors (admin action, called after all badges are awarded)
  Future<void> resetAllCompetitors();
}

import 'package:app_events/domain/models/organizer.dart';
import 'package:app_events/domain/models/sponsor.dart';
import 'package:app_events/domain/models/user_competitor.dart';

abstract class OtherRepository {
  /// Retrieves the list of sponsors
  Future<List<Sponsor>> getSponsors();

  /// Lists all organizers
  Future<List<Organizer>> getOrganizer();

  /// Listens for changes in the ranking
  Stream<List<UserCompetitor>> getRanking();

  /// Adds a sponsor to the list
  Future<void> addSponsor(Sponsor sponsor, String? sponsorImagePath);
}

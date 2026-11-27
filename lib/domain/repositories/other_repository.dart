import 'package:app_events/domain/models/organizer.dart';
import 'package:app_events/domain/models/sponsor.dart';
import 'package:app_events/domain/models/treasure_hunt_model.dart';
import 'package:app_events/domain/models/user_competitor.dart';

abstract class OtherRepository {
  /// Retrieves the list of sponsors
  Future<List<Sponsor>> getSponsors();

  /// Lists all organizers
  Future<List<Organizer>> getOrganizer();

  /// Add a new organizer to the list
  Future<void> addOrganizer(
    Organizer organizerData,
    String? organizerImagePath,
  );

  /// Delete one organizer by id
  Future<void> deleteOrganizer(String organizerId);

  /// Listens for changes in the ranking
  Stream<List<UserCompetitor>> getRanking();

  /// Adds a sponsor to the list
  Future<void> addSponsor(Sponsor sponsor, String? sponsorImagePath);

  /// List treasure hunt items
  Future<List<TreasureHuntModel>> getTreasureHuntItems();

  /// Deletes a sponsor by id
  Future<void> deleteSponsor(String sponsorId);
}

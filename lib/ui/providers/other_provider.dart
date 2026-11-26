import 'package:app_events/domain/models/organizer.dart';
import 'package:app_events/domain/models/sponsor.dart';
import 'package:app_events/domain/models/treasure_hunt_model.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/domain/repositories/other_repository.dart';
import 'package:flutter/foundation.dart';

class OtherProvider with ChangeNotifier {
  final OtherRepository _otherRepository;
  bool _loadingSponsor = false;
  bool _loadingOrganizers = false;
  bool _loadingTreasureHunt = false;

  OtherProvider(this._otherRepository);

  List<Sponsor> _sponsors = [];
  List<Organizer> _organizers = [];
  List<UserCompetitor> _ranking = [];
  List<TreasureHuntModel> _treasureHuntItems = [];

  bool get loadingTreasureHunt => _loadingTreasureHunt;
  set loadingTreasureHunt(bool value) {
    _loadingTreasureHunt = value;
    notifyListeners();
  }

  List<TreasureHuntModel> get treasureHuntItems => _treasureHuntItems;
  set treasureHuntItems(List<TreasureHuntModel> list) {
    _treasureHuntItems = list;
    notifyListeners();
  }

  bool get loadingSponsor => _loadingSponsor;
  set loadingSponsor(bool value) {
    _loadingSponsor = value;
    notifyListeners();
  }

  bool get loadingOrganizers => _loadingOrganizers;
  set loadingOrganizers(bool value) {
    _loadingOrganizers = value;
    notifyListeners();
  }

  List<Organizer> get organizers => _organizers;
  set organizers(List<Organizer> list) {
    _organizers = list;
    notifyListeners();
  }

  List<UserCompetitor> get ranking => _ranking;
  set ranking(List<UserCompetitor> list) {
    _ranking = list;
    notifyListeners();
  }

  List<Sponsor> get sponsors => _sponsors;
  set sponsors(List<Sponsor> list) {
    _sponsors = list;
    notifyListeners();
  }

  Future<void> getSponsors() async {
    if (sponsors.isEmpty) {
      sponsors = await _otherRepository.getSponsors();
    }
  }

  Future<void> getOrganizer() async {
    if (organizers.isEmpty) {
      organizers = await _otherRepository.getOrganizer();
    }
  }

  Future<void> addOrganizer(
    Organizer organizer,
    String? organizerImagePath,
  ) async {
    loadingOrganizers = true;
    try {
      loadingOrganizers = true;
      await _otherRepository.addOrganizer(organizer, organizerImagePath);
      organizers = await _otherRepository.getOrganizer();
    } catch (e) {
      rethrow;
    } finally {
      loadingOrganizers = false;
    }
  }

  Future<void> deleteOrganizer(String organizerId) async {
    loadingOrganizers = true;
    try {
      await _otherRepository.deleteOrganizer(organizerId);
      organizers = await _otherRepository.getOrganizer();
    } catch (e) {
      rethrow;
    } finally {
      loadingOrganizers = false;
    }
  }

  Stream<List<UserCompetitor>> getRanking() {
    return _otherRepository.getRanking();
  }

  Future<void> addSponsor(Sponsor sponsor, String? sponsorImagePath) async {
    loadingSponsor = true;
    try {
      await _otherRepository.addSponsor(sponsor, sponsorImagePath);
      sponsors = await _otherRepository.getSponsors();
    } catch (e) {
      rethrow;
    } finally {
      loadingSponsor = false;
    }
  }

  Future<void> deleteSponsor(String sponsorId) async {
    loadingSponsor = true;
    try {
      await _otherRepository.deleteSponsor(sponsorId);
      sponsors = await _otherRepository.getSponsors();
    } catch (e) {
      rethrow;
    } finally {
      loadingSponsor = false;
    }
  }

  Future<void> getTreasureHuntItems() async {
    try {
      loadingTreasureHunt = true;
      if (treasureHuntItems.isEmpty) {
        treasureHuntItems = await _otherRepository.getTreasureHuntItems();
      }
    } catch (e) {
      rethrow;
    } finally {
      loadingTreasureHunt = false;
    }
  }
}

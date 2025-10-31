import 'package:app_events/domain/models/organizer.dart';
import 'package:app_events/domain/models/sponsor.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/domain/repositories/other_repository.dart';
import 'package:flutter/foundation.dart';

class OtherProvider with ChangeNotifier {
  final OtherRepository _otherRepository;
  bool isLoading = false;
  bool get loading => isLoading;

  OtherProvider(this._otherRepository);

  List<Sponsor> _sponsors = [];
  List<Organizer> _organizers = [];
  List<UserCompetitor> _ranking = [];

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
    sponsors = await _otherRepository.getSponsors();
  }

  Future<void> getOrganizer() async {
    organizers = await _otherRepository.getOrganizer();
  }

  Stream<List<UserCompetitor>> getRanking() {
    return _otherRepository.getRanking();
  }

  Future<void> addSponsor(Sponsor sponsor, String? sponsorImagePath) async {
    isLoading = true;
    notifyListeners();

    try {
      await _otherRepository.addSponsor(sponsor, sponsorImagePath);
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

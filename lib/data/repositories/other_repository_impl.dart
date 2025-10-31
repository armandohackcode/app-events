import 'package:app_events/domain/datasources/other_datasource.dart';
import 'package:app_events/domain/models/organizer.dart';
import 'package:app_events/domain/models/sponsor.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/domain/repositories/other_repository.dart';

class OtherRepositoryImpl implements OtherRepository {
  final OtherDatasource _db;

  OtherRepositoryImpl(this._db);

  @override
  Future<List<Organizer>> getOrganizer() async {
    return _db.getOrganizer();
  }

  @override
  Stream<List<UserCompetitor>> getRanking() {
    return _db.getRanking();
  }

  @override
  Future<List<Sponsor>> getSponsors() {
    return _db.getSponsors();
  }

  @override
  Future<void> addSponsor(Sponsor sponsor) {
    return _db.addSponsor(sponsor);
  }
}

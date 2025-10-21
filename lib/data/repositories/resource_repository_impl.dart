import 'package:app_events/domain/datasources/resource_datasource.dart';
import 'package:app_events/domain/models/resource_library.dart';
import 'package:app_events/domain/repositories/resource_repository.dart';

class ResourceRepositoryImpl implements ResourceRepository {
  final ResourceDatasource _db;

  ResourceRepositoryImpl(this._db);
  @override
  Future<void> addResources(ResourceLibrary data) async {
    return _db.addResources(data);
  }

  @override
  Future<List<ResourceLibrary>> getResources() async {
    return _db.getResources();
  }

  @override
  Future<List<ResourceLibrary>> searchResource({String? param}) async {
    return _db.searchResource(param: param);
  }
}

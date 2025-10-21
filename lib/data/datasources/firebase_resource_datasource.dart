import 'package:app_events/domain/datasources/resource_datasource.dart';
import 'package:app_events/domain/models/resource_library.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseResourceDatasource implements ResourceDatasource {
  final FirebaseFirestore _db;
  FirebaseResourceDatasource(this._db);
  @override
  Future<void> addResources(ResourceLibrary data) async {
    try {
      await _db.collection("resource-library").doc().set(data.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ResourceLibrary>> getResources() async {
    try {
      var res = await _db.collection("resource-library").get();
      var info =
          res.docs.map((e) => ResourceLibrary.fromJson(e.data())).toList();
      return info;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ResourceLibrary>> searchResource({String? param}) async {
    try {
      var res = await _db.collection("resource-library").get();
      var info =
          res.docs.map((e) => ResourceLibrary.fromJson(e.data())).toList();
      var data = info;
      if ((param ?? "").isNotEmpty) {
        data = info
            .where((element) => element.title
                .toLowerCase()
                .contains((param ?? "").toLowerCase()))
            .toList();
        return data;
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }
}

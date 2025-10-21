import 'package:app_events/domain/models/resource_library.dart';

abstract class ResourceRepository {
  /// Adds a new resource to the library
  Future<void> addResources(ResourceLibrary data);

  /// Lists the resources in the library
  Future<List<ResourceLibrary>> getResources();

  /// Searches for resources within the library
  Future<List<ResourceLibrary>> searchResource({String? param});
}

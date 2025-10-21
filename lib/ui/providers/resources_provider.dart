import 'package:app_events/domain/models/resource_library.dart';
import 'package:app_events/domain/repositories/resource_repository.dart';
import 'package:flutter/foundation.dart';

class ResourcesProvider with ChangeNotifier {
  final ResourceRepository resourceRepository;
  ResourcesProvider(this.resourceRepository);

  bool _activeWeb = false;
  bool _activeMobile = false;
  bool _activeCloud = false;
  bool _activeIA = false;

  bool _loadingResource = false;
  List<ResourceLibrary> _resources = [];

  bool get loadingResource => _loadingResource;
  set loadingResource(bool state) {
    _loadingResource = state;
    notifyListeners();
  }

  List<ResourceLibrary> get resources => _resources;
  set resources(List<ResourceLibrary> list) {
    _resources = list;
    notifyListeners();
  }

  bool get activeWeb => _activeWeb;
  bool get activeMobile => _activeMobile;
  bool get activeCloud => _activeCloud;
  bool get activeIA => _activeIA;

  set activeWeb(bool state) {
    _activeWeb = state;
    notifyListeners();
  }

  set activeMobile(bool state) {
    _activeMobile = state;
    notifyListeners();
  }

  set activeCloud(bool state) {
    _activeCloud = state;
    notifyListeners();
  }

  set activeIA(bool state) {
    _activeIA = state;
    notifyListeners();
  }

  Future<void> loadResources() async {
    try {
      loadingResource = true;
      var data = await resourceRepository.getResources();
      resources = data;
      loadingResource = false;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> searchResource({required String param}) async {
    try {
      loadingResource = true;
      if (activeWeb) {
        param = 'Web';
      } else if (activeMobile) {
        param = 'Mobile';
      } else if (activeCloud) {
        param = 'Cloud';
      } else if (activeIA) {
        param = 'IA';
      }
      var data = await resourceRepository.searchResource(param: param);
      resources = data;
      loadingResource = false;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addResources(ResourceLibrary data) async {
    try {
      await resourceRepository.addResources(data);
    } catch (e) {
      rethrow;
    }
  }

  void cleanTag() {
    activeWeb = false;
    activeMobile = false;
    activeCloud = false;
    activeIA = false;
  }
}

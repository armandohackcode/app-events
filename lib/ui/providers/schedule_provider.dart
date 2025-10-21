import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/domain/repositories/schedule_repository.dart';
import 'package:flutter/foundation.dart';

class ScheduleProvider with ChangeNotifier {
  final ScheduleRepository _repository;
  ScheduleProvider(this._repository);

  Speaker? _currentSpeaker;
  List<Speaker> _schedule = [];
  bool _loadingSchedule = false;

  bool _loadingNewSchedule = false;

  bool get loadingSchedule => _loadingSchedule;
  set loadingSchedule(bool state) {
    _loadingSchedule = state;
    notifyListeners();
  }

  Speaker? get currentSpeaker => _currentSpeaker;
  set currentSpeaker(Speaker? data) {
    _currentSpeaker = data;
    notifyListeners();
  }

  List<Speaker> get schedule => _schedule;

  set schedule(List<Speaker> list) {
    _schedule = list;
    notifyListeners();
  }

  bool get loadingNewSchedule => _loadingNewSchedule;
  set loadingNewSchedule(bool state) {
    _loadingNewSchedule = state;
    notifyListeners();
  }

// Load schedule from repository
  Future<void> loadSchedule() async {
    try {
      loadingSchedule = true;
      var data = await _repository.getListSchedule();
      schedule = data;
      loadingSchedule = false;
    } catch (e) {
      rethrow;
    }
  }

  Stream<Speaker?> speakerStream(String uuid) {
    return _repository.speakerStream(uuid);
  }

  Future<void> addNewSchedule(Speaker speaker) async {
    try {
      loadingNewSchedule = true;
      await _repository.addNewSchedule(speaker);
      loadingNewSchedule = false;
    } catch (e) {
      rethrow;
    }
  }
}

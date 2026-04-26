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

  Future<void> loadSchedule(String eventId) async {
    try {
      loadingSchedule = true;
      schedule = await _repository.getListSchedule(eventId);
      loadingSchedule = false;
    } catch (e) {
      loadingSchedule = false;
      rethrow;
    }
  }

  Stream<Speaker?> speakerStream(String eventId, String speakerUuid) =>
      _repository.speakerStream(eventId, speakerUuid);

  Future<void> addNewSchedule(String eventId, Speaker speaker, {String? imagePath}) async {
    try {
      loadingNewSchedule = true;
      await _repository.addNewSchedule(eventId, speaker, imagePath: imagePath);
      loadingNewSchedule = false;
    } catch (e) {
      loadingNewSchedule = false;
      rethrow;
    }
  }
}

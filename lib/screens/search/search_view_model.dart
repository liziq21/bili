import 'package:flutter/foundation.dart';
import 'package:f_biuli/bili/constonts/constonts.dart';

class SearchViewModel extends ChangeNotifier {

  DateTime _startTime = Constonts.minDate;
  DateTime get startTime => _startTime;

  DateTime _endTime = DateTime.now();
  DateTime get endTime => _endTime;
  
  void setStartTime(DateTime time) {
    _startTime = time;
    notifyListeners();
  }

  void setEndTime(DateTime time) {
    _endTime = time;
    notifyListeners();
  }
  
  void selectStartDate() {
    
  }
  
  void selectEndDate() {
    
  }
}


enum DatePickerShowState {
  dismiss,
  selectStartDate,
  selectEndDate;
}
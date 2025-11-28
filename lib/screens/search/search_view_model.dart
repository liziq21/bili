import 'package:flutter/foundation.dart';

import '../../bili/constonts/constonts.dart';

class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    String? initialQuery,
  }) {
    _searchController = .new();
    if (initialQuery != null && initialQuery.trim().isNotEmpty) {
      _searchController.text = initialQuery;
    } else {
      _searchController.openView();
    }
  }
  
  late SearchController _searchController;
  get searchController => _searchController;
  
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
  
  void onChanged(String value) {
    
  }
  
  void onSearchTriggered(String value) {
    _searchController.closeView(value);
  }
  
  void clearSearch() {
    _searchController.clear();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}


enum DatePickerShowState {
  dismiss,
  selectStartDate,
  selectEndDate;
}
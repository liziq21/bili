import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../bili/constonts/constonts.dart';
import '../../network/network_search_data_source.dart';
import '../../utils/command.dart';
import '../../utils/result.dart';

class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    required NetworkSearchDataSource netwotkSearchApi,
    String? initialQuery,
  }) : _netwotkSearchApi = netwotkSearchApi {
    _searchController = .new();
    if (initialQuery != null && initialQuery.trim().isNotEmpty) {
      _searchController.text = initialQuery;
    } else {
      _searchController.openView();
    }
    
    searchSuggest = Command0(_searchSuggest)..execute();
  }
  
  final NetworkSearchDataSource _netwotkSearchApi;
  
  late SearchController _searchController;
  get searchController => _searchController;
  
  List<NetworkSearchSuggestItem> _suggests = [];
  get suggests => _suggests;
  
  late final Command0 searchSuggest;
  
  DateTime _startTime = Constonts.minDate;
  DateTime get startTime => _startTime;

  DateTime _endTime = DateTime.now();
  DateTime get endTime => _endTime;
  
  Future<Result<void>> _searchSuggest() async {
    final result = await netwotkSearchApi.searchSuggest();
    switch (result) {
      case Ok():
        {
          _destinations = result.value.tag;
        }
      case Error():
        {
          _log.warning('Failed to load destinations', result.error);
        }
    }

    notifyListeners();
    return result;
  }
  
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
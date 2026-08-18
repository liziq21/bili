import '../../database/app_database.dart';

class const RecentSearchQuery({
  required final String query,
  required final DateTime queriedDate,
});

extension RecentSearchQueryEntityX on RecentSearchQueryEntity {
  RecentSearchQuery asExternalModel() {
    return RecentSearchQuery(query: query, queriedDate: queriedDate);
  }
}

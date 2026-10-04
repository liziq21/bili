import 'model/user/network_bili_user_card.dart';

abstract class NetworkUserDataSource {
  Future<NetworkBiliUserCardData> getUserCard({required int mid});
}

/*
默认为0
全部用户：0
up主：1
普通用户：2
认证用户：3
*/
enum UserType {
  allUsers,
  upMain,
  normalUser,
  verifiedUser;
  
  @override
  String toString() => '$index';
}
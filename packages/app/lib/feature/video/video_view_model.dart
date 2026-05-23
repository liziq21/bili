/*class VidoeViewModel extends ChangeNotifier {
  VideoViewModel({
    /required ref,
    //required BookingRepository bookingRepository,
    //required UserRepository userRepository,
  }) :
    _ref = ref,
    //_bookingRepository = bookingRepository,
    //_userRepository = userRepository;
  
  final WidgetRef _ref;
  //final BookingRepository _bookingRepository;
  //final UserRepository _userRepository;
  
}

class VideoViewModel extends ChangeNotifier {
  final WidgetRef ref;

  UserViewModel(this.ref);

  User get user => ref.watch(userProvider);

  void increaseScore() {
    ref.read(userProvider.notifier).increaseScore();
    notifyListeners();
  }

  void clearAll() {
    ref.read(userProvider.notifier).clearAll();
    notifyListeners();
  }

  void addMobileNumber(String mobileNumber) {
    ref.read(userProvider.notifier).addMobileNumber(mobileNumber);
  }
}

class UserNotifier extends StateNotifier<User> {
  UserNotifier() : super(User(name: "Maharaja Kumar V", age: 27));

  void increaseScore() {
    state = User(
      name: state.name,
      age: state.age,
      score: (state.score ?? 0) + 1,
      mobileNumbers: state.mobileNumbers,
    );
  }

  void clearAll() {
    state = User(
      name: state.name,
      age: state.age,
      score: 0,
      mobileNumbers: [],
    );
  }

  void addMobileNumber(String mobileNumber) {
    final updatedNumbers = [...?state.mobileNumbers, mobileNumber];
    state = User(
      name: state.name,
      age: state.age,
      score: state.score,
      mobileNumbers: updatedNumbers,
    );
  }
}

final userProvider = StateNotifierProvider<UserNotifier, User>((ref) {
  return UserNotifier();
});

// Simulated message stream
Stream<List<String>> messageStream() async* {
  await Future.delayed(Duration(seconds: 1)); // Simulate initial delay
  yield ["Hello", "World"];
  await Future.delayed(Duration(seconds: 2));
  yield ["Hello", "Riverpod"];
  await Future.delayed(Duration(seconds: 2));
  yield ["Stream", "Provider", "Example"];
}

// StreamProvider
final messagesProvider = StreamProvider<List<String>>((ref) {
  return messageStream();
});

class User {
  String name;
  int age;
  int? score;
  List<String>? mobileNumbers;

  User({
    required this.name,
    required this.age,
    this.score = 0,
    this.mobileNumbers,
  });
}

late final UserViewModel userViewModel;

const ProviderScope(
    child: MyApp(),
  )*/
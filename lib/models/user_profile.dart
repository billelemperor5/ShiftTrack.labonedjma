import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String? firstName;

  @HiveField(1)
  String? lastName;

  @HiveField(2)
  String? companyName;

  @HiveField(3)
  String? logoPath;

  @HiveField(4)
  bool isFirstLaunchDone;

  @HiveField(5)
  String locale;

  @HiveField(6)
  List<int> workDays;

  @HiveField(7)
  String defaultCheckIn;

  @HiveField(8)
  String defaultCheckOut;

  @HiveField(9, defaultValue: 'light')
  String themeMode;

  @HiveField(10, defaultValue: 30)
  int breakDuration; // in minutes

  @HiveField(11, defaultValue: false)
  bool isBreakPaid;

  @HiveField(12, defaultValue: false)
  bool faceCheckinEnabled;

  @HiveField(13, defaultValue: false)
  bool notificationsEnabled;

  @HiveField(14, defaultValue: [6, 7, 1, 2, 3, 4])
  List<int> notificationWorkDays;

  UserProfile({
    this.firstName,
    this.lastName,
    this.companyName,
    this.logoPath,
    this.isFirstLaunchDone = false,
    this.locale = 'fr',
    this.workDays = const [1, 2, 3, 4, 5], // DateTime.monday = 1
    this.defaultCheckIn = "08:00",
    this.defaultCheckOut = "16:00",
    this.themeMode = 'light',
    this.breakDuration = 30,
    this.isBreakPaid = false,
    this.faceCheckinEnabled = false,
    this.notificationsEnabled = false,
    this.notificationWorkDays = const [6, 7, 1, 2, 3, 4],
  });
}

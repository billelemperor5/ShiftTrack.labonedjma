import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/hive_service.dart';

class AppProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  String _tempTheme = 'light';

  UserProfile? get userProfile => _userProfile;
  bool get isFirstLaunch =>
      _userProfile == null || !_userProfile!.isFirstLaunchDone;
  String get currentLocale => _userProfile?.locale ?? 'ar';
  String get currentTheme => _userProfile?.themeMode ?? _tempTheme;

  AppProvider() {
    _loadUser();
  }

  void refresh() => _loadUser();

  void _loadUser() {
    final box = HiveService.getUserBox();
    if (box.isNotEmpty) {
      _userProfile = box.getAt(0);
    }
    notifyListeners();
  }

  Future<void> setZkUserProfile({
    required String firstName,
    required String lastName,
    required String department,
    String? matricule,
  }) async {
    final profile = _userProfile ??
        UserProfile(
          firstName: firstName,
          lastName: lastName,
          companyName: department,
          isFirstLaunchDone: true,
          defaultCheckIn: "08:00",
          defaultCheckOut: "17:00",
          logoPath: 'assets/images/official_logo.jpg',
        );
    profile.firstName = firstName;
    profile.lastName = lastName;
    profile.companyName = department;
    profile.isFirstLaunchDone = true;
    if (profile.logoPath == null || profile.logoPath!.isEmpty) {
      profile.logoPath = 'assets/images/official_logo.jpg';
    }
    await saveProfile(profile);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final box = HiveService.getUserBox();
    if (box.isEmpty) {
      await box.add(profile);
    } else {
      await box.putAt(0, profile);
    }
    _userProfile = profile;
    notifyListeners();
  }

  bool get isLoggedIn => _userProfile != null && _userProfile!.isFirstLaunchDone;

  Future<void> logout() async {
    final box = HiveService.getUserBox();
    await box.clear();
    _userProfile = null;
    notifyListeners();
  }

  Future<void> changeTheme(String themeMode) async {
    if (_userProfile != null) {
      _userProfile!.themeMode = themeMode;
      final box = HiveService.getUserBox();
      await box.putAt(0, _userProfile!);
    } else {
      _tempTheme = themeMode;
    }
    notifyListeners();
  }
}

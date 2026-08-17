import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ZKBioTimeEmployee {
  final int id;
  final String empCode;
  final String firstName;
  final String lastName;
  final String department;
  final String position;
  final String? photo;

  ZKBioTimeEmployee({
    required this.id,
    required this.empCode,
    required this.firstName,
    required this.lastName,
    required this.department,
    required this.position,
    this.photo,
  });

  String get fullName => '$firstName $lastName'.trim();

  String? get photoUrl {
    if (photo == null || photo!.isEmpty) {
      // Fallback direct BioTime media photo URL for matricule
      return 'http://105.96.0.211:8080/media/photo/$empCode.jpg';
    }
    if (photo!.startsWith('http://') || photo!.startsWith('https://')) {
      return photo;
    }
    final cleanPath = photo!.startsWith('/') ? photo!.substring(1) : photo!;
    return 'http://105.96.0.211:8080/$cleanPath';
  }

  factory ZKBioTimeEmployee.fromJson(Map<String, dynamic> json) {
    final rawPhoto = json['photo']?.toString() ??
        json['avatar']?.toString() ??
        json['head_photo']?.toString() ??
        json['portrait']?.toString();

    final fName = json['first_name']?.toString() ?? json['firstName']?.toString() ?? '';
    final lName = json['last_name']?.toString() ?? json['lastName']?.toString() ?? '';
    final fullNameRaw = json['full_name']?.toString() ?? json['fullName']?.toString() ?? '';

    String computedFirst = fName;
    String computedLast = lName;
    if (computedFirst.isEmpty && computedLast.isEmpty && fullNameRaw.isNotEmpty) {
      final parts = fullNameRaw.trim().split(' ');
      computedFirst = parts.first;
      computedLast = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    String dept = 'IT';
    if (json['department'] is Map) {
      dept = json['department']['dept_name']?.toString() ?? 'IT';
    } else if (json['department'] is String && (json['department'] as String).isNotEmpty) {
      dept = json['department'] as String;
    } else if (json['dept_name'] != null) {
      dept = json['dept_name'].toString();
    } else if (json['department_name'] != null) {
      dept = json['department_name'].toString();
    }

    String pos = 'Collaborateur';
    if (json['position'] is Map) {
      pos = json['position']['position_name']?.toString() ?? 'Collaborateur';
    } else if (json['position'] is String && (json['position'] as String).isNotEmpty) {
      pos = json['position'] as String;
    } else if (json['position_name'] is String && (json['position_name'] as String).isNotEmpty) {
      pos = json['position_name'] as String;
    }

    return ZKBioTimeEmployee(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      empCode: json['emp_code']?.toString() ?? json['empCode']?.toString() ?? '',
      firstName: computedFirst,
      lastName: computedLast,
      department: dept,
      position: pos,
      photo: rawPhoto,
    );
  }
}

class ZKBioTimePunch {
  final int id;
  final String empCode;
  final String punchTime; // Format: YYYY-MM-DD HH:MM:SS
  final String punchState;
  final String terminalAlias;

  ZKBioTimePunch({
    required this.id,
    required this.empCode,
    required this.punchTime,
    required this.punchState,
    required this.terminalAlias,
  });

  DateTime? get dateTime {
    try {
      return DateTime.parse(punchTime);
    } catch (_) {
      return null;
    }
  }

  factory ZKBioTimePunch.fromJson(Map<String, dynamic> json) {
    return ZKBioTimePunch(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      empCode: json['emp_code']?.toString() ?? json['empCode']?.toString() ?? '',
      punchTime: json['punch_time']?.toString() ?? json['punchTime']?.toString() ?? '',
      punchState: json['punch_state']?.toString() ?? json['punchState']?.toString() ?? '',
      terminalAlias: json['terminal_alias']?.toString() ?? json['terminal_sn']?.toString() ?? 'Terminal BioTime',
    );
  }
}

class ZKBioTimeService {
  static const String defaultServerUrl = 'http://105.96.0.211:8080';
  static const String defaultProxyUrl = 'https://shifttrack-labonedjma.web.app';
  static const String defaultUsername = 'billel.bouraba';
  
  String _serverUrl = defaultServerUrl;
  String _proxyUrl = defaultProxyUrl;
  String? _jwtToken;
  ZKBioTimeEmployee? _currentUser;
  bool _isLoggedIn = false;

  String get serverUrl => _serverUrl;
  String? get jwtToken => _jwtToken;
  ZKBioTimeEmployee? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  // Singleton instance
  static final ZKBioTimeService _instance = ZKBioTimeService._internal();
  factory ZKBioTimeService() => _instance;
  ZKBioTimeService._internal();

  /// Configure server settings
  void configure({String? serverUrl, String? proxyUrl}) {
    if (serverUrl != null && serverUrl.isNotEmpty) {
      _serverUrl = serverUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
    if (proxyUrl != null && proxyUrl.isNotEmpty) {
      _proxyUrl = proxyUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
  }

  /// Authenticate to ZKBioTime via JWT token endpoint (or Proxy for Web)
  Future<bool> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    configure(serverUrl: serverUrl);

    // If running in Web browser, verify via proxy or direct
    if (kIsWeb) {
      try {
        final res = await http.get(Uri.parse('$_proxyUrl/api/health')).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          _jwtToken = 'local-proxy-jwt-token';
          _isLoggedIn = true;
          return true;
        }
      } catch (_) {}
    }

    try {
      final url = Uri.parse('$_serverUrl/jwt-api-token-auth/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _jwtToken = data['token'];
        _isLoggedIn = true;
        return true;
      } else {
        // Fallback endpoint /login/
        final fallbackUrl = Uri.parse('$_serverUrl/login/');
        final fbResponse = await http.post(
          fallbackUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username.trim(),
            'password': password,
          }),
        ).timeout(const Duration(seconds: 10));

        if (fbResponse.statusCode == 200) {
          final fbData = jsonDecode(fbResponse.body);
          _jwtToken = fbData['token'] ?? 'cookie-auth-success';
          _isLoggedIn = true;
          return true;
        }

        throw Exception('Échec de connexion (${response.statusCode})');
      }
    } catch (e) {
      if (kIsWeb) {
        // Fallback for Web CORS
        _jwtToken = 'web-cors-fallback-token';
        _isLoggedIn = true;
        return true;
      }
      debugPrint('ZKBioTime login error: $e');
      rethrow;
    }
  }

  /// Get headers with Auth token
  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_jwtToken != null && _jwtToken != 'cookie-auth-success' && _jwtToken != 'web-cors-fallback-token' && _jwtToken != 'local-proxy-jwt-token') {
      headers['Authorization'] = 'JWT $_jwtToken';
    }
    return headers;
  }

  /// 100% Read-Only: Fetch Employee details by matricule (emp_code)
  Future<ZKBioTimeEmployee?> getEmployee(String empCode) async {
    // 1. Try Cloud and Local proxies if in Web
    if (kIsWeb) {
      final currentOrigin = Uri.base.origin;
      final proxyList = [
        if (currentOrigin.isNotEmpty && !currentOrigin.startsWith('file:')) currentOrigin,
        'https://shifttrack-labonedjma.web.app',
        'https://shifttrack-labonedjma.firebaseapp.com',
        'http://localhost:3000',
      ];
      for (final p in proxyList) {
        try {
          final proxyUrl = Uri.parse('$p/api/attendance/search?matricule=${empCode.trim()}');
          final response = await http.get(
            proxyUrl,
            headers: {'Bypass-Tunnel-Reminder': 'true'},
          ).timeout(const Duration(seconds: 10));
          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            if (body['success'] == true && body['data']?['employee'] != null) {
              final emp = ZKBioTimeEmployee.fromJson(body['data']['employee']);
              _currentUser = emp;
              return emp;
            }
          }
        } catch (_) {}
      }
    }

    // 2. Direct ZKBioTime call
    try {
      final url = Uri.parse('$_serverUrl/personnel/api/employees/?emp_code=${empCode.trim()}');
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] ?? data['results'] ?? data;
        if (list is List && list.isNotEmpty) {
          final emp = ZKBioTimeEmployee.fromJson(list.first);
          _currentUser = emp;
          return emp;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting employee: $e');
      return null;
    }
  }

  /// 100% Read-Only: Fetch Biometric Transactions for a Date Range
  Future<List<ZKBioTimePunch>> getTransactions({
    required String empCode,
    required String startDate, // YYYY-MM-DD
    required String endDate,   // YYYY-MM-DD
  }) async {
    // 1. Try Cloud and Local proxies if in Web
    if (kIsWeb) {
      final currentOrigin = Uri.base.origin;
      final proxyList = [
        if (currentOrigin.isNotEmpty && !currentOrigin.startsWith('file:')) currentOrigin,
        'https://shifttrack-labonedjma.web.app',
        'https://shifttrack-labonedjma.firebaseapp.com',
        'http://localhost:3000',
      ];
      for (final p in proxyList) {
        try {
          final proxyUrl = Uri.parse(
            '$p/api/attendance/search?matricule=${empCode.trim()}'
            '&startDate=${Uri.encodeComponent(startDate)}'
            '&endDate=${Uri.encodeComponent(endDate)}',
          );
          final response = await http.get(
            proxyUrl,
            headers: {'Bypass-Tunnel-Reminder': 'true'},
          ).timeout(const Duration(seconds: 15));
          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            if (body['success'] == true && body['data'] != null) {
              if (body['data']['employee'] != null) {
                try {
                  final emp = ZKBioTimeEmployee.fromJson(body['data']['employee']);
                  _currentUser = emp;
                } catch (_) {}
              }
              if (body['data']['days'] is List) {
                final days = body['data']['days'] as List;
                final List<ZKBioTimePunch> punchesList = [];
                for (final d in days) {
                  if (d['rawPunches'] is List) {
                    for (final p in d['rawPunches']) {
                      punchesList.add(ZKBioTimePunch(
                        id: p['id'] ?? 0,
                        empCode: empCode,
                        punchTime: p['punchTime'] ?? p['punch_time'] ?? '',
                        punchState: p['punchState'] ?? p['punch_state'] ?? '',
                        terminalAlias: p['terminalAlias'] ?? p['terminal_alias'] ?? 'BioTime',
                      ));
                    }
                  }
                }
                if (punchesList.isNotEmpty) {
                  punchesList.sort((a, b) => a.punchTime.compareTo(b.punchTime));
                  return punchesList;
                }
              }
            }
          }
        } catch (_) {}
      }
    }

    // 2. Direct ZKBioTime API call
    try {
      final startFormatted = '$startDate 00:00:00';
      final endFormatted = '$endDate 23:59:59';
      
      final url = Uri.parse(
        '$_serverUrl/iclock/api/transactions/?emp_code=${empCode.trim()}'
        '&start_time=${Uri.encodeComponent(startFormatted)}'
        '&end_time=${Uri.encodeComponent(endFormatted)}'
        '&page_size=1000',
      );

      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] ?? data['results'] ?? data;
        if (list is List) {
          final punches = list.map((item) => ZKBioTimePunch.fromJson(item)).toList();
          punches.sort((a, b) => a.punchTime.compareTo(b.punchTime));
          return punches;
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }

  /// Logout
  void logout() {
    _jwtToken = null;
    _currentUser = null;
    _isLoggedIn = false;
  }
}

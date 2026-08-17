import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'zkbiotime_service.dart';

class FirestoreService {
  static const String projectId = 'shifttrack-labonedjma';
  static const String baseUrl =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  /// Converts a standard Map into Firestore REST API fields JSON
  static Map<String, dynamic> encodeFields(Map<String, dynamic> map) {
    final fields = <String, dynamic>{};
    map.forEach((key, value) {
      final encoded = _encodeValue(value);
      if (encoded != null) {
        fields[key] = encoded;
      }
    });
    return {'fields': fields};
  }

  static dynamic _encodeValue(dynamic val) {
    if (val == null) return {'nullValue': null};
    if (val is bool) return {'booleanValue': val};
    if (val is int) return {'integerValue': val.toString()};
    if (val is double) return {'doubleValue': val};
    if (val is String) return {'stringValue': val};
    if (val is List) {
      return {
        'arrayValue': {
          'values': val.map((item) => _encodeValue(item) ?? {'nullValue': null}).toList()
        }
      };
    }
    if (val is Map<String, dynamic>) {
      final inner = <String, dynamic>{};
      val.forEach((k, v) {
        final enc = _encodeValue(v);
        if (enc != null) inner[k] = enc;
      });
      return {'mapValue': {'fields': inner}};
    }
    return {'stringValue': val.toString()};
  }

  /// Decodes Firestore REST API document fields into standard Dart Map
  static Map<String, dynamic> decodeDocument(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>?;
    if (fields == null) return {};
    final result = <String, dynamic>{};
    fields.forEach((key, value) {
      result[key] = _decodeValue(value);
    });
    return result;
  }

  static dynamic _decodeValue(dynamic val) {
    if (val is! Map<String, dynamic>) return val;
    if (val.containsKey('stringValue')) return val['stringValue'];
    if (val.containsKey('integerValue')) return int.tryParse(val['integerValue'].toString()) ?? 0;
    if (val.containsKey('doubleValue')) return (val['doubleValue'] as num).toDouble();
    if (val.containsKey('booleanValue')) return val['booleanValue'] as bool;
    if (val.containsKey('nullValue')) return null;
    if (val.containsKey('arrayValue')) {
      final list = val['arrayValue']?['values'] as List?;
      if (list == null) return [];
      return list.map((item) => _decodeValue(item)).toList();
    }
    if (val.containsKey('mapValue')) {
      final fields = val['mapValue']?['fields'] as Map<String, dynamic>?;
      if (fields == null) return {};
      final map = <String, dynamic>{};
      fields.forEach((k, v) {
        map[k] = _decodeValue(v);
      });
      return map;
    }
    return null;
  }

  /// Get Employee from Firestore
  Future<ZKBioTimeEmployee?> getEmployee(String empCode) async {
    try {
      final clean = empCode.trim();
      final url = Uri.parse('$baseUrl/employees/$clean');
      final res = await http.get(url).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final doc = jsonDecode(res.body);
        final data = decodeDocument(doc);
        if (data.isNotEmpty) {
          return ZKBioTimeEmployee(
            id: data['id'] is int ? data['id'] : int.tryParse(data['id']?.toString() ?? '0') ?? 0,
            empCode: data['empCode']?.toString() ?? clean,
            firstName: data['firstName']?.toString() ?? '',
            lastName: data['lastName']?.toString() ?? '',
            department: data['department']?.toString() ?? 'Direction',
            position: data['position']?.toString() ?? 'Collaborateur',
            photo: data['photo']?.toString() ?? data['avatar']?.toString(),
          );
        }
      }
    } catch (e) {
      debugPrint('[FirestoreService] getEmployee error: $e');
    }
    return null;
  }

  /// Get Attendance Report & Punches from Firestore
  Future<Map<String, dynamic>?> getAttendanceData(String empCode) async {
    try {
      final clean = empCode.trim();
      final url = Uri.parse('$baseUrl/attendance/$clean');
      final res = await http.get(url).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final doc = jsonDecode(res.body);
        return decodeDocument(doc);
      }
    } catch (e) {
      debugPrint('[FirestoreService] getAttendanceData error: $e');
    }
    return null;
  }

  /// Save Employee to Firestore
  Future<bool> saveEmployee(ZKBioTimeEmployee emp) async {
    try {
      final url = Uri.parse('$baseUrl/employees/${emp.empCode.trim()}');
      final payload = encodeFields({
        'id': emp.id,
        'empCode': emp.empCode,
        'firstName': emp.firstName,
        'lastName': emp.lastName,
        'fullName': emp.fullName,
        'department': emp.department,
        'position': emp.position,
        'photo': emp.photo ?? '',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final res = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[FirestoreService] saveEmployee error: $e');
      return false;
    }
  }

  /// Save Attendance Data to Firestore
  Future<bool> saveAttendanceData(String empCode, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/attendance/${empCode.trim()}');
      data['updatedAt'] = DateTime.now().toIso8601String();
      final payload = encodeFields(data);

      final res = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[FirestoreService] saveAttendanceData error: $e');
      return false;
    }
  }
}

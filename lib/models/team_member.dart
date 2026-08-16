import 'dart:convert';

class TeamMember {
  final String empCode;
  final String firstName;
  final String lastName;
  final String department;
  final String position;
  final String? photo;
  final DateTime addedAt;
  final String? ownerEmpCode;

  TeamMember({
    required this.empCode,
    required this.firstName,
    required this.lastName,
    required this.department,
    required this.position,
    this.photo,
    required this.addedAt,
    this.ownerEmpCode,
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : 'Matricule $empCode';
  }

  String? get photoUrl {
    if (photo == null || photo!.isEmpty) {
      return 'http://105.96.0.211:8080/media/photo/$empCode.jpg';
    }
    if (photo!.startsWith('http://') || photo!.startsWith('https://')) {
      return photo;
    }
    final cleanPath = photo!.startsWith('/') ? photo!.substring(1) : photo!;
    return 'http://105.96.0.211:8080/$cleanPath';
  }

  Map<String, dynamic> toJson() {
    return {
      'empCode': empCode,
      'firstName': firstName,
      'lastName': lastName,
      'department': department,
      'position': position,
      'photo': photo,
      'addedAt': addedAt.toIso8601String(),
      'ownerEmpCode': ownerEmpCode,
    };
  }

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      empCode: json['empCode']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      department: json['department']?.toString() ?? 'Général',
      position: json['position']?.toString() ?? 'Collaborateur',
      photo: json['photo']?.toString(),
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      ownerEmpCode: json['ownerEmpCode']?.toString(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory TeamMember.fromJsonString(String source) =>
      TeamMember.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

// lib/src/models/app_user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role; // student | teacher | parent | admin
  final String? schoolId;
  final String? photoUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Optional / future expansion
  final String? gender;
  final String? sex; // "M" | "F" (MoEYI reporting)
  final String? bio;
  final String? studentId;
  final String? gradeLevel;
  final String? classId;
  final String? className;
  final String? teacherDepartment;
  final String? homeroomClassId;
  final String? homeroomClassName;
  final List<SubjectAssignment>? subjectAssignments;
  final List<String>? childrenIds; // for parents
  final String? parentGuardianName;
  final String? parentGuardianPhone;
  final String? address;
  final DateTime? dateOfBirth;

  AppUser({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.schoolId,
    this.photoUrl,
    this.gender,
    this.sex,
    this.bio,
    this.studentId,
    this.gradeLevel,
    this.classId,
    this.className,
    this.teacherDepartment,
    this.homeroomClassId,
    this.homeroomClassName,
    this.subjectAssignments,
    this.childrenIds,
    this.createdAt,
    this.updatedAt,
    this.parentGuardianName,
    this.dateOfBirth,
    this.address,
    this.parentGuardianPhone,
  });

  /// ✅ Computed UI name
  String get displayName {
    if (firstName.isEmpty && lastName.isEmpty) return email;
    return "$firstName $lastName".trim();
  }

  /// ✅ Initials
  String get initials {
    String a = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String b = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return (a + b).isNotEmpty ? (a + b) : 'U';
  }

  int? get gradeLevelNumber {
    final raw = gradeLevel;
    if (raw == null || raw.trim().isEmpty) return null;
    return int.tryParse(raw);
  }

  /// ✅ Convert Firestore to Dart model
  factory AppUser.fromMap(String uid, Map<String, dynamic>? data) {
    final map = data ?? <String, dynamic>{};

    final Timestamp? cts = map['createdAt'] is Timestamp
        ? map['createdAt'] as Timestamp
        : null;
    final Timestamp? uts = map['updatedAt'] is Timestamp
        ? map['updatedAt'] as Timestamp
        : null;

    final Timestamp? dobTs =
        map['dateOfBirth'] is Timestamp ? map['dateOfBirth'] as Timestamp : null;

    final rawGradeLevel = map['gradeLevel'];
    final String? gradeLevel = rawGradeLevel == null
        ? null
        : rawGradeLevel.toString();

    final rawSex = map['sex']?.toString();
    final rawGender = map['gender']?.toString();
    final normalizedSex = (rawSex != null && rawSex.trim().isNotEmpty)
        ? rawSex
        : (rawGender == 'M' || rawGender == 'F')
            ? rawGender
            : null;

    final subjectAssignmentsRaw = map['subjectAssignments'];
    final subjectAssignments = subjectAssignmentsRaw is List
        ? subjectAssignmentsRaw
            .where((entry) => entry is Map)
            .map(
              (entry) => SubjectAssignment.fromMap(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList()
        : null;

    return AppUser(
      uid: uid,
      firstName: (map['firstName'] ?? "").toString(),
      lastName: (map['lastName'] ?? "").toString(),
      email: (map['email'] ?? "").toString(),
      phone: (map['phone'] ?? "").toString(),
      role: (map['role'] ?? "student").toString(),
      schoolId: map['schoolId'] as String?,
      photoUrl: map['photoUrl'],
      gender: map['gender'],
      sex: normalizedSex,
      bio: map['bio'],
      studentId: map['studentId'],
      gradeLevel: gradeLevel,
      classId: map['classId'] as String?,
      className: map['className'] as String?,
      teacherDepartment: map['teacherDepartment'],
      homeroomClassId: map['homeroomClassId'] as String?,
      homeroomClassName: map['homeroomClassName'] as String?,
      subjectAssignments: subjectAssignments,
      childrenIds: map['childrenIds'] != null
          ? List<String>.from(map['childrenIds'])
          : null,
      createdAt: cts?.toDate(),
      updatedAt: uts?.toDate(),

      // NEW: hydrate profile fields
      parentGuardianName: map['parentGuardianName'] as String?,
      parentGuardianPhone: map['parentGuardianPhone'] as String?,
      address: map['address'] as String?,
      dateOfBirth: dobTs?.toDate(),
    );
  }

  factory AppUser.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    return AppUser.fromMap(snap.id, snap.data());
  }

  /// ✅ Convert Dart back to Firestore
  Map<String, dynamic> toMap({bool includeTimestampsWhenMissing = true}) {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'role': role,
      'schoolId': schoolId,
      'photoUrl': photoUrl,
      'gender': gender,
      'sex': sex,
      'bio': bio,
      'studentId': studentId,
      'gradeLevel': gradeLevel,
      'classId': classId,
      'className': className,
      'teacherDepartment': teacherDepartment,
      'homeroomClassId': homeroomClassId,
      'homeroomClassName': homeroomClassName,
      'subjectAssignments': subjectAssignments
          ?.map((assignment) => assignment.toMap())
          .toList(),
      'childrenIds': childrenIds,

      // NEW: profile fields
      'parentGuardianName': parentGuardianName,
      'parentGuardianPhone': parentGuardianPhone,
      'address': address,
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,

      /// ✅ Timestamp strategy
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : (includeTimestampsWhenMissing
                ? FieldValue.serverTimestamp()
                : null),

      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? role,
    String? schoolId,
    String? photoUrl,
    String? gender,
    String? sex,
    String? bio,
    String? studentId,
    String? gradeLevel,
    String? classId,
    String? className,
    String? teacherDepartment,
    String? homeroomClassId,
    String? homeroomClassName,
    List<SubjectAssignment>? subjectAssignments,
    List<String>? childrenIds,
    DateTime? createdAt,
    DateTime? updatedAt,

    // 🔥 new profile fields
    String? parentGuardianName,
    String? parentGuardianPhone,
    String? address,
    DateTime? dateOfBirth,
  }) {
    return AppUser(
      uid: uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      schoolId: schoolId ?? this.schoolId,
      photoUrl: photoUrl ?? this.photoUrl,
      gender: gender ?? this.gender,
      sex: sex ?? this.sex,
      bio: bio ?? this.bio,
      studentId: studentId ?? this.studentId,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      teacherDepartment: teacherDepartment ?? this.teacherDepartment,
      homeroomClassId: homeroomClassId ?? this.homeroomClassId,
      homeroomClassName: homeroomClassName ?? this.homeroomClassName,
      subjectAssignments: subjectAssignments ?? this.subjectAssignments,
      childrenIds: childrenIds ?? this.childrenIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,

      // 🔥 new fields wired in
      parentGuardianName: parentGuardianName ?? this.parentGuardianName,
      parentGuardianPhone: parentGuardianPhone ?? this.parentGuardianPhone,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }

  @override
  String toString() {
    return "AppUser(uid: $uid, name: $displayName, email: $email, role: $role)";
  }
}

class SubjectAssignment {
  const SubjectAssignment({
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    this.gradeLevel,
  });

  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final int? gradeLevel;

  factory SubjectAssignment.fromMap(Map<String, dynamic> data) {
    final rawGradeLevel = data['gradeLevel'];
    final gradeLevel = rawGradeLevel is int
        ? rawGradeLevel
        : int.tryParse(rawGradeLevel?.toString() ?? '');

    return SubjectAssignment(
      classId: (data['classId'] ?? '').toString(),
      className: (data['className'] ?? '').toString(),
      subjectId: (data['subjectId'] ?? '').toString(),
      subjectName: (data['subjectName'] ?? '').toString(),
      gradeLevel: gradeLevel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'className': className,
      'gradeLevel': gradeLevel,
      'subjectId': subjectId,
      'subjectName': subjectName,
    };
  }
}

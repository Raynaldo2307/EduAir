// lib/src/models/app_user.dart

class AppUser {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role; // student | teacher | parent | admin
  final String? schoolId;
  final String? photoUrl;

  /// The school's default shift type — comes from the schools table via API.
  /// Controls which shift options are shown in the UI.
  /// Values: 'morning' | 'afternoon' | 'whole_day' | null
  final String? defaultShiftType;

  /// Whether the school operates on a shift system.
  /// If false, only 'whole_day' is relevant.
  final bool isShiftSchool;

  /// Student's current shift assignment for attendance:
  /// - 'morning'
  /// - 'afternoon'
  /// - 'whole_day'
  ///
  /// Used by AttendanceService to decide:
  /// - which shift doc to write ({dateKey}_{shiftType}_{uid})
  /// - what start time to use for early/late
  final String? currentShift;

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
    this.defaultShiftType,
    this.isShiftSchool = false,
    this.currentShift,
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

  // ─── Role Helpers ────────────────────────────────────────────────────────
  // Node JWT is the security layer. These are UI/UX guards only.
  // Use these everywhere instead of raw role string comparisons.
  bool get isStudent          => role == 'student';
  bool get isTeacher          => role == 'teacher';
  bool get isAdmin            => role == 'admin';
  bool get isPrincipal        => role == 'principal';
  bool get isParent           => role == 'parent';
  bool get isAdminOrPrincipal => isAdmin || isPrincipal;
  bool get isStaff            => isTeacher || isAdmin || isPrincipal;

  /// Convert a plain map (Node API or Firestore-free) to AppUser.
  factory AppUser.fromMap(String uid, Map<String, dynamic>? data) {
    final map = data ?? <String, dynamic>{};

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final cts   = parseDate(map['createdAt']);
    final uts   = parseDate(map['updatedAt']);
    final dobTs = parseDate(map['dateOfBirth']);

    final rawGradeLevel = map['gradeLevel'];
    final String? gradeLevel = rawGradeLevel?.toString();

    final rawSex = map['sex']?.toString();
    final rawGender = map['gender']?.toString();
    final normalizedSex = (rawSex != null && rawSex.trim().isNotEmpty)
        ? rawSex
        : (rawGender == 'M' || rawGender == 'F')
        ? rawGender
        : null;

    // NEW: shift – prefer currentShift, fall back to legacy shiftType if it exists
    final rawCurrentShift = map['currentShift']?.toString();
    final rawLegacyShift = map['shiftType']?.toString();
    final normalizedShift = _normalizeShiftType(
      rawCurrentShift ?? rawLegacyShift,
    );

    final subjectAssignmentsRaw = map['subjectAssignments'];
    final subjectAssignments = subjectAssignmentsRaw is List
        ? subjectAssignmentsRaw
              .whereType<Map>()
              .map(
                (entry) =>
                    SubjectAssignment.fromMap(Map<String, dynamic>.from(entry)),
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
      currentShift: normalizedShift,
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
      createdAt: cts,
      updatedAt: uts,

      // NEW: hydrate profile fields
      parentGuardianName: map['parentGuardianName'] as String?,
      parentGuardianPhone: map['parentGuardianPhone'] as String?,
      address: map['address'] as String?,
      dateOfBirth: dobTs,
    );
  }

  /// Convert AppUser to a plain map (for Node API or in-memory use).
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

      // NEW: shift fields
      'currentShift': currentShift,
      // Optional: also write legacy key for any old code or external tools
      //'shiftType': currentShift,

      // NEW: profile fields
      'parentGuardianName': parentGuardianName,
      'parentGuardianPhone': parentGuardianPhone,
      'address': address,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'createdAt':   createdAt?.toIso8601String(),
      'updatedAt':   updatedAt?.toIso8601String()
                     ?? DateTime.now().toIso8601String(),
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
    String? defaultShiftType,
    bool? isShiftSchool,
    String? currentShift,
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
      defaultShiftType: defaultShiftType ?? this.defaultShiftType,
      isShiftSchool: isShiftSchool ?? this.isShiftSchool,
      currentShift: currentShift ?? this.currentShift,
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
    return "AppUser(uid: $uid, name: $displayName, email: $email, role: $role, currentShift: $currentShift)";
  }

  /// Local normalizer so this file does not depend on attendance_models.dart.
  /// We keep only the 3 canonical forms we care about.
  static String? _normalizeShiftType(String? value) {
    if (value == null) return null;
    final v = value.trim().toLowerCase();
    if (v.isEmpty) return null;

    if (v == 'morning' || v == 'am' || v == 'a.m.') {
      return 'morning';
    }
    if (v == 'afternoon' || v == 'evening' || v == 'pm' || v == 'p.m.') {
      return 'afternoon';
    }
    if (v == 'whole_day' ||
        v == 'whole-day' ||
        v == 'wholeday' ||
        v == 'full_day' ||
        v == 'allday' ||
        v == 'all_day' ||
        v == 'full') {
      return 'whole_day';
    }

    // Unknown values → null; AttendanceService will treat null as "whole_day"
    return null;
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

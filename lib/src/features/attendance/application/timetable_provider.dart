import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/attendance/domain/timetable_entry.dart';

/// Returns the timetable for a given weekday (1 = Monday … 5 = Friday).
/// Demo data — replace with a real API call when the timetable endpoint is ready.
final timetableProvider = Provider.family<List<TimetableEntry>, int>(
  (ref, weekday) => _schedules[weekday] ?? [],
);

const _schedules = <int, List<TimetableEntry>>{
  // Monday
  1: [
    TimetableEntry(time: '07:15', subject: 'Mathematics'),
    TimetableEntry(time: '08:15', subject: 'English Language'),
    TimetableEntry(time: '09:15', subject: 'Biology'),
    TimetableEntry(time: '10:15', subject: 'Social Studies'),
    TimetableEntry(time: '11:15', subject: 'Physical Education'),
  ],
  // Tuesday
  2: [
    TimetableEntry(time: '07:15', subject: 'English Language'),
    TimetableEntry(time: '08:15', subject: 'Chemistry'),
    TimetableEntry(time: '09:15', subject: 'History'),
    TimetableEntry(time: '10:15', subject: 'Mathematics'),
    TimetableEntry(time: '11:15', subject: 'Geography'),
  ],
  // Wednesday
  3: [
    TimetableEntry(time: '07:15', subject: 'Biology'),
    TimetableEntry(time: '08:15', subject: 'Mathematics'),
    TimetableEntry(time: '09:15', subject: 'Principles of Business'),
    TimetableEntry(time: '10:15', subject: 'English Language'),
    TimetableEntry(time: '11:15', subject: 'Religious Education'),
  ],
  // Thursday
  4: [
    TimetableEntry(time: '07:15', subject: 'Social Studies'),
    TimetableEntry(time: '08:15', subject: 'Physics'),
    TimetableEntry(time: '09:15', subject: 'Mathematics'),
    TimetableEntry(time: '10:15', subject: 'English Language'),
    TimetableEntry(time: '11:15', subject: 'Information Technology'),
  ],
  // Friday
  5: [
    TimetableEntry(time: '07:15', subject: 'Geography'),
    TimetableEntry(time: '08:15', subject: 'English Language'),
    TimetableEntry(time: '09:15', subject: 'Chemistry'),
    TimetableEntry(time: '10:15', subject: 'Social Studies'),
    TimetableEntry(time: '11:15', subject: 'Visual Arts'),
  ],
};

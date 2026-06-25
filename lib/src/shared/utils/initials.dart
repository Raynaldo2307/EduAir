/// The single rule for turning a display name into avatar initials.
///
/// Every avatar in the app must derive initials from THIS function — not its own
/// `substring`/`[0]` logic. [UserAvatar] keys its colour off the initials string,
/// so if two screens computed initials differently ("SB" vs "S") the same person
/// would get a different colour per screen. One helper → one string → one colour.
///
/// Rule: first letter of the first word + first letter of the last word, upper
/// case. Single word → its first letter. Empty → 'U'.
String initialsFromName(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

// Import Flutter's UI toolkit — gives us Scaffold, Text, Icon, etc.
import 'package:flutter/material.dart';
// Import Riverpod — gives us ConsumerStatefulWidget and ref.watch/read
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import our global providers (userProvider, tokenStorageProvider)
import 'package:edu_air/src/core/app_providers.dart';
// Import our app theme (colors, radius values, text styles)
import 'package:edu_air/src/core/app_theme.dart';

// SettingsPage is a ConsumerStatefulWidget because it needs BOTH:
//   - Local state (the toggle switches) → StatefulWidget
//   - Riverpod access (to read the logged-in user) → ConsumerWidget
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key}); // const constructor — better performance

  @override
  // Creates the mutable state object paired with this widget
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

// _SettingsPageState holds all the logic and local UI state for SettingsPage
class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Local toggle — true means push notifications are ON by default
  bool _notifications = true;
  // Local toggle — false means dark mode is OFF by default
  bool _darkMode = false;

  // Helper: converts a numeric schoolId string to a human-readable school name
  String _schoolName(String? schoolId) {
    switch (schoolId) { // Check which school ID the user belongs to
      case '1':         // School ID 1 → Papine High School
        return 'Papine High School';
      case '2':         // School ID 2 → Maggotty High School
        return 'Maggotty High School';
      case '3':         // School ID 3 → St. Catherine High School
        return 'St. Catherine High School';
      default:          // Unknown ID → fallback to generic name
        return 'EduAir School';
    }
  }

  // Handles the full logout flow — async because it awaits a dialog and storage deletion
  Future<void> _handleLogout() async {
    // Show a confirmation dialog before logging out
    final confirmed = await showDialog<bool>(
      context: context, // The current screen's BuildContext
      builder: (_) => AlertDialog( // Build the dialog widget
        shape: RoundedRectangleBorder(
          // Rounded corners using the theme's large radius value
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text('Log Out'),                             // Dialog title
        content: const Text('Are you sure you want to log out?'), // Dialog body text
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel → returns false
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),  // Confirm → returns true
            child: const Text('Log Out', style: TextStyle(color: Colors.red)), // Red = danger action
          ),
        ],
      ),
    );

    // If user tapped Cancel (or dismissed the dialog), OR the widget is gone → do nothing
    if (confirmed != true || !mounted) return;

    // Read the token storage service from Riverpod (does NOT rebuild on change)
    final tokenStorage = ref.read(tokenStorageProvider);
    // Delete the saved JWT token from secure device storage
    await tokenStorage.delete();
    // Clear the current user from the global Riverpod state (sets it to null)
    ref.read(userProvider.notifier).state = null;

    // Safety check — make sure the widget is still in the tree before navigating
    if (!mounted) return;
    // Navigate to onboarding, replacing this screen so user cannot press Back to return
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  @override
  // build() describes the full UI — reruns whenever setState() or ref.watch() triggers
  Widget build(BuildContext context) {
    // Watch userProvider — this widget rebuilds automatically if the user changes
    final user = ref.watch(userProvider);
    // Get role string, default to empty if user is null
    final role = user?.role ?? '';
    // True for admin/principal — used to show/hide the SCHOOL section
    final isAdminOrPrincipal = role == 'admin' || role == 'principal';
    // Display name from user model, fallback to 'User'
    final name = user?.displayName ?? 'User';
    // Email from user model, fallback to dash
    final email = user?.email ?? '—';
    // Convert schoolId number to readable school name
    final school = _schoolName(user?.schoolId);

    return Scaffold(
      // Light gray background — makes the white card sections stand out
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea( // Keeps content away from the status bar and home indicator
        child: SingleChildScrollView( // Makes the entire page scrollable
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align all children to the left
            children: [

              // ── Title bar ──────────────────────────────────────────
              // "Settings" heading at the top of the screen
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8), // left=20, top=20, right=20, bottom=8
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 28,               // Large heading size
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary, // Dark text from theme
                  ),
                ),
              ),

              // ── Profile header card ────────────────────────────────
              // White card showing avatar, name, role badge, school, and email
              Container(
                width: double.infinity,
                margin : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color :  AppTheme.white,
                  borderRadius : BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color:Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2)
                    ),
                  ],
                ),
                child :  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
              
                  // Space above and below content
                   
                      children: [
                        // Stack lets us layer the camera badge on top of the avatar circle
                        Stack(
                          children: [
                            // The circular profile picture
                            CircleAvatar(
                              radius: 40, // Circle size = 80px diameter
                              backgroundColor: AppTheme.secondaryColor, // Shown if no photo
                              // Load photo from URL if available, otherwise null
                              backgroundImage: user?.photoUrl != null
                                  ? NetworkImage(user!.photoUrl!) // Remote image URL
                                  : null,                          // No image — show icon child instead
                              // Show a person icon when there's no photo URL
                              child: user?.photoUrl == null
                                  ? const Icon(
                                      Icons.person_outline,
                                      size: 40,
                                      color: AppTheme.primaryColor,
                                    )
                                  : null, // Photo exists → no child needed (image shows behind)
                            ),

                            // Camera icon badge — overlaid at the bottom-right of the avatar
                            Positioned(
                              bottom: 0, // Anchored to bottom of Stack
                              right: 0,  // Anchored to right of Stack
                              child: Container(
                                padding: const EdgeInsets.all(4), // Small padding around the icon
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor, // Primary color circle
                                  shape: BoxShape.circle,        // Makes the container circular
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 14,           // Small icon to fit the badge
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12), // Vertical space between avatar and name

                        // User's full display name
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 6), // Space between name and role badge

                        // Role badge pill — e.g. "ADMIN" or "TEACHER"
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, // Wide horizontal padding makes it look like a pill
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            // Very faint primary color background (10% opacity)
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20), // Fully rounded pill shape
                          ),
                          child: Text(
                            role.toUpperCase(), // e.g. "admin" becomes "ADMIN"
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor, // Solid primary color text
                              letterSpacing: 1.2,            // Spread letters for a badge look
                            ),
                          ),
                        ),

                        const SizedBox(height: 6), // Space between badge and school name

                        // School name in muted gray
                        Text(
                          school,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.grey, // De-emphasized gray
                          ),
                        ),

                        const SizedBox(height: 2), // Tiny gap between school and email

                        // Email address in smaller gray text
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
              ),

              // ── MY ACCOUNT ─────────────────────────────────────────
              // Gray uppercase label above this section
              _SectionLabel('MY ACCOUNT'),
              // White card containing Edit Profile and Change Password rows
              _SectionCard(
                children: [
                  _SettingsRow(
                    icon: Icons.person_outline,          // Person silhouette icon
                    iconBg: const Color(0xFFE8F2FF),     // Light blue background box
                    iconColor: const Color(0xFF4A7CFF),  // Blue icon color
                    label: 'Edit Profile',
                    onTap: () => _showComingSoon(context, 'Edit Profile'), // Placeholder for now
                  ),
                  const _Divider(), // Thin separator line between the two rows

                  _SettingsRow(
                    icon: Icons.lock_outline,            // Padlock icon
                    iconBg: const Color(0xFFF5EBFF),     // Light purple background box
                    iconColor: const Color(0xFF9B51E0),  // Purple icon color
                    label: 'Change Password',
                    onTap: () => _showComingSoon(context, 'Change Password'), // Placeholder
                  ),
                ],
              ),

              // ── SCHOOL (admin / principal only) ────────────────────
              // This entire block is hidden from teachers and students
              if (isAdminOrPrincipal) ...[
                _SectionLabel('SCHOOL'), // Only shown if user is admin or principal

                _SectionCard(
                  children: [
                    _SettingsRow(
                      icon: Icons.school_outlined,           // School building icon
                      iconBg: const Color(0xFFE6F6F3),       // Light teal background box
                      iconColor: const Color(0xFF2D9CDB),    // Blue icon color
                      label: 'School Information',
                      onTap: () =>
                          _showComingSoon(context, 'School Information'), // Placeholder
                    ),
                    const _Divider(), // Separator line between rows

                    _SettingsRow(
                      icon: Icons.schedule_outlined,         // Clock/schedule icon
                      iconBg: const Color(0xFFF8F2DC),       // Light amber background box
                      iconColor: const Color(0xFFB7791F),    // Amber/brown icon color
                      label: 'Shift Settings',
                      onTap: () => _showComingSoon(context, 'Shift Settings'), // Placeholder
                    ),
                  ],
                ),
              ],

              // ── PREFERENCES ────────────────────────────────────────
              _SectionLabel('PREFERENCES'), // Gray label above toggles

              // White card with Switch toggles (not tappable rows with chevrons)
              _SectionCard(
                children: [
                  _ToggleRow(
                    icon: Icons.notifications_outlined,    // Bell icon
                    iconBg: const Color(0xFFFDE9EC),       // Light pink background box
                    iconColor: const Color(0xFFE65D7B),    // Pink/red icon
                    label: 'Push Notifications',
                    value: _notifications,                 // Current true/false state
                    // When user flips the switch, update local state → UI rebuilds
                    onChanged: (v) => setState(() => _notifications = v),
                  ),
                  const _Divider(), // Separator between the two toggles

                  _ToggleRow(
                    icon: Icons.dark_mode_outlined,        // Moon icon
                    iconBg: const Color(0xFFEFF4FF),       // Light blue-gray background box
                    iconColor: const Color(0xFF4A5568),    // Dark gray icon
                    label: 'Dark Mode',
                    value: _darkMode,                      // Current true/false state
                    // When user flips the switch, update local state → UI rebuilds
                    onChanged: (v) => setState(() => _darkMode = v),
                  ),
                ],
              ),

              // ── SUPPORT ────────────────────────────────────────────
              _SectionLabel('SUPPORT'), // Gray label above support rows

              _SectionCard(
                children: [
                  _SettingsRow(
                    icon: Icons.help_outline,              // Question mark icon
                    iconBg: const Color(0xFFE6F6F3),       // Light teal background box
                    iconColor: const Color(0xFF2D9CDB),    // Blue icon
                    label: 'Help & FAQ',
                    onTap: () => _showComingSoon(context, 'Help & FAQ'), // Placeholder
                  ),
                  const _Divider(), // Separator between rows

                  _SettingsRow(
                    icon: Icons.info_outline,              // Info circle icon
                    iconBg: const Color(0xFFE8F2FF),       // Light blue background box
                    iconColor: const Color(0xFF4A7CFF),    // Blue icon
                    label: 'About EduAir',
                    onTap: () => _showComingSoon(context, 'About EduAir'), // Placeholder
                  ),
                ],
              ),

              // ── LOG OUT ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), // Extra bottom padding for scroll comfort
                child: SizedBox(
                  width: double.infinity, // Button stretches to full screen width
                  height: 52,             // Fixed button height
                  child: OutlinedButton.icon(
                    onPressed: _handleLogout, // Triggers the logout confirmation dialog
                    icon: const Icon(Icons.logout, color: Colors.red), // Red logout icon
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.red,          // Red text signals a destructive action
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      // Red border outline with no fill background
                      side: const BorderSide(color: Colors.red, width: 1.4),
                      shape: RoundedRectangleBorder(
                        // Rounded corners to match the rest of the card UI
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Utility: shows a snackbar at the bottom saying this feature isn't ready yet
  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature — coming soon')));
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

// Small gray uppercase text shown above each group of settings rows (e.g. "MY ACCOUNT")
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text); // Takes the label string as a positional argument
  final String text;              // The text to display

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6), // Top padding creates visual separation from card above
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,                // Small label text
          fontWeight: FontWeight.w600, // Semi-bold so it's readable but not dominant
          color: AppTheme.grey,        // Gray — visually de-emphasized
          letterSpacing: 0.8,          // Slight letter spacing gives it a label feel
        ),
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

// White rounded container that wraps a group of settings rows into one visual block
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children}); // Requires the list of rows to display
  final List<Widget> children;                   // The rows stacked inside this card

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16), // Left/right margin so card doesn't touch screen edges
      decoration: BoxDecoration(
        color: AppTheme.white,                                      // White card background
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), // Very subtle shadow (4% opacity black)
            blurRadius: 10,                               // How soft/spread the shadow is
            offset: const Offset(0, 2),                   // Shadow drops 2px below the card
          ),
        ],
      ),
      child: Column(children: children), // Stack all the rows vertically inside the card
    );
  }
}

// ─── Settings Row ─────────────────────────────────────────────────────────────

// A tappable list row with: colored icon box | label text | right chevron arrow
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,      // The icon to show (e.g. Icons.person_outline)
    required this.iconBg,    // Background color for the icon box
    required this.iconColor, // Color of the icon itself
    required this.label,     // Text label for this row
    required this.onTap,     // What to do when the row is tapped
  });

  final IconData icon;      // Material Design icon
  final Color iconBg;       // Light-colored square background behind the icon
  final Color iconColor;    // Usually a darker shade of iconBg for contrast
  final String label;       // Row label text (e.g. "Edit Profile")
  final VoidCallback onTap; // Callback with no arguments and no return value

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // Run the tap handler when the user taps this row
      // Clip the ink ripple effect to match the card's rounded corners
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Row padding
        child: Row(
          children: [
            // Colored rounded-square icon box
            Container(
              width: 34,  // Fixed square width
              height: 34, // Fixed square height
              decoration: BoxDecoration(
                color: iconBg,                              // Light-colored background
                borderRadius: BorderRadius.circular(9),     // Slightly rounded corners on the box
              ),
              child: Icon(icon, color: iconColor, size: 18), // Icon inside the box
            ),

            const SizedBox(width: 14), // Horizontal gap between icon and label

            // Label — Expanded so it fills remaining space and pushes chevron to the right
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500, // Medium weight — readable but not heavy
                  color: AppTheme.textPrimary,
                ),
              ),
            ),

            // Chevron arrow on the right — signals this row navigates somewhere
            const Icon(Icons.chevron_right, color: AppTheme.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Toggle Row ───────────────────────────────────────────────────────────────

// Like _SettingsRow but with a Switch at the end instead of a chevron
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,       // The icon to show
    required this.iconBg,     // Background color for the icon box
    required this.iconColor,  // Color of the icon
    required this.label,      // Row text label
    required this.value,      // Current on/off state of the Switch
    required this.onChanged,  // Called with the new bool value when the switch is flipped
  });

  final IconData icon;               // Material Design icon
  final Color iconBg;                // Light background for icon box
  final Color iconColor;             // Icon color
  final String label;                // Label text
  final bool value;                  // true = switch is ON, false = switch is OFF
  final ValueChanged<bool> onChanged; // Called with new value when toggled

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Slightly less vertical padding than SettingsRow
      child: Row(
        children: [
          // Colored rounded-square icon box (identical structure to _SettingsRow)
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),

          const SizedBox(width: 14), // Gap between icon and label

          // Label — Expanded pushes the Switch to the far right
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // The actual toggle switch widget
          Switch(
            value: value,               // Reflects current on/off state from parent
            onChanged: onChanged,       // Fires when user flips the switch
            activeThumbColor: AppTheme.primaryColor,   // Thumb (circle) color when ON
            activeTrackColor: AppTheme.secondaryColor, // Track (bar) color when ON
          ),
        ],
      ),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────

// A thin horizontal separator line between rows inside a _SectionCard
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,                        // Only takes up 1px in the layout
      indent: 64,                       // Starts at 64px from the left (aligns with label text, not icon)
      endIndent: 16,                    // Ends 16px from the right edge
      color: Color(0xFFEEEEEE),         // Very light gray — subtle, not harsh
    );
  }
}

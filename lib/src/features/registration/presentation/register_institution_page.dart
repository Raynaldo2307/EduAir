import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';

/// Public school-registration wizard (web-first — see D5 in the registration
/// blueprint). A principal onboards their whole institution here.
///
/// Design intent: calm, guided, premium — a Jamaican principal should feel
/// welcomed and proud, never overwhelmed. So: a warm branded hero on the left,
/// a calm one-step-at-a-time form on the right, generous whitespace, soft
/// motion between steps, and a celebratory payoff at the end.
///
/// MOCK ONLY — answers live in local state; nothing is sent to a backend yet.
class RegisterInstitutionPage extends ConsumerStatefulWidget {
  const RegisterInstitutionPage({super.key});

  @override
  ConsumerState<RegisterInstitutionPage> createState() =>
      _RegisterInstitutionPageState();
}

class _RegisterInstitutionPageState
    extends ConsumerState<RegisterInstitutionPage> {
  static const _totalSteps = 4;

  int _step = 0;
  bool _done = false;
  bool _submitting = false;
  bool _obscurePassword = true;

  // ── Step 1: school ──
  final _schoolName = TextEditingController();
  String? _parish;

  // ── Step 2: operating model ──
  // Default to the most common type; value matches the backend enum.
  String _institutionType = 'secondary';
  String _operatingModel = 'whole_day';

  // ── Step 3: campus ──
  double _geofenceRadius = 200;

  // ── Step 4: administrator account ──
  final _adminFirstName = TextEditingController();
  final _adminLastName = TextEditingController();
  final _adminEmail = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  // Jamaica's 14 parishes — a principal picks theirs.
  static const _parishes = [
    'Kingston', 'St. Andrew', 'St. Catherine', 'Clarendon', 'Manchester',
    'St. Elizabeth', 'Westmoreland', 'Hanover', 'St. James', 'Trelawny',
    'St. Ann', 'St. Mary', 'Portland', 'St. Thomas',
  ];

  // Wire values MUST match the backend `schools.school_type` enum
  // (ALLOWED_SCHOOL_TYPES) so they join with no translation — the same
  // wire-value discipline as the bell slot-types.
  static const _institutionTypes = [
    (v: 'basic', l: 'Basic School'),
    (v: 'primary', l: 'Primary School'),
    (v: 'prep', l: 'Preparatory School'),
    (v: 'secondary', l: 'High / Secondary School'),
    (v: 'all_age', l: 'All-Age School'),
    (v: 'heart_nta', l: 'Vocational / HEART NSTA'),
    (v: 'other', l: 'Other'),
  ];

  static const _operatingModels = [
    (v: 'whole_day', l: 'Whole-Day', d: 'One session, everyone on the same hours.'),
    (v: 'multi_shift', l: 'Multi-Shift', d: 'A morning body and an afternoon body share the campus.'),
    (v: 'flexible', l: 'Flexible / Block', d: 'Block sessions instead of fixed bells (e.g. HEART workshops).'),
  ];

  @override
  void dispose() {
    _schoolName.dispose();
    _adminFirstName.dispose();
    _adminLastName.dispose();
    _adminEmail.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  // Validate just the fields on the current step before advancing.
  bool _stepValid() {
    switch (_step) {
      case 0:
        return _schoolName.text.trim().isNotEmpty && _parish != null;
      case 3: // administrator account
        return _adminFirstName.text.trim().isNotEmpty &&
            _adminLastName.text.trim().isNotEmpty &&
            _adminEmail.text.contains('@') &&
            _password.text.length >= 8 &&
            _password.text == _confirmPassword.text;
      default:
        return true; // steps 2 & 3 have sensible defaults
    }
  }

  // The schema stores a boolean + a default shift, not a 3-way model.
  // TODO: add an `operating_model` column so Flexible/Block is first-class —
  // for now it folds into whole-day (but is captured here, not lost silently).
  (bool isShift, String defaultShift) _shiftFromModel() {
    switch (_operatingModel) {
      case 'multi_shift':
        return (true, 'morning');
      default: // whole_day + flexible
        return (false, 'whole_day');
    }
  }

  Future<void> _next() async {
    if (!_stepValid()) {
      final msg = _step == 0
          ? 'Please enter your school name and parish.'
          : 'Complete all fields — password must be 8+ characters and match.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      return;
    }
    await _submit(); // last step
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final (isShift, defaultShift) = _shiftFromModel();
    try {
      await ref.read(registrationApiRepositoryProvider).registerSchool(
            name: _schoolName.text.trim(),
            parish: _parish!,
            schoolType: _institutionType,
            isShiftSchool: isShift,
            defaultShiftType: defaultShift,
            radiusMeters: _geofenceRadius.round(),
            adminFirstName: _adminFirstName.text.trim(),
            adminLastName: _adminLastName.text.trim(),
            adminEmail: _adminEmail.text.trim(),
            password: _password.text,
          );
      if (mounted) setState(() { _done = true; _submitting = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errMessage(e))),
        );
      }
    }
  }

  // Surface the server's {message} (e.g. duplicate-school 409) when present.
  String _errMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return 'Could not reach the server. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final form = _done
                ? _SuccessPanel(
                    schoolName: _schoolName.text.trim(),
                    adminEmail: _adminEmail.text.trim(),
                  )
                : _formPanel(cs);

            if (!isWide) {
              // Narrow: compact brand bar on top, form below.
              return Column(
                children: [
                  _CompactBrandBar(),
                  Expanded(child: form),
                ],
              );
            }
            // Wide: warm hero left, calm form right.
            return Row(
              children: [
                const Expanded(flex: 5, child: _HeroPanel()),
                Expanded(flex: 6, child: form),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── The form side ───────────────────────────────────────────────────────────
  Widget _formPanel(ColorScheme cs) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProgressHeader(step: _step, total: _totalSteps),
              const SizedBox(height: 28),

              // Soft motion between steps — the premium "alive" feel.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0.04, 0), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _stepContent(cs),
                ),
              ),

              const SizedBox(height: 32),
              _navButtons(cs),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 15, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text("Your school's information is private and secure.",
                      style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepContent(ColorScheme cs) {
    switch (_step) {
      case 0:  return _step1Identity(cs);
      case 1:  return _step2Model(cs);
      case 2:  return _step3Campus(cs);
      default: return _step4Admin(cs);
    }
  }

  // ── Step 1 ──
  Widget _step1Identity(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: "Let's start with your school",
            subtitle: 'The basics so we know who you are.'),
        const SizedBox(height: 20),
        _Field(
          controller: _schoolName,
          label: 'School name',
          icon: Icons.school_outlined,
          textCapitalization: TextCapitalization.words, // "papine high" → "Papine High"
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _parish,
          isExpanded: true,
          decoration: _dec('Parish', Icons.place_outlined),
          hint: const Text('Select your parish'),
          items: _parishes
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (v) => setState(() => _parish = v),
        ),
      ],
    );
  }

  // ── Step 2 ──
  Widget _step2Model(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: 'How does your school run?',
            subtitle: 'This shapes the whole app for your institution.'),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _institutionType,
          isExpanded: true,
          decoration: _dec('Institution type', Icons.account_balance_outlined),
          items: _institutionTypes
              .map((t) => DropdownMenuItem(value: t.v, child: Text(t.l)))
              .toList(),
          onChanged: (v) => setState(() => _institutionType = v ?? _institutionType),
        ),
        const SizedBox(height: 20),
        Text('Operating model',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
        const SizedBox(height: 8),
        ..._operatingModels.map((m) => _RadioCard(
              selected: _operatingModel == m.v,
              title: m.l,
              subtitle: m.d,
              onTap: () => setState(() => _operatingModel = m.v),
            )),
      ],
    );
  }

  // ── Step 3 ──
  Widget _step3Campus(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: 'Your campus',
            subtitle: 'So attendance can be tied to school grounds.'),
        const SizedBox(height: 20),
        // Map picker placeholder — real Google Maps widget lands later.
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined, size: 34, color: cs.onSurfaceVariant),
                const SizedBox(height: 8),
                Text('Drop a pin on your campus',
                    style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                Text('Map picker — coming soon',
                    style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Geofence radius',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
            const Spacer(),
            Text('${_geofenceRadius.round()} m',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary)),
          ],
        ),
        Slider(
          value: _geofenceRadius,
          min: 50, max: 1000, divisions: 19,
          label: '${_geofenceRadius.round()} m',
          onChanged: (v) => setState(() => _geofenceRadius = v),
        ),
        Text('How far from the centre still counts as "on campus".',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      ],
    );
  }

  // ── Step 4: administrator account ──
  Widget _step4Admin(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: 'Your administrator account',
            subtitle: "This is the login you'll use to run the school."),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _Field(
              controller: _adminFirstName, label: 'First name',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
            )),
            const SizedBox(width: 12),
            Expanded(child: _Field(
              controller: _adminLastName, label: 'Last name',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
            )),
          ],
        ),
        const SizedBox(height: 14),
        _Field(
          controller: _adminEmail, label: 'Administrator email',
          icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _Field(
          controller: _password, label: 'Password (8+ characters)',
          icon: Icons.lock_outline, obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined, size: 20),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 14),
        _Field(
          controller: _confirmPassword, label: 'Confirm password',
          icon: Icons.lock_outline, obscureText: _obscurePassword,
        ),
      ],
    );
  }

  // ── Nav buttons ──
  Widget _navButtons(ColorScheme cs) {
    final isLast = _step == _totalSteps - 1;
    return Row(
      children: [
        if (_step > 0 && !_submitting)
          TextButton(onPressed: _back, child: const Text('Back')),
        const Spacer(),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: _submitting ? null : _next,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isLast ? 'Finish setup' : 'Continue',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // Shared calm input decoration.
  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

// ─── Hero panel (warm, branded, Jamaican) ─────────────────────────────────────

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand lockup: white "breeze" air mark + the logo in a white badge
          // so it stays crisp against the gradient (the logo asset is built for
          // a white background).
          Row(
            children: [
              const Icon(Icons.air, color: Colors.white, size: 38),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset('assets/images/eduair_logo.png', width: 48, height: 48),
              ),
            ],
          ),
          const Spacer(),
          const Text('Built for\nJamaican schools.',
              style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, height: 1.1)),
          const SizedBox(height: 16),
          Text('Welcome, Principal. Let\'s get your school set up — it only takes a few minutes.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 16, height: 1.4)),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Your data is private and secure.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 13.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactBrandBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          const Icon(Icons.air, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Image.asset('assets/images/eduair_logo.png', width: 26, height: 26),
          ),
          const SizedBox(width: 10),
          const Text('Register your school',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Progress header ──────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step ${step + 1} of $total',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
        const SizedBox(height: 10),
        Row(
          children: List.generate(total, (i) {
            final filled = i <= step;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                height: 5,
                margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                decoration: BoxDecoration(
                  color: filled ? cs.primary : cs.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Small building blocks ────────────────────────────────────────────────────

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: cs.onSurface, height: 1.15)),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(fontSize: 14.5, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  /// Lets the keyboard auto-case input as it's typed — e.g. proper-case a
  /// school name. We never FORCE caps; we just help the user type it cleanly.
  final TextCapitalization textCapitalization;

  /// Masks input (passwords). The show/hide toggle is passed as [suffixIcon].
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _RadioCard extends StatelessWidget {
  const _RadioCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.06) : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? cs.primary : cs.onSurfaceVariant, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Success payoff ───────────────────────────────────────────────────────────

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({required this.schoolName, required this.adminEmail});
  final String schoolName;
  final String adminEmail;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: Icon(Icons.mark_email_unread_outlined, size: 46, color: cs.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Check your email',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: cs.onSurface, height: 1.2),
            ),
            const SizedBox(height: 12),
            Text(
              "We've sent an activation link to $adminEmail. Click it to activate "
              "${schoolName.isEmpty ? 'your school' : schoolName} — then log in and you're ready.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

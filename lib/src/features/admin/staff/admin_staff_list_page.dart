import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';
import 'package:edu_air/src/features/admin/staff/application/admin_staff_provider.dart';
import 'admin_staff_edit_page.dart';

class AdminStaffListPage extends ConsumerStatefulWidget {
  const AdminStaffListPage({super.key, this.onBackToHome});

  final VoidCallback? onBackToHome;

  @override
  ConsumerState<AdminStaffListPage> createState() => _AdminStaffListPageState();
}

class _AdminStaffListPageState extends ConsumerState<AdminStaffListPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppUser> _filter(List<AppUser> staff) {
    if (_query.isEmpty) return staff;
    final q = _query.toLowerCase();
    return staff.where((s) {
      return s.displayName.toLowerCase().contains(q) ||
          (s.teacherDepartment?.toLowerCase().contains(q) ?? false) ||
          s.email.toLowerCase().contains(q);
    }).toList();
  }

  void _openEditPage(AppUser? staff) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminStaffEditPage(staff: staff),
      ),
    );
    if (result == true) {
      ref.invalidate(schoolStaffProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              staff == null
                  ? 'Staff member added successfully'
                  : 'Staff record updated',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final staffAsync = ref.watch(schoolStaffProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: widget.onBackToHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBackToHome,
              )
            : null,
        title: Text(
          'Manage Staff',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 40, color: cs.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(
                  'Failed to load staff',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(schoolStaffProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (staff) {
          final filtered = _filter(staff);

          return Column(
            children: [
              // Search bar + count
              Container(
                color: cs.surface,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v.trim()),
                      style: TextStyle(fontSize: 14, color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search by name, department or email…',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: cs.onSurfaceVariant,
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: cs.onSurfaceVariant, size: 18),
                                onPressed: () => setState(() {
                                  _query = '';
                                  _searchController.clear();
                                }),
                              )
                            : null,
                        filled: true,
                        fillColor: cs.surfaceContainerLow,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _query.isEmpty
                          ? '${staff.length} staff members'
                          : '${filtered.length} of ${staff.length} staff members',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(query: _query, cs: cs,
                        onAdd: () => _openEditPage(null))
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final member = filtered[i];
                          return _StaffTile(
                            member: member,
                            onTap: () => _openEditPage(member),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_staff',
        onPressed: () => _openEditPage(null),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Staff'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.query,
    required this.cs,
    required this.onAdd,
  });

  final String query;
  final ColorScheme cs;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isSearch = query.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearch ? Icons.search_off : Icons.people_outline,
              size: 56,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              isSearch ? 'No results for "$query"' : 'No staff yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isSearch
                  ? 'Try searching by a different name or department'
                  : 'Tap the button below to add your first staff member',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (!isSearch) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add First Staff Member'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({required this.member, required this.onTap});

  final AppUser member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            UserAvatar(
              initials: member.initials,
              photoUrl: member.photoUrl,
              radius: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.teacherDepartment != null
                              ? 'Teacher · ${member.teacherDepartment}'
                              : 'Teacher',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ShiftChip(shift: member.currentShift, cs: cs),
                    ],
                  ),
                  if (member.email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      member.email,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit_outlined,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  const _ShiftChip({required this.shift, required this.cs});

  final String? shift;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (shift) {
      'morning'   => ('Morning', const Color(0xFF0059BA)),
      'afternoon' => ('Afternoon', const Color(0xFFB7791F)),
      _           => ('Whole Day', const Color(0xFF2E7D32)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

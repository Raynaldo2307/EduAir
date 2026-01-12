// lib/src/features/shell/select_school.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/models/school/domain/school.dart';


/// ─────────────────────────────────────────────────────────
///  REFACTORED: Multi-tenant School Provider
/// ─────────────────────────────────────────────────────────
final schoolsListProvider = FutureProvider<List<School>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection('schools')
      .orderBy('name')
      .get();

  return snap.docs.map((doc) {
    final data = doc.data();
    return School(
      id: doc.id,
      name: (data['name'] ?? 'Unknown School').toString(),
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      radiusMeters: (data['radiusMeters'] as num?)?.toDouble() ?? 200.0,
      timezone: (data['timezone'] ?? 'America/Jamaica').toString(),
    );
  }).toList();
});

/// ─────────────────────────────────────────────────────────
/// REFACTORED: SelectSchoolPage
/// ─────────────────────────────────────────────────────────
class SelectSchoolPage extends ConsumerStatefulWidget {
  const SelectSchoolPage({super.key});

  @override
  ConsumerState<SelectSchoolPage> createState() => _SelectSchoolPageState();
}

class _SelectSchoolPageState extends ConsumerState<SelectSchoolPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final schoolsAsync = ref.watch(schoolsListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light professional background
      appBar: AppBar(
        title: const Text('Connect Your Campus'),
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Search Bar (The "Big Tech" Scale Move)
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search schools in Jamaica...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // 2. School List
          Expanded(
            child: user == null
                ? const _ErrorDisplay(message: 'Please sign in to continue.')
                : schoolsAsync.when(
                    data: (schools) {
                      final filtered = schools
                          .where((s) => s.name.toLowerCase().contains(_searchQuery))
                          .toList();

                      if (filtered.isEmpty) {
                        return const _ErrorDisplay(
                          message: 'No schools match your search.',
                          icon: Icons.search_off,
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, index) => _SchoolTile(
                          school: filtered[index],
                          onTap: () => _handleSelectSchool(user, filtered[index]),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => _ErrorDisplay(message: 'Error: $err'),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSelectSchool(AppUser user, School school) async {
    final userService = ref.read(userServiceProvider);
    final userNotifier = ref.read(userProvider.notifier);
    
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Update Firestore
      await userService.updateUserSchoolId(
        uid: user.uid,
        schoolId: school.id,
      );

      // 2. Update Global State
      userNotifier.state = user.copyWith(schoolId: school.id);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // 3. Routing Logic (Caribbean Scale Ready)
      final route = user.role == 'student' ? '/studentHome' : '/teacherHome';
      
      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to link school: $e')),
      );
    }
  }
}

/// ─────────────────────────────────────────────────────────
/// REFACTORED: Clean, Modern School Tile
/// ─────────────────────────────────────────────────────────
class _SchoolTile extends StatelessWidget {
  final School school;
  final VoidCallback onTap;

  const _SchoolTile({required this.school, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: const Icon(Icons.school, color: AppTheme.primaryColor),
        ),
        title: Text(
          school.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '${school.lat.toStringAsFixed(4)}, ${school.lng.toStringAsFixed(4)} • ${school.radiusMeters.toInt()}m radius',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
        onTap: onTap,
      ),
    );
  }
}

/// Helper for empty/error states
class _ErrorDisplay extends StatelessWidget {
  final String message;
  final IconData icon;
  const _ErrorDisplay({required this.message, this.icon = Icons.info_outline});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
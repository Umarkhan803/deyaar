import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/site_media_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'projects_screen.dart';

/// Site Photos module — same navy/card UI as the rest of the app.
/// Photos are stored per project; gallery supports selecting multiple images at once.
class SitePhotosScreen extends StatefulWidget {
  const SitePhotosScreen({super.key});

  @override
  State<SitePhotosScreen> createState() => _SitePhotosScreenState();
}

class _SitePhotosScreenState extends State<SitePhotosScreen> {
  Map<int, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final counts = await context.read<AppProvider>().repo.getPhotoCounts();
    if (!mounted) return;
    setState(() {
      _counts = counts;
      _loading = false;
    });
  }

  Future<void> _openProject(int projectId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(projectId: projectId),
      ),
    );
    await _load();
  }

  Future<void> _quickGallery(int projectId) async {
    final media = SiteMediaService(context.read<AppProvider>().repo);
    final n = await media.pickMultipleMediaFromGallery(projectId);
    if (!mounted) return;
    if (n > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(n == 1 ? '1 item added' : '$n items added'),
        ),
      );
      await _load();
    }
  }

  Future<void> _quickCamera(int projectId) async {
    final media = SiteMediaService(context.read<AppProvider>().repo);
    final n = await media.takeCameraPhoto(projectId);
    if (!mounted) return;
    if (n > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('1 photo added')),
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<AppProvider>().projects;

    return Scaffold(
      appBar: AppBar(title: const Text('Site Photos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : projects.isEmpty
              ? const EmptyState(
                  message: 'Add a project from the Projects tab',
                  icon: Icons.apartment_outlined,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Text(
                      'Progress photos by project',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Open a project to add site photos from camera or gallery. Gallery lets you select multiple photos at once.',
                      style: TextStyle(color: AppColors.muted, height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    ...projects.map((project) {
                      final count = _counts[project.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openProject(project.id!),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.photo_camera_outlined,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              project.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              count == 0
                                                  ? 'No progress photos yet'
                                                  : '$count photo${count == 1 ? '' : 's'}',
                                              style: const TextStyle(
                                                color: AppColors.muted,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: AppColors.muted,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _quickGallery(project.id!),
                                          icon: const Icon(
                                            Icons.photo_library_outlined,
                                            size: 18,
                                          ),
                                          label: const Text('Gallery'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _quickCamera(project.id!),
                                          icon: const Icon(
                                            Icons.photo_camera_outlined,
                                            size: 18,
                                          ),
                                          label: const Text('Camera'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}

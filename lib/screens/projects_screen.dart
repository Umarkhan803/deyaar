import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../services/site_media_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_header.dart';
import '../widgets/date_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/form_actions.dart';
import '../widgets/progress_ring.dart';
import '../widgets/status_chip.dart';

Future<bool?> openProjectEditor(BuildContext context, {Project? project}) async {
  final app = context.read<AppProvider>();
  final name = TextEditingController(text: project?.name ?? '');
  final location = TextEditingController(text: project?.location ?? '');
  final progress = TextEditingController(
    text: (project?.progress ?? 0).toStringAsFixed(0),
  );
  var status = project?.status ?? ProjectStatus.planning;
  var clientId = project?.clientId;
  var start = project?.startDate ?? Formatters.todayIso();
  var end = project?.expectedEnd ?? '';

  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (ctx) => Scaffold(
        appBar: AppBar(
          title: Text(project == null ? 'Add Project' : 'Edit Project'),
        ),
        body: StatefulBuilder(
          builder: (ctx, setModal) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Project name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: location,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                // ignore: deprecated_member_use
                value: clientId,
                decoration: const InputDecoration(labelText: 'Client'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No client')),
                  ...app.clients.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (v) => setModal(() => clientId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProjectStatus>(
                // ignore: deprecated_member_use
                value: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ProjectStatus.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                    .toList(),
                onChanged: (v) => setModal(() => status = v ?? status),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: progress,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Progress %'),
              ),
              const SizedBox(height: 12),
              DateField(
                label: 'Start date',
                value: start,
                onChanged: (v) => setModal(() => start = v),
              ),
              const SizedBox(height: 12),
              DateField(
                label: 'Expected end',
                value: end,
                onChanged: (v) => setModal(() => end = v),
              ),
              const SizedBox(height: 24),
              FormActions(
                primaryLabel: project == null ? 'Save Project' : 'Update',
                onCancel: () => Navigator.pop(ctx, false),
                onPrimary: () async {
                  if (name.text.trim().isEmpty) return;
                  await app.saveProject(
                    Project(
                      id: project?.id,
                      name: name.text.trim(),
                      location: location.text.trim(),
                      clientId: clientId,
                      status: status,
                      progress: double.tryParse(progress.text) ?? 0,
                      startDate: start,
                      expectedEnd: end,
                    ),
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ProjectsScreen extends StatefulWidget {
  final bool openAdd;
  final bool focusSearch;
  const ProjectsScreen({
    super.key,
    this.openAdd = false,
    this.focusSearch = false,
  });

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _search = TextEditingController();
  ProjectStatus? _filter;
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_opened && widget.openAdd) {
        _opened = true;
        _openEditor();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Project> _filtered(List<Project> all) {
    final q = _search.text.trim().toLowerCase();
    return all.where((p) {
      if (_filter != null && p.status != _filter) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          (p.clientName ?? '').toLowerCase().contains(q) ||
          p.location.toLowerCase().contains(q) ||
          p.displayId.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openEditor([Project? project]) async {
    final saved = await openProjectEditor(context, project: project);
    if (saved == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final currency = app.settings.currency;
    final list = _filtered(app.projects);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: AppHeader(
              onBack: Navigator.of(context).canPop()
                  ? () => Navigator.pop(context)
                  : null,
              trailing: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.filter_list,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              autofocus: widget.focusSearch,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search projects, IDs, or locations...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                StatusChip(
                  label: 'All Categories',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                ...ProjectStatus.values.map(
                  (s) => StatusChip(
                    label: s.label,
                    selected: _filter == s,
                    onTap: () => setState(() => _filter = s),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? const EmptyState(
                    message: 'No projects match your search.',
                    icon: Icons.work_outline,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = list[i];
                      final clientMatches = app.clients.where(
                        (c) => c.id == p.clientId,
                      );
                      final client = clientMatches.isEmpty
                          ? null
                          : clientMatches.first;
                      final budget = client?.contractValue ?? 0;
                      return _ProjectCard(
                        project: p,
                        budgetLabel: Formatters.money(
                          budget,
                          currency: currency,
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProjectDetailScreen(projectId: p.id!),
                          ),
                        ),
                        onEdit: () => _openEditor(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final String budgetLabel;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ProjectCard({
    required this.project,
    required this.budgetLabel,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  BadgePill(label: project.status.label),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 14,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project.location.isEmpty
                          ? (project.clientName ?? '—')
                          : project.location,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ProgressRing(
                    value: project.progress,
                    size: 64,
                    centerSub: null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Started ${Formatters.dateDisplay(project.startDate)}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          budgetLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sub-task completion',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (project.progress / 100).clamp(0, 1),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.primaryBlue,
                          backgroundColor: AppColors.primaryBlue.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Project? _project;
  List<SitePhoto> _photos = [];
  List<ProjectMilestone> _milestones = [];
  double _pending = 0;
  double _received = 0;
  double _contract = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<AppProvider>().repo;
    final project = await repo.getProject(widget.projectId);
    final photos = await repo.getPhotos(widget.projectId);
    final milestones = await repo.getMilestones(widget.projectId);
    final received = await repo.getReceivedForProject(widget.projectId);
    final pending = await repo.getPendingForProject(widget.projectId);
    final contract = await repo.getContractValueForProject(widget.projectId);
    if (!mounted) return;
    setState(() {
      _project = project;
      _photos = photos;
      _milestones = milestones;
      _received = received;
      _pending = pending;
      _contract = contract;
      _loading = false;
    });
  }

  Future<void> _addMedia() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery (photos & videos)'),
              subtitle: const Text('Multi-select from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Record video'),
              onTap: () => Navigator.pop(ctx, 'record'),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Pick video'),
              onTap: () => Navigator.pop(ctx, 'pick_video'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final media = SiteMediaService(context.read<AppProvider>().repo);
    switch (choice) {
      case 'gallery':
        await media.pickMultipleMediaFromGallery(widget.projectId);
      case 'camera':
        await media.takeCameraPhoto(widget.projectId);
      case 'record':
        await media.captureVideo(widget.projectId);
      case 'pick_video':
        await media.pickVideoFromGallery(widget.projectId);
    }
    await _load();
  }

  void _openMedia(SitePhoto photo) {
    final media = SiteMediaService(context.read<AppProvider>().repo);
    final isVideo = media.isVideoPath(photo.path) || photo.caption == 'video';
    if (isVideo) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _VideoPlayerPage(path: photo.path)),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: Image.file(File(photo.path), fit: BoxFit.contain),
        ),
      ),
    );
  }

  Future<void> _toggleMilestone(ProjectMilestone m) async {
    final repo = context.read<AppProvider>().repo;
    final done = !m.done;
    await repo.updateMilestone(
      ProjectMilestone(
        id: m.id,
        projectId: m.projectId,
        title: m.title,
        done: done,
        completedAt: done
            ? DateFormat('yyyy-MM-dd').format(DateTime.now())
            : null,
        sortOrder: m.sortOrder,
      ),
    );
    final milestones = await repo.getMilestones(widget.projectId);
    final doneCount = milestones.where((e) => e.done).length;
    final total = milestones.isEmpty ? 1 : milestones.length;
    final progress = (doneCount / total) * 100;
    final p = _project;
    if (p != null) {
      await context.read<AppProvider>().saveProject(
        p.copyWith(progress: progress),
      );
    }
    await _load();
  }

  Future<void> _updateProgressSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Update Progress',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Toggle milestones below, or add photos to document site progress.',
                ),
                const SizedBox(height: 12),
                ..._milestones.map(
                  (m) => CheckboxListTile(
                    value: m.done,
                    title: Text(m.title),
                    onChanged: (_) async {
                      Navigator.pop(ctx);
                      await _toggleMilestone(m);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _addMedia();
                  },
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Add photos / video'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppProvider>().settings.currency;
    if (_loading || _project == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final project = _project!;
    final done = _milestones.where((m) => m.done).length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _updateProgressSheet,
        icon: const Icon(Icons.add),
        label: const Text('Update Progress'),
      ),
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final saved = await openProjectEditor(context, project: project);
              if (saved == true) await _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete project?'),
                  content: const Text(
                    'This removes the project and related records.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true && mounted) {
                await context.read<AppProvider>().removeProject(
                  widget.projectId,
                );
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Card(
            color: AppColors.primaryBlue.withValues(alpha: 0.18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      BadgePill(label: project.status.label),
                      BadgePill(
                        label: project.displayId,
                        background: Colors.white24,
                        foreground: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    project.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text(project.location.isEmpty ? '—' : project.location),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ProgressRing(
                    value: project.progress,
                    size: 100,
                    centerLabel: '${project.progress.round()}%',
                    centerSub: 'COMPLETED',
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Date: ${Formatters.dateDisplay(project.startDate)}',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Est. Completion: ${project.expectedEnd.isEmpty ? 'Not set' : Formatters.dateDisplay(project.expectedEnd)}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Project Information',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text('Client ${project.clientName ?? '—'}'),
                ),
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text('Status ${project.status.label}'),
                ),
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(
                    'Contract Value ${Formatters.money(_contract, currency: currency)}',
                  ),
                  subtitle: Text(
                    'Received ${Formatters.money(_received, currency: currency)} · Pending ${Formatters.money(_pending, currency: currency)}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Milestones',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '$done/${_milestones.length} done',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: _milestones
                  .map(
                    (m) => CheckboxListTile(
                      value: m.done,
                      onChanged: (_) => _toggleMilestone(m),
                      title: Text(m.title),
                      subtitle: Text(
                        m.done
                            ? 'Completed ${Formatters.dateDisplay(m.completedAt ?? '')}'
                            : 'Pending',
                      ),
                      secondary: Icon(
                        m.done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: m.done ? AppColors.primaryBlue : AppColors.muted,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Site photos & video',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: _addMedia,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_photos.isEmpty)
            const EmptyState(
              message:
                  'No progress media yet. Add photos or video from gallery (multi) or camera.',
              icon: Icons.photo_outlined,
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, i) {
                final photo = _photos[i];
                final mediaSvc =
                    SiteMediaService(context.read<AppProvider>().repo);
                final isVideo = mediaSvc.isVideoPath(photo.path) ||
                    photo.caption == 'video';
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Material(
                    color: AppColors.sky,
                    child: InkWell(
                      onTap: () => _openMedia(photo),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (isVideo)
                            const ColoredBox(
                              color: Color(0xFF1B2A4A),
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Colors.white,
                                size: 48,
                              ),
                            )
                          else
                            Image.file(File(photo.path), fit: BoxFit.cover),
                          Positioned(
                            left: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              color: Colors.black54,
                              child: Text(
                                isVideo
                                    ? 'Video · ${photo.takenAt}'
                                    : photo.takenAt,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                await context
                                    .read<AppProvider>()
                                    .repo
                                    .deletePhoto(photo.id!);
                                await _load();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _VideoPlayerPage extends StatefulWidget {
  final String path;
  const _VideoPlayerPage({required this.path});

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Site video')),
      body: Center(
        child: !_ready
            ? const CircularProgressIndicator()
            : AspectRatio(
                aspectRatio: _controller.value.aspectRatio == 0
                    ? 16 / 9
                    : _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_controller),
                    VideoProgressIndicator(_controller, allowScrubbing: true),
                    Positioned(
                      bottom: 28,
                      child: IconButton(
                        iconSize: 48,
                        color: Colors.white,
                        onPressed: () {
                          setState(() {
                            if (_controller.value.isPlaying) {
                              _controller.pause();
                            } else {
                              _controller.play();
                            }
                          });
                        },
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause_circle
                              : Icons.play_circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

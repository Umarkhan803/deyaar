import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../services/wage_media_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

class TransactionPhotosScreen extends StatefulWidget {
  final Worker worker;

  const TransactionPhotosScreen({super.key, required this.worker});

  @override
  State<TransactionPhotosScreen> createState() =>
      _TransactionPhotosScreenState();
}

class _TransactionPhotosScreenState extends State<TransactionPhotosScreen> {
  List<WagePaymentPhoto> _photos = [];
  bool _loading = true;
  String? _error;

  Worker get worker => widget.worker;

  // The payment ID to attach new photos to — most recent payment, or 0.
  int _wagePaymentId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final repo = context.read<AppProvider>().repo;

      // Single JOIN query — one round trip for all photos
      final photos = await repo.getWagePaymentPhotosForWorker(worker.id!);

      // Also resolve the target payment ID for new photos
      final payments = await repo.getWagePayments(workerId: worker.id!);
      final paymentId = payments.isNotEmpty ? (payments.first.id ?? 0) : 0;

      if (!mounted) return;
      setState(() {
        _photos = photos;
        _wagePaymentId = paymentId;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load transaction photos. Please try again.';
      });
    }
  }

  // ── Add from gallery (multi-select) ──────────────────────────────────────
  Future<void> _addGallery() async {
    final media = WageMediaService(context.read<AppProvider>().repo);
    final n = await media.pickMultipleFromGallery(worker.id!, _wagePaymentId);
    if (!mounted) return;
    if (n > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(n == 1 ? '1 photo added' : '$n photos added')),
      );
      await _load();
    }
  }

  // ── Take photo from camera ────────────────────────────────────────────────
  Future<void> _addCamera() async {
    final media = WageMediaService(context.read<AppProvider>().repo);
    final n = await media.takePhoto(worker.id!, _wagePaymentId);
    if (!mounted) return;
    if (n > 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('1 photo added')));
      await _load();
    }
  }

  // ── Show media source picker (same as site photos _addMedia) ─────────────
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
              title: const Text('Gallery'),
              subtitle: const Text('Multi-select photos'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'gallery') {
      await _addGallery();
    } else {
      await _addCamera();
    }
  }

  // ── Delete with confirmation ──────────────────────────────────────────────
  Future<void> _deletePhoto(WagePaymentPhoto photo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final media = WageMediaService(context.read<AppProvider>().repo);
    await media.deletePhoto(photo);
    if (!mounted) return;
    await _load();
  }

  // ── Open full-screen viewer (same InteractiveViewer Dialog as site photos)
  void _openPhoto(WagePaymentPhoto photo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.file(File(photo.path), fit: BoxFit.contain),
            ),
            // Close button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${worker.name} — Photos'),
        actions: [
          // Count badge
          if (!_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_photos.length} photo${_photos.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      // FAB matches site photos extended FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMedia,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Add Photo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 42),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _photos.isEmpty
          ? const EmptyState(
              message:
                  'No proof photos yet.\nTap "Add Photo" to add from gallery or camera.',
              icon: Icons.photo_library_outlined,
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
              itemCount: _photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (ctx, i) {
                final photo = _photos[i];
                return _PhotoTile(
                  photo: photo,
                  onTap: () => _openPhoto(photo),
                  onDelete: () => _deletePhoto(photo),
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single grid tile — mirrors the site photos Stack/InkWell pattern exactly
// ─────────────────────────────────────────────────────────────────────────────
class _PhotoTile extends StatelessWidget {
  final WagePaymentPhoto photo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PhotoTile({
    required this.photo,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final exists = File(photo.path).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Material(
        color: AppColors.sky,
        child: InkWell(
          onTap: exists ? onTap : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              exists
                  ? Image.file(
                      File(photo.path),
                      fit: BoxFit.cover,
                      // Cache at display size — avoids decoding full-res on every tile
                      cacheWidth: 300,
                    )
                  : const ColoredBox(
                      color: Color(0xFF1B2A4A),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 32,
                      ),
                    ),

              // Date label — bottom left (same as site photos)
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  color: Colors.black54,
                  child: Text(
                    photo.takenAt,
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                  ),
                ),
              ),

              // Delete icon — top right (same as site photos)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

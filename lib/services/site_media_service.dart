import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/models/models.dart';
import '../data/repositories/app_repository.dart';

/// Camera / gallery helpers for site photos and videos (multi-select supported).
class SiteMediaService {
  SiteMediaService(this._repo);

  final AppRepository _repo;
  final ImagePicker _picker = ImagePicker();

  Future<Directory> photosDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'site_photos'));
    if (!await photosDir.exists()) await photosDir.create(recursive: true);
    return photosDir;
  }

  bool isVideoPath(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext == '.mp4' ||
        ext == '.mov' ||
        ext == '.3gp' ||
        ext == '.webm' ||
        ext == '.mkv';
  }

  Future<int> savePickedFiles(
    int projectId,
    List<XFile> files, {
    String caption = '',
  }) async {
    if (files.isEmpty) return 0;
    final photosDir = await this.photosDir();
    final stamp = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    var i = 0;
    for (final file in files) {
      final ext = p.extension(file.path);
      final isVideo = isVideoPath(file.path);
      final name =
          'p${projectId}_${DateTime.now().millisecondsSinceEpoch}_${i++}$ext';
      final saved = await File(file.path).copy(p.join(photosDir.path, name));
      await _repo.addPhoto(SitePhoto(
        projectId: projectId,
        path: saved.path,
        caption: caption.isNotEmpty
            ? caption
            : (isVideo ? 'video' : ''),
        takenAt: stamp,
      ));
    }
    return files.length;
  }

  /// Multi-select photos from gallery.
  Future<int> pickMultipleFromGallery(int projectId) async {
    final files = await _picker.pickMultiImage(
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (files.isEmpty) return 0;
    return savePickedFiles(projectId, files);
  }

  /// Multi-select photos and/or videos from gallery.
  Future<int> pickMultipleMediaFromGallery(int projectId) async {
    final files = await _picker.pickMultipleMedia(
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (files.isEmpty) return 0;
    return savePickedFiles(projectId, files);
  }

  Future<int> takeCameraPhoto(int projectId) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (file == null) return 0;
    return savePickedFiles(projectId, [file]);
  }

  Future<int> captureVideo(int projectId) async {
    final file = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 3),
    );
    if (file == null) return 0;
    return savePickedFiles(projectId, [file], caption: 'video');
  }

  Future<int> pickVideoFromGallery(int projectId) async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (file == null) return 0;
    return savePickedFiles(projectId, [file], caption: 'video');
  }
}

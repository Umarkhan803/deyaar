import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/models/models.dart';
import '../data/repositories/app_repository.dart';

/// Camera / gallery helpers for worker transaction proof photos.
/// Mirrors SiteMediaService so photos are saved and displayed the same way.
class WageMediaService {
  WageMediaService(this._repo);

  final AppRepository _repo;
  final ImagePicker _picker = ImagePicker();

  Future<Directory> photosDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'wage_photos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Saves a list of picked files and returns the number saved.
  /// [workerId] is used to build the filename prefix so photos are
  /// scoped to the worker even when wage_payment_id is 0 (unlinked).
  Future<int> savePickedFiles(
    int workerId,
    int wagePaymentId,
    List<XFile> files,
  ) async {
    if (files.isEmpty) return 0;
    final dir = await photosDir();
    final stamp = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    var i = 0;
    for (final file in files) {
      final ext = p.extension(file.path).isNotEmpty
          ? p.extension(file.path)
          : '.jpg';
      final name = 'w${workerId}_${DateTime.now().millisecondsSinceEpoch}_${i++}$ext';
      final saved = await File(file.path).copy(p.join(dir.path, name));
      await _repo.addWagePaymentPhoto(WagePaymentPhoto(
        wagePaymentId: wagePaymentId,
        path: saved.path,
        caption: '',
        takenAt: stamp,
      ));
    }
    return files.length;
  }

  /// Multi-select photos + videos from gallery.
  Future<int> pickMultipleFromGallery(int workerId, int wagePaymentId) async {
    final files = await _picker.pickMultipleMedia(
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (files.isEmpty) return 0;
    return savePickedFiles(workerId, wagePaymentId, files);
  }

  /// Single photo from camera.
  Future<int> takePhoto(int workerId, int wagePaymentId) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (file == null) return 0;
    return savePickedFiles(workerId, wagePaymentId, [file]);
  }

  /// Delete a photo record and its file from disk.
  Future<void> deletePhoto(WagePaymentPhoto photo) async {
    await _repo.deleteWagePaymentPhoto(photo.id!);
    try {
      await File(photo.path).delete();
    } catch (_) {}
  }
}

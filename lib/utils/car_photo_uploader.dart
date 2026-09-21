import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/car_service.dart';
import '../theme/app_theme.dart';

/*
 * Add photos to a car in a few taps:
 *   1. choose Camera or Gallery (several photos at once)
 *   2. photos are shrunk on the phone first, so the upload is fast
 *   3. a progress bar shows while they are sent
 *
 * Returns true when photos were uploaded, so the caller can refresh.
 * Used from the car list menu and right after adding a new car.
 */
Future<bool> pickAndUploadCarPhotos(
    BuildContext context, {
      required int carId,
      required String carName,
    }) async {
  final _PhotoChoice? choice = await showModalBottomSheet<_PhotoChoice>(
    context: context,
    showDragHandle: true,
    builder: (_) => _PhotoSourceSheet(carName: carName),
  );

  if (choice == null || !context.mounted) {
    return false;
  }

  final ImagePicker picker = ImagePicker();
  List<XFile> photos = <XFile>[];

  // Resize and compress on the phone: a 12 MP photo becomes
  // a few hundred KB, which uploads in about a second.
  const double maxSide = 1600;
  const int quality = 80;

  try {
    if (choice.fromCamera) {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxSide,
        maxHeight: maxSide,
        imageQuality: quality,
      );

      if (photo != null) {
        photos = <XFile>[photo];
      }
    } else {
      photos = await picker.pickMultiImage(
        maxWidth: maxSide,
        maxHeight: maxSide,
        imageQuality: quality,
        limit: 8,
      );
    }
  } on PlatformException catch (error) {
    if (context.mounted) {
      _snack(
        context,
        error.code == 'camera_access_denied'
            ? 'Camera permission is needed to take photos.'
            : 'Could not open the ${choice.fromCamera ? 'camera' : 'gallery'}.',
        isError: true,
      );
    }
    return false;
  }

  if (photos.isEmpty || !context.mounted) {
    return false;
  }

  if (photos.length > 8) {
    photos = photos.take(8).toList();
  }

  final ValueNotifier<double> progress = ValueNotifier<double>(0);

  // Upload dialog with a live progress bar.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UploadDialog(count: photos.length, progress: progress),
  );

  try {
    final String message = await CarService().uploadPhotos(
      carId: carId,
      photos: photos,
      setMain: choice.setMain,
      onProgress: (double value) => progress.value = value,
    );

    // The image link stays the same, so drop cached pictures
    // to show the new main photo straight away.
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      HapticFeedback.mediumImpact();
      _snack(context, message);
    }

    return true;
  } on CarServiceException catch (error) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _snack(context, error.message, isError: true);
    }

    return false;
  } finally {
    progress.dispose();
  }
}

void _snack(BuildContext context, String text, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
    ),
  );
}

class _PhotoChoice {
  final bool fromCamera;
  final bool setMain;

  const _PhotoChoice({required this.fromCamera, required this.setMain});
}

/*
 * ---------- Bottom sheet ----------
 */
class _PhotoSourceSheet extends StatefulWidget {
  final String carName;

  const _PhotoSourceSheet({required this.carName});

  @override
  State<_PhotoSourceSheet> createState() => _PhotoSourceSheetState();
}

class _PhotoSourceSheetState extends State<_PhotoSourceSheet> {
  bool _setMain = true;

  void _choose(bool fromCamera) {
    Navigator.pop(
      context,
      _PhotoChoice(fromCamera: fromCamera, setMain: _setMain),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ADD PHOTOS',
              style: TextStyle(
                color: AppTheme.primaryBlueDark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.carName,
              style: const TextStyle(
                color: AppTheme.darkColor,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_camera_outlined,
                    label: 'Camera',
                    hint: 'One photo',
                    onTap: () => _choose(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    hint: 'Up to 8',
                    onTap: () => _choose(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _setMain,
              onChanged: (bool value) => setState(() => _setMain = value),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Use first photo as the main image',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'The rest go to the car gallery',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primaryBlueSoft,
      borderRadius: BorderRadius.circular(AppTheme.largeRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.largeRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, size: 30, color: AppTheme.primaryBlue),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.darkColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                hint,
                style: const TextStyle(color: AppTheme.mutedColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
 * ---------- Upload dialog ----------
 */
class _UploadDialog extends StatelessWidget {
  final int count;
  final ValueNotifier<double> progress;

  const _UploadDialog({required this.count, required this.progress});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text('Uploading $count photo${count == 1 ? '' : 's'}'),
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (context, value, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: value == 0 ? null : value,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  value >= 1 ? 'Saving…' : '${(value * 100).round()}%',
                  style: const TextStyle(color: AppTheme.mutedColor),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

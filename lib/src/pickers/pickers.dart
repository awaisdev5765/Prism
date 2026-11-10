import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A file the app picked, decoupled from any picker package.
///
/// Prism deliberately does not depend on `image_picker` or `file_picker`;
/// your `onPick` callback calls whichever you use and hands back these value
/// types. [bytes], when provided, powers previews.
class PrismPickedFile {
  /// Creates a picked-file value.
  const PrismPickedFile({
    required this.name,
    required this.sizeBytes,
    this.bytes,
    this.mimeType,
    this.data,
  });

  /// Display name, e.g. `receipt.pdf`.
  final String name;

  /// Size in bytes.
  final int sizeBytes;

  /// Image bytes for preview thumbnails (image picker tiles only).
  final Uint8List? bytes;

  /// Best-effort MIME type, e.g. `application/pdf`.
  final String? mimeType;

  /// Escape hatch for the raw platform object (`XFile`, `PlatformFile`),
  /// so callers never lose information.
  final Object? data;

  /// Human-readable size, e.g. `1.2 MB`.
  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  /// Extension without the dot, lower-cased.
  String get extension {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  }
}

/// Validation for picked files: extensions and per-file size.
class PrismPickerConstraints {
  /// Creates constraints. Null bounds mean unlimited.
  const PrismPickerConstraints({
    this.allowedExtensions,
    this.maxSizeBytes,
    this.maxFiles,
  });

  /// When non-empty, lower-cased extensions must be in this list.
  final List<String>? allowedExtensions;

  /// Rejects files larger than this.
  final int? maxSizeBytes;

  /// Rejects batches larger than this.
  final int? maxFiles;

  /// Returns a human-readable reason when [files] violate the constraints,
  /// or null when they are all acceptable.
  String? validate(List<PrismPickedFile> files) {
    if (maxFiles != null && files.length > maxFiles!) {
      return 'Pick at most $maxFiles file(s)';
    }
    for (final file in files) {
      if (allowedExtensions != null &&
          allowedExtensions!.isNotEmpty &&
          !allowedExtensions!.contains(file.extension)) {
        return '"${file.name}" is not an allowed type '
            '(${allowedExtensions!.join(', ')})';
      }
      if (maxSizeBytes != null && file.sizeBytes > maxSizeBytes!) {
        return '"${file.name}" is larger than the '
            '${_human(maxSizeBytes!)} limit';
      }
    }
    return null;
  }

  String _human(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${bytes ~/ 1024} KB';
    return '${bytes ~/ 1024 ~/ 1024} MB';
  }
}

/// A file attachment picker tile with built-in validation and removal.
///
/// Prism renders the tile, chips, validation and empty state; your app
/// supplies the actual picking via [onPick] (typically `file_picker`).
class PrismFilePickerTile extends StatelessWidget {
  /// Creates a file picker tile.
  const PrismFilePickerTile({
    super.key,
    required this.files,
    required this.onPick,
    required this.onFilesPicked,
    this.onRemove,
    this.label = 'Attachments',
    this.emptyHint = 'Tap to attach files',
    this.constraints = const PrismPickerConstraints(),
    this.trailing,
  });

  /// Currently attached files.
  final List<PrismPickedFile> files;

  /// Opens your picker and returns the picked files (or null when cancelled).
  final Future<List<PrismPickedFile>?> Function() onPick;

  /// Called with the new file list after a valid pick.
  final ValueChanged<List<PrismPickedFile>> onFilesPicked;

  /// Removes one file.
  final ValueChanged<PrismPickedFile>? onRemove;

  /// Tile label.
  final String label;

  /// Hint shown in the empty state.
  final String emptyHint;

  /// Extension, size and count limits.
  final PrismPickerConstraints constraints;

  /// Optional trailing widget in the header (e.g. an upload spinner).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
            ?trailing,
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        InkWell(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          onTap: _pick,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(tokens.spaceMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              border: Border.all(color: colors.outline),
            ),
            child: files.isEmpty
                ? Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_file,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: tokens.spaceSm),
                        Text(
                          emptyHint,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : Wrap(
                    spacing: tokens.spaceSm,
                    runSpacing: tokens.spaceSm,
                    children: [
                      for (final file in files)
                        InputChip(
                          avatar: const Icon(
                            Icons.insert_drive_file_outlined,
                            size: 18,
                          ),
                          label: Text('${file.name} · ${file.sizeLabel}'),
                          onDeleted: onRemove == null
                              ? null
                              : () => onRemove!(file),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _pick() async {
    final picked = await onPick();
    if (picked == null || picked.isEmpty) return;
    final error = constraints.validate(picked);
    if (error != null) return;
    onFilesPicked([...files, ...picked]);
  }
}

/// An image picker tile with thumbnails, validation and removal.
///
/// Same contract as [PrismFilePickerTile]: Prism owns the UI, your [onPick]
/// owns the platform picker. Pass image bytes in
/// [PrismPickedFile.bytes] for previews.
class PrismImagePickerTile extends StatelessWidget {
  /// Creates an image picker tile.
  const PrismImagePickerTile({
    super.key,
    required this.images,
    required this.onPick,
    required this.onImagesPicked,
    this.onRemove,
    this.label = 'Photos',
    this.maxImages,
    this.maxSizeBytes,
    this.previewSize = 72,
  });

  /// Currently selected images.
  final List<PrismPickedFile> images;

  /// Opens your picker and returns the picked images (or null).
  final Future<List<PrismPickedFile>?> Function() onPick;

  /// Called with the new image list after a valid pick.
  final ValueChanged<List<PrismPickedFile>> onImagesPicked;

  /// Removes one image.
  final ValueChanged<PrismPickedFile>? onRemove;

  /// Tile label.
  final String label;

  /// Maximum images kept after a pick.
  final int? maxImages;

  /// Maximum size per image.
  final int? maxSizeBytes;

  /// Thumbnail edge length.
  final double previewSize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
            if (maxImages != null)
              Text(
                '${images.length}/$maxImages',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        SizedBox(
          height: previewSize,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final image in images)
                Padding(
                  padding: EdgeInsets.only(right: tokens.spaceSm),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(tokens.radiusMd),
                        child: image.bytes != null
                            ? Image.memory(
                                image.bytes!,
                                width: previewSize,
                                height: previewSize,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: previewSize,
                                  height: previewSize,
                                  color: colors.surfaceSunken,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                  ),
                                ),
                              )
                            : Container(
                                width: previewSize,
                                height: previewSize,
                                color: colors.surfaceSunken,
                                child: const Icon(Icons.image_outlined),
                              ),
                      ),
                      if (onRemove != null)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => onRemove!(image),
                            customBorder: const CircleBorder(),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: theme.colorScheme.surface,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              InkWell(
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                onTap: _pick,
                child: Container(
                  width: previewSize,
                  height: previewSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(tokens.radiusMd),
                    border: Border.all(color: colors.outline),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pick() async {
    final picked = await onPick();
    if (picked == null || picked.isEmpty) return;
    final error = PrismPickerConstraints(
      maxSizeBytes: maxSizeBytes,
    ).validate(picked);
    if (error != null) return;
    final merged = [...images, ...picked];
    if (maxImages != null && merged.length > maxImages!) {
      merged.removeRange(maxImages!, merged.length);
    }
    onImagesPicked(merged);
  }
}

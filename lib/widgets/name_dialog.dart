import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/bibliophile.dart';
import '../theme/bibliophile_themes.dart';

/// Shared "Puzzler name" rename dialog, used by the menu and settings screens.
///
/// Commit semantics (player-name review, 2026-10-09):
/// - Save button .............. commits the typed name and closes.
/// - Keyboard done (onSubmitted) commits the typed name and closes.
/// - Focus loss (barrier tap / system back: the dialog is dismissed without
///   an explicit Save or Cancel) commits the typed name instead of silently
///   dropping it — renames must never appear "not saved".
/// - Cancel ..................... discards the typed name and closes.
Future<void> showPuzzlerNameDialog({
  required BuildContext context,
  required LibraryThemeDef theme,
  required JigsawSettings settings,
  LibraryAudio? audio,
}) async {
  final ctrl = TextEditingController(text: settings.profileName);
  var saved = false;
  var cancelled = false;

  Future<void> commit() async {
    saved = true;
    await settings.setProfileName(ctrl.text);
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: theme.woodMid,
      title:
          Text('Puzzler name', style: Bibliophile.display(20, theme: theme)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLength: 20,
        style: Bibliophile.body(16, theme: theme),
        decoration: InputDecoration(
          hintText: 'Your name',
          hintStyle: Bibliophile.body(14,
              theme: theme, color: theme.ivory.withValues(alpha: 0.4)),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.accent)),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.accentLight, width: 2)),
        ),
        // Keyboard done: commit the name, don't leave it hanging.
        onSubmitted: (_) async {
          audio?.click();
          await commit();
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            cancelled = true;
            Navigator.of(dialogContext).pop();
          },
          child: Text('Cancel', style: Bibliophile.label(14, theme: theme)),
        ),
        TextButton(
          onPressed: () async {
            audio?.click();
            await commit();
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: Text('Save', style: Bibliophile.label(14, theme: theme)),
        ),
      ],
    ),
  );

  // Focus-loss commit: the dialog went away without an explicit Save or
  // Cancel (barrier tap, system back). The field lost focus — commit the
  // typed name rather than silently dropping it.
  if (!saved && !cancelled && ctrl.text.trim() != settings.profileName) {
    await settings.setProfileName(ctrl.text);
  }
  ctrl.dispose();
}

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/bibliophile.dart';
import '../theme/bibliophile_themes.dart';
import 'custom_theme_screen.dart';
import 'pro_screen.dart';

/// Settings — oak catalog-card-drawer rows, brass-stud toggles and sliders.
class SettingsScreen extends StatefulWidget {
  final LibraryAudio audio;
  final JigsawSettings settings;
  final StoreService store;
  final bool openThemes;

  const SettingsScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
    this.openThemes = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  LibraryThemeDef get _t => LibraryThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    if (widget.openThemes) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToThemes();
      });
    }
  }

  final _themesKey = GlobalKey();
  void _scrollToThemes() {
    Scrollable.ensureVisible(_themesKey.currentContext!,
        duration: const Duration(milliseconds: 400));
  }

  void _goPro() {
    widget.audio.click();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    );
  }

  void _confirmReset() {
    final t = _t;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.woodMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: t.accent, width: 2),
        ),
        title:
            Text('Reset records?', style: Bibliophile.display(20, theme: t)),
        content: Text(
          'This clears your best times, star ratings and daily stamps. This cannot be undone.',
          style: Bibliophile.body(14, theme: t),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Keep them',
                style: Bibliophile.label(14, theme: t)),
          ),
          TextButton(
            onPressed: () {
              widget.settings.resetRecords();
              widget.audio.invalid();
              Navigator.of(context).pop();
            },
            child: Text('Reset',
                style: Bibliophile.label(14, theme: t)
                    .copyWith(color: t.folio)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final audio = widget.audio;
    return WoodBackdrop(
      theme: t,
      child: LampGlow(
        theme: t,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: t.accentLight),
              onPressed: () {
                audio.click();
                Navigator.of(context).pop();
              },
            ),
            title: Text('Settings', style: Bibliophile.display(22, theme: t)),
            centerTitle: true,
          ),
          body: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle('Puzzler', t),
                  SettingRow(
                    theme: t,
                    label: 'Name',
                    control: GestureDetector(
                      onTap: () {
                        audio.click();
                        final ctrl =
                            TextEditingController(text: s.profileName);
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: t.woodMid,
                            title: Text('Puzzler name',
                                style: Bibliophile.display(20, theme: t)),
                            content: TextField(
                              controller: ctrl,
                              autofocus: true,
                              maxLength: 20,
                              style: Bibliophile.body(16, theme: t),
                              decoration: InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: t.accent)),
                                focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: t.accentLight, width: 2)),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(),
                                child: Text('Cancel',
                                    style: Bibliophile.label(14,
                                        theme: t)),
                              ),
                              TextButton(
                                onPressed: () {
                                  s.setProfileName(ctrl.text);
                                  audio.click();
                                  Navigator.of(context).pop();
                                },
                                child: Text('Save',
                                    style: Bibliophile.label(14,
                                        theme: t)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s.profileName,
                              style: Bibliophile.label(14, theme: t)),
                          const SizedBox(width: 6),
                          Icon(Icons.edit,
                              size: 16,
                              color: t.accentLight.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SectionTitle('Puzzle assistance', t),
                  SettingRow(
                    theme: t,
                    label: 'Apprentice marks',
                    control: _Segmented(
                      theme: t,
                      options: const ['Auto', 'On', 'Off'],
                      value: s.apprenticeMarks,
                      onChanged: (v) {
                        audio.click();
                        s.setApprenticeMarks(v);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Gold-foil dots on edge pieces. Auto: on for 24/48, off for 96/192.',
                      style: Bibliophile.body(12,
                          theme: t,
                          color: t.ivory.withValues(alpha: 0.6)),
                    ),
                  ),
                  SettingRow(
                    theme: t,
                    label: 'Generous snap',
                    control: BrassStudToggle(
                      theme: t,
                      value: s.generousSnap,
                      onChanged: (v) {
                        audio.click();
                        s.setGenerousSnap(v);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Widens the snap radius from 28% to 40% of a piece edge — kinder for young puzzlers.',
                      style: Bibliophile.body(12,
                          theme: t,
                          color: t.ivory.withValues(alpha: 0.6)),
                    ),
                  ),
                  SettingRow(
                    theme: t,
                    label: 'Reference thumbnail',
                    control: BrassStudToggle(
                      theme: t,
                      value: s.showReference,
                      onChanged: (v) {
                        audio.click();
                        s.setShowReference(v);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SectionTitle('Sound', t),
                  SettingRow(
                    theme: t,
                    label: 'Music',
                    control: BrassStudToggle(
                      theme: t,
                      value: s.musicOn,
                      onChanged: (v) async {
                        audio.click();
                        await s.setMusic(v);
                        audio.configure(
                            musicOn: s.musicOn,
                            sfxOn: s.sfxOn,
                            volume: s.volume);
                        if (v) {
                          audio.startMenuMusic();
                        } else {
                          audio.stopMusic();
                        }
                      },
                    ),
                  ),
                  SettingRow(
                    theme: t,
                    label: 'Sound effects',
                    control: BrassStudToggle(
                      theme: t,
                      value: s.sfxOn,
                      onChanged: (v) async {
                        await s.setSfx(v);
                        audio.configure(
                            musicOn: s.musicOn,
                            sfxOn: s.sfxOn,
                            volume: s.volume);
                        if (v) audio.click();
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Volume', style: Bibliophile.body(16, theme: t)),
                  BeadSlider(
                    theme: t,
                    value: s.volume,
                    onChanged: (v) async {
                      await s.setVolume(v);
                      audio.configure(
                          musicOn: s.musicOn,
                          sfxOn: s.sfxOn,
                          volume: s.volume);
                    },
                  ),
                  const SizedBox(height: 10),
                  _SectionTitle('Jigsaw PRO', t),
                  SettingRow(
                    theme: t,
                    label: s.isPro ? 'PRO active ✦' : 'Unlock PRO',
                    control: GestureDetector(
                      onTap: _goPro,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: s.isPro
                              ? t.accent.withValues(alpha: 0.85)
                              : Colors.black.withValues(alpha: 0.3),
                          border: Border.all(
                              color: t.accentLight, width: 2),
                        ),
                        child: Text(
                          s.isPro ? '✦ PRO' : 'View',
                          style: Bibliophile.label(13,
                              theme: t,
                              color: s.isPro ? t.woodDeep : t.ivory),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SectionTitle('Library themes', t, key: _themesKey),
                  SettingRow(
                    theme: t,
                    label: 'Theme',
                    control: Text(
                      LibraryThemes.byId(s.themeId,
                              custom: s.customTheme)
                          .name,
                      style: Bibliophile.label(14, theme: t),
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final th in LibraryThemes.all)
                        _themeSwatch(t, s, th),
                      _customSwatch(t, s),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _SectionTitle('Records', t),
                  SettingRow(
                    theme: t,
                    label: 'Reset best times & stars',
                    control: GestureDetector(
                      onTap: _confirmReset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: t.accent.withValues(alpha: 0.6)),
                        ),
                        child: Text('Reset',
                            style: Bibliophile.label(13, theme: t)),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 4, top: 6, bottom: 6),
                    child: Text(
                      '${s.wins} puzzles completed · best times kept per folio size.',
                      style: Bibliophile.body(12,
                          theme: t,
                          color: t.ivory.withValues(alpha: 0.6)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SectionTitle('About', t),
                  Text(
                    'Jigsaw — Bibliophile Puzzle Sanctuary edition.\nVersion 1.0.0 • Made with ♥ by WAJIHA',
                    style: Bibliophile.body(13,
                        theme: t,
                        color: t.ivory.withValues(alpha: 0.65)),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _themeSwatch(
      LibraryThemeDef t, JigsawSettings s, LibraryThemeDef th) {
    final locked = LibraryThemes.isProTheme(th.id) && !s.isPro;
    final selected = s.themeId == th.id;
    return GestureDetector(
      onTap: () {
        widget.audio.click();
        if (locked) {
          _goPro();
          return;
        }
        s.setTheme(th.id);
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [th.woodMid, th.mat, th.accent],
                  ),
                  border: Border.all(
                    color: selected
                        ? t.accentLight
                        : t.accent.withValues(alpha: 0.3),
                    width: selected ? 3 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        offset: const Offset(0, 3),
                        blurRadius: 6),
                  ],
                ),
              ),
              if (locked)
                Container(
                  width: 72,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                  child: Icon(Icons.lock,
                      color: t.accentLight, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 76,
            child: Text(
              th.name,
              style: Bibliophile.body(10,
                  theme: t, color: t.ivory.withValues(alpha: 0.8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _customSwatch(LibraryThemeDef t, JigsawSettings s) {
    final locked = !s.isPro;
    final selected = s.themeId == 'custom';
    return GestureDetector(
      onTap: () {
        widget.audio.click();
        if (locked) {
          _goPro();
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomThemeScreen(
              audio: widget.audio,
              settings: s,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: t.woodDeep.withValues(alpha: 0.7),
                  border: Border.all(
                    color: selected
                        ? t.accentLight
                        : t.accent.withValues(alpha: 0.4),
                    width: selected ? 3 : 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Icon(Icons.palette,
                    color: t.accentLight, size: 22),
              ),
              if (locked)
                Container(
                  width: 72,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                  child: Icon(Icons.lock,
                      color: t.accentLight, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 76,
            child: Text(
              'My Creation',
              style: Bibliophile.body(10,
                  theme: t, color: t.ivory.withValues(alpha: 0.8)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final LibraryThemeDef theme;
  const _SectionTitle(this.text, this.theme, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(text, style: Bibliophile.display(19, theme: theme)),
    );
  }
}

/// Three-way brass segmented control (Auto / On / Off).
class _Segmented extends StatelessWidget {
  final LibraryThemeDef theme;
  final List<String> options;
  final int value;
  final ValueChanged<int> onChanged;
  const _Segmented({
    required this.theme,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: t.woodDeep.withValues(alpha: 0.7),
        border: Border.all(color: t.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < options.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: value == i
                      ? t.accent.withValues(alpha: 0.85)
                      : Colors.transparent,
                ),
                child: Text(
                  options[i],
                  style: Bibliophile.label(12, theme: t).copyWith(
                    color: value == i ? t.woodDeep : t.ivory,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

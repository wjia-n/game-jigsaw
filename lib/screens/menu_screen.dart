import 'package:flutter/material.dart';
import '../engine/jigsaw_engine.dart';
import '../pictures.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/bibliophile.dart';
import '../theme/bibliophile_themes.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';
import '../services/iap_service.dart';

/// Main menu: carved JIGSAW plaque, clothbound folio spine stack for piece
/// counts, picture-folio picker, mode selector, leather-card buttons —
/// the Stitch "Bibliophile Library Jigsaw Menu" direction.
class MenuScreen extends StatefulWidget {
  final LibraryAudio audio;
  final JigsawSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late int _mode;
  late int _count;
  late int _picture;
  StoreService? _store;

  LibraryThemeDef get _t => LibraryThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _mode = s.lastMode;
    _count = s.lastPieceCount;
    _picture = s.lastPictureId;
    _store = StoreService()..init();
  }

  @override
  void dispose() {
    _store?.dispose();
    super.dispose();
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  int _dayOfYear() {
    final n = DateTime.now();
    return n.difference(DateTime(n.year, 1, 1)).inDays;
  }

  void _pickCount(int c) {
    widget.audio.click();
    setState(() => _count = c);
    widget.settings.setLastSetup(mode: _mode, pieceCount: _count, pictureId: _picture);
  }

  void _pickPicture(int i) {
    if (PictureFolio.isPro[i] && !widget.settings.isPro) {
      widget.audio.invalid();
      _goPro();
      return;
    }
    widget.audio.click();
    setState(() => _picture = i);
    widget.settings.setLastSetup(mode: _mode, pieceCount: _count, pictureId: _picture);
  }

  void _pickMode(int m) {
    widget.audio.click();
    setState(() {
      _mode = m;
      if (m == JigsawMode.daily) {
        _count = 48;
        _picture = _dayOfYear() % PictureFolio.names.length;
      }
    });
    widget.settings.setLastSetup(mode: _mode, pieceCount: _count, pictureId: _picture);
  }

  (int, int) _gridFor(int count) => switch (count) {
        24 => (6, 4),
        96 => (12, 8),
        192 => (16, 12),
        _ => (8, 6),
      };

  JigsawEngine _buildEngine() {
    final isDaily = _mode == JigsawMode.daily;
    final now = DateTime.now();
    final seed = isDaily
        ? now.year * 10000 + now.month * 100 + now.day
        : DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    final pic = isDaily ? _dayOfYear() % PictureFolio.names.length : _picture;
    final (cols, rows) = _gridFor(_count);
    return JigsawEngine(
      rows: rows,
      cols: cols,
      pictureId: pic,
      seed: seed,
      mode: _mode,
      pieceCount: _count,
      snapRadiusFraction: widget.settings.snapRadiusFraction,
    );
  }

  void _newPuzzle() {
    widget.audio.gameStart();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: widget.audio,
          settings: widget.settings,
          engine: _buildEngine(),
          isNewGame: true,
        ),
      ),
    );
  }

  void _continue() {
    final raw = widget.settings.readSave();
    if (raw == null) return;
    final engine = JigsawEngine.decode(raw);
    if (engine == null) {
      // Corrupt save: delete and start fresh (RULES.md 12).
      widget.settings.clearSave();
      widget.audio.invalid();
      return;
    }
    widget.audio.gameStart();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: widget.audio,
          settings: widget.settings,
          engine: engine,
          isNewGame: false,
        ),
      ),
    );
  }

  void _goPro() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: _store!,
        ),
      ),
    );
  }

  void _openSettings() {
    widget.audio.click();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: _store!,
        ),
      ),
    );
  }

  void _editName() {
    final t = _t;
    final ctrl = TextEditingController(text: widget.settings.profileName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.woodMid,
        title: Text('Puzzler name', style: Bibliophile.display(20, theme: t)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 20,
          style: Bibliophile.body(16, theme: t),
          decoration: InputDecoration(
            hintText: 'Your name',
            hintStyle: Bibliophile.body(14,
                theme: t, color: t.ivory.withValues(alpha: 0.4)),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: t.accent)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: t.accentLight, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: Bibliophile.label(14, theme: t)),
          ),
          TextButton(
            onPressed: () {
              widget.settings.setProfileName(ctrl.text);
              widget.audio.click();
              Navigator.of(context).pop();
            },
            child: Text('Save', style: Bibliophile.label(14, theme: t)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final dailyDone = s.dailyDone.contains(_todayKey());
    return WoodBackdrop(
      theme: t,
      child: LampGlow(
        theme: t,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: ListenableBuilder(
              listenable: s,
              builder: (_, _) => SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(
                  children: [
                    _plaque(t),
                    const SizedBox(height: 14),
                    _profileCard(t, s),
                    const SizedBox(height: 14),
                    _modeSelector(t),
                    const SizedBox(height: 14),
                    _folioStack(t),
                    const SizedBox(height: 14),
                    _pictureFolio(t, s),
                    const SizedBox(height: 18),
                    LeatherCardButton(
                      label: _mode == JigsawMode.daily && dailyDone
                          ? "TODAY'S PUZZLE — DONE ✓"
                          : _mode == JigsawMode.daily
                              ? "START TODAY'S PUZZLE"
                              : 'NEW PUZZLE',
                      theme: t,
                      onTap: _newPuzzle,
                    ),
                    const SizedBox(height: 10),
                    if (s.hasSave)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LeatherCardButton(
                          label: 'CONTINUE',
                          theme: t,
                          onTap: _continue,
                        ),
                      ),
                    LeatherCardButton(
                      label: 'SETTINGS',
                      theme: t,
                      onTap: _openSettings,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _smallLink(t, s.isPro ? 'PRO ACTIVE ✓' : 'GO PRO',
                            _goPro),
                        const SizedBox(width: 18),
                        _smallLink(t, 'THEMES', () {
                          widget.audio.click();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(
                                audio: widget.audio,
                                settings: widget.settings,
                                store: _store!,
                                openThemes: true,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _audioBar(t, s),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- sections
  Widget _plaque(LibraryThemeDef t) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.woodMid, t.woodDark, t.woodDeep],
          ),
          border: Border.all(color: t.accent, width: 3),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                offset: const Offset(0, 8),
                blurRadius: 14),
            BoxShadow(
                color: t.accentLight.withValues(alpha: 0.35),
                offset: const Offset(0, -1),
                blurRadius: 2),
          ],
        ),
        child: Column(
          children: [
            Text('JIGSAW', style: Bibliophile.display(40, theme: t)),
            const SizedBox(height: 2),
            Text('THE BIBLIOPHILE PUZZLE SANCTUARY',
                style: Bibliophile.label(11, theme: t)),
          ],
        ),
      );

  Widget _profileCard(LibraryThemeDef t, JigsawSettings s) => GestureDetector(
        onTap: _editName,
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: t.ivory.withValues(alpha: 0.92),
            border: Border.all(color: t.accent.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  offset: const Offset(0, 4),
                  blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    t.accentLight,
                    t.accent,
                    t.accentDark
                  ]),
                ),
                child: Icon(Icons.person, color: t.woodDeep, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.profileName,
                        style: Bibliophile.display(20, theme: t)
                            .copyWith(color: t.ink)),
                    Text('${s.wins} puzzles completed',
                        style: Bibliophile.body(12, theme: t)
                            .copyWith(color: t.ink.withValues(alpha: 0.65))),
                  ],
                ),
              ),
              Icon(Icons.edit, color: t.ink.withValues(alpha: 0.5), size: 20),
            ],
          ),
        ),
      );

  Widget _modeSelector(LibraryThemeDef t) {
    const modes = ['Classic', 'Timed', 'Relaxed', 'Daily'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MODE', style: Bibliophile.label(13, theme: t)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i < modes.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: i == modes.length - 1 ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => _pickMode(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _mode == i
                            ? t.accent.withValues(alpha: 0.85)
                            : t.woodDeep.withValues(alpha: 0.7),
                        border: Border.all(
                            color: _mode == i
                                ? t.accentLight
                                : t.accent.withValues(alpha: 0.4),
                            width: 2),
                        boxShadow: _mode == i
                            ? [
                                BoxShadow(
                                    color: t.lampGlow
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10)
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        modes[i],
                        style: Bibliophile.label(13, theme: t).copyWith(
                          color: _mode == i ? t.woodDeep : t.ivory,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_mode == JigsawMode.timed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Beat the par time: ${JigsawEngine.formatMs(JigsawEngine.parMs(_count))} for $_count pieces.',
              style: Bibliophile.body(12,
                  theme: t, color: t.ivory.withValues(alpha: 0.7)),
            ),
          ),
        if (_mode == JigsawMode.relaxed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No clock, no records — just the lamp, the mat and the pieces.',
              style: Bibliophile.body(12,
                  theme: t, color: t.ivory.withValues(alpha: 0.7)),
            ),
          ),
        if (_mode == JigsawMode.daily)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Today's shared puzzle: 48 pieces, same for everyone.",
              style: Bibliophile.body(12,
                  theme: t, color: t.ivory.withValues(alpha: 0.7)),
            ),
          ),
      ],
    );
  }

  static const _folios = [
    (24, 'Botanical Folio', Color(0xFF3E5C43)),
    (48, "Cartographer's Study", Color(0xFF6E2A30)),
    (96, 'Oxford Quadrangle', Color(0xFFC88A2E)),
    (192, 'Antiquarian Vault', Color(0xFF232B3A)),
  ];

  Widget _folioStack(LibraryThemeDef t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CHOOSE YOUR FOLIO', style: Bibliophile.label(13, theme: t)),
          const SizedBox(height: 8),
          for (final f in _folios) _spine(t, f.$1, f.$2, f.$3),
        ],
      );

  Widget _spine(LibraryThemeDef t, int count, String name, Color spine) {
    final sel = _count == count;
    final stars = widget.settings.stars(count);
    return GestureDetector(
      onTap: () => _pickCount(count),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(spine, Colors.white, 0.08)!,
              spine,
              Color.lerp(spine, Colors.black, 0.25)!
            ],
          ),
          border: Border.all(
              color: sel ? t.accentLight : t.accent.withValues(alpha: 0.45),
              width: sel ? 3 : 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 4),
                blurRadius: 8),
            if (sel)
              BoxShadow(
                  color: t.lampGlow.withValues(alpha: 0.3), blurRadius: 12),
          ],
        ),
        child: Row(
          children: [
            // Raised spine bands.
            Column(
              children: [
                for (int i = 0; i < 3; i++)
                  Container(
                    width: 8,
                    height: 6,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: Bibliophile.display(17, theme: t)
                          .copyWith(color: t.ivory)),
                  Text('$count pieces',
                      style: Bibliophile.body(12,
                          theme: t,
                          color: t.ivory.withValues(alpha: 0.7))),
                ],
              ),
            ),
            if (stars > 0)
              Text('★' * stars + '☆' * (3 - stars),
                  style: TextStyle(color: t.accentLight, fontSize: 14)),
            const SizedBox(width: 8),
            Text('$count',
                style: Bibliophile.display(26, theme: t)
                    .copyWith(color: t.accentLight)),
          ],
        ),
      ),
    );
  }

  Widget _pictureFolio(LibraryThemeDef t, JigsawSettings s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('PICTURE FOLIO', style: Bibliophile.label(13, theme: t)),
              const Spacer(),
              if (!s.isPro)
                Text('4 more with PRO',
                    style: Bibliophile.body(11,
                        theme: t,
                        color: t.accentLight.withValues(alpha: 0.8))),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.82,
            ),
            itemCount: PictureFolio.names.length,
            itemBuilder: (_, i) {
              final sel = _picture == i && _mode != JigsawMode.daily;
              final locked = PictureFolio.isPro[i] && !s.isPro;
              return GestureDetector(
                onTap: () => _pickPicture(i),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: sel
                                  ? t.accentLight
                                  : t.accent.withValues(alpha: 0.45),
                              width: sel ? 3 : 1.5),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.5),
                                offset: const Offset(0, 3),
                                blurRadius: 6),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            RepaintBoundary(
                              child: CustomPaint(
                                  painter: _ThumbPainter(i)),
                            ),
                            if (locked)
                              Container(
                                color: Colors.black.withValues(alpha: 0.55),
                                child: Icon(Icons.lock,
                                    color: t.accentLight, size: 22),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      PictureFolio.names[i],
                      style: Bibliophile.body(9,
                          theme: t,
                          color: t.ivory.withValues(alpha: 0.8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      );

  Widget _smallLink(LibraryThemeDef t, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: () {
          widget.audio.click();
          onTap();
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.accent.withValues(alpha: 0.6)),
            color: Colors.black.withValues(alpha: 0.3),
          ),
          child: Text(label, style: Bibliophile.label(13, theme: t)),
        ),
      );

  Widget _audioBar(LibraryThemeDef t, JigsawSettings s) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: t.woodDeep.withValues(alpha: 0.7),
          border:
              Border.all(color: t.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            BrassIconButton(
              icon: s.musicOn ? Icons.music_note : Icons.music_off,
              size: 44,
              theme: t,
              onTap: () {
                final v = !s.musicOn;
                s.setMusic(v);
                widget.audio.configure(
                    musicOn: v, sfxOn: s.sfxOn, volume: s.volume);
                if (v) {
                  widget.audio.startMenuMusic();
                } else {
                  widget.audio.stopMusic();
                }
              },
            ),
            const SizedBox(width: 10),
            BrassIconButton(
              icon: s.sfxOn ? Icons.volume_up : Icons.volume_off,
              size: 44,
              theme: t,
              onTap: () {
                final v = !s.sfxOn;
                s.setSfx(v);
                widget.audio.configure(
                    musicOn: s.musicOn, sfxOn: v, volume: s.volume);
                widget.audio.click();
              },
            ),
            const SizedBox(width: 6),
            Expanded(
              child: BeadSlider(
                value: s.volume,
                theme: t,
                onChanged: (v) {
                  s.setVolume(v);
                  widget.audio.configure(
                      musicOn: s.musicOn,
                      sfxOn: s.sfxOn,
                      volume: v);
                },
              ),
            ),
          ],
        ),
      );
}

class _ThumbPainter extends CustomPainter {
  final int id;
  _ThumbPainter(this.id);

  @override
  void paint(Canvas canvas, Size size) {
    PictureFolio.painter(id).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _ThumbPainter old) => old.id != id;
}

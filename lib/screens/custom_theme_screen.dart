import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/bibliophile.dart';
import '../theme/bibliophile_themes.dart';

/// PRO: custom theme creator — pick table wood, mat, lamplight, metal and
/// cardboard tones. Live preview, persisted per color.
class CustomThemeScreen extends StatefulWidget {
  final LibraryAudio audio;
  final JigsawSettings settings;

  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  LibraryThemeDef get _t => LibraryThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  // Curated library-friendly palette choices.
  static const List<Color> palette = [
    Color(0xFF3B2A1E), Color(0xFF5A4330), Color(0xFF0C0806),
    Color(0xFF4A1F14), Color(0xFF6E3220), Color(0xFF220D06),
    Color(0xFF7A5230), Color(0xFF9C7040), Color(0xFF3A2410),
    Color(0xFF232B3A), Color(0xFF36415A), Color(0xFF0A0D16),
    Color(0xFF2E3B22), Color(0xFF4A5A34), Color(0xFF111709),
    Color(0xFFC9A227), Color(0xFFE8C96A), Color(0xFF8A6D1A),
    Color(0xFFB87333), Color(0xFFE09A5E), Color(0xFF7A4A1E),
    Color(0xFFC0C6D4), Color(0xFFE8ECF5), Color(0xFF7E8698),
    Color(0xFFF3E8CB), Color(0xFFF9F3E0), Color(0xFF2B1D12),
    Color(0xFF2F5D43), Color(0xFF1C3A2A), Color(0xFF3D1F2E),
    Color(0xFF5E2E36), Color(0xFF24405A), Color(0xFF4A5A2E),
    Color(0xFFE8A94E), Color(0xFFF0C060), Color(0xFFEED27A),
    Color(0xFFB99B6E), Color(0xFFC49A6C), Color(0xFFD4B183),
  ];

  static const rows = [
    ('Table dark', 'woodDark'),
    ('Table lit', 'woodMid'),
    ('Deep shadow', 'woodDeep'),
    ('Accent metal', 'accent'),
    ('Metal light', 'accentLight'),
    ('Metal dark', 'accentDark'),
    ('Parchment text', 'ivory'),
    ('Ink', 'ink'),
    ('Puzzle mat', 'mat'),
    ('Mat shadow', 'matDark'),
    ('Lamplight', 'lampGlow'),
    ('Piece back', 'pieceBack'),
    ('Folio cloth', 'folio'),
  ];

  Future<void> _pick(String key, String label) async {
    final s = widget.settings;
    final current = Color(s.customColors[key]!);
    final chosen = await showDialog<Color>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: [
              _t.woodMid,
              _t.woodDeep,
            ]),
            border: Border.all(color: _t.accent, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pick $label',
                  style: Bibliophile.display(20, theme: _t)),
              const SizedBox(height: 14),
              SizedBox(
                width: 300,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: palette.length,
                  itemBuilder: (_, i) {
                    final c = palette[i];
                    final selected = c.toARGB32() == current.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        widget.audio.click();
                        Navigator.of(context).pop(c);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                            color: selected
                                ? _t.accentLight
                                : Colors.black.withValues(alpha: 0.4),
                            width: selected ? 3 : 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              WoodButton(
                label: 'Cancel',
                width: 160,
                fontSize: 15,
                theme: _t,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null && mounted) {
      widget.audio.click();
      await s.setCustomColor(key, chosen.toARGB32());
      // Selecting a custom color auto-applies the custom theme.
      await s.setTheme('custom');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final preview = s.customTheme;
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
                widget.audio.click();
                Navigator.of(context).pop();
              },
            ),
            title: Text('Theme Creator',
                style: Bibliophile.display(22, theme: t)),
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
                  // Live preview: mini table with mat and pieces.
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [preview.woodMid, preview.woodDark],
                      ),
                      border:
                          Border.all(color: preview.accent, width: 2),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            width: 190,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: preview.mat,
                              border: Border.all(
                                  color: preview.matDark, width: 3),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (int i = 0; i < 3; i++)
                                    Container(
                                      width: 34,
                                      height: 34,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        color: preview.pieceBack,
                                        border: Border.all(
                                            color: preview.accent,
                                            width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black.withValues(
                                                  alpha: 0.5),
                                              offset: const Offset(0, 3),
                                              blurRadius: 4),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Text('JIGSAW',
                                style: Bibliophile.display(20,
                                    theme: preview)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap a row to repaint that part of your library.',
                    style: Bibliophile.body(13,
                        theme: t,
                        color: t.ivory.withValues(alpha: 0.65)),
                  ),
                  const SizedBox(height: 8),
                  for (final r in rows)
                    GestureDetector(
                      onTap: () => _pick(r.$2, r.$1),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: t.woodDeep.withValues(alpha: 0.65),
                          border: Border.all(
                              color: t.accent.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(s.customColors[r.$2]!),
                                border: Border.all(
                                    color: t.accent, width: 2),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(r.$1,
                                  style:
                                      Bibliophile.body(16, theme: t)),
                            ),
                            Icon(Icons.chevron_right,
                                color: t.accentLight),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        widget.audio.click();
                        s.resetCustomColors();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: t.accent.withValues(alpha: 0.6)),
                        ),
                        child: Text('Restore Bibliophile Classic',
                            style: Bibliophile.label(13, theme: t)),
                      ),
                    ),
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
}

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/bibliophile.dart';
import '../theme/bibliophile_themes.dart';
import 'menu_screen.dart';

/// Launch splash: WAJIHA company moment, then the game splash
/// (logo + name + animated loading line + "Credits: WAJIHA").
class SplashScreen extends StatefulWidget {
  final LibraryAudio audio;
  final JigsawSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyDone = false;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the company splash shows, then start menu music.
    widget.audio.prewarm();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _companyDone = true);
    widget.audio.startMenuMusic();
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LibraryThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF0C0806),
      body: _companyDone
          ? _GameSplash(theme: theme, loader: _loader)
          : const _CompanySplash(),
    );
  }
}

/// WAJIHA company splash moment (official logo, untouched).
class _CompanySplash extends StatefulWidget {
  const _CompanySplash();

  @override
  State<_CompanySplash> createState() => _CompanySplashState();
}

class _CompanySplashState extends State<_CompanySplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/wajiha_logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),
            Text(
              'WAJIHA',
              style: Bibliophile.display(30).copyWith(letterSpacing: 6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Game splash: logo + name + animated loading line + credits.
class _GameSplash extends StatelessWidget {
  final LibraryThemeDef theme;
  final AnimationController loader;
  const _GameSplash({required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    return WoodBackdrop(
      theme: theme,
      child: LampGlow(
        theme: theme,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: theme.accent, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        offset: const Offset(0, 10),
                        blurRadius: 24,
                      ),
                      BoxShadow(
                        color: theme.lampGlow.withValues(alpha: 0.25),
                        offset: const Offset(0, -2),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/jigsaw_logo.png',
                      fit: BoxFit.cover),
                ),
                const SizedBox(height: 22),
                // Carved timber plaque with gold-leaf lettering.
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 34, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [theme.woodMid, theme.woodDark],
                    ),
                    border: Border.all(color: theme.accent, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          offset: const Offset(0, 6),
                          blurRadius: 12),
                    ],
                  ),
                  child: Text('JIGSAW',
                      style: Bibliophile.display(44, theme: theme)),
                ),
                const SizedBox(height: 8),
                Text(
                  'THE BIBLIOPHILE PUZZLE SANCTUARY',
                  style: Bibliophile.label(12, theme: theme),
                ),
                const SizedBox(height: 30),
                // Animated loading line.
                SizedBox(
                  width: 220,
                  child: AnimatedBuilder(
                    animation: loader,
                    builder: (_, _) => Column(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: Colors.black.withValues(alpha: 0.45),
                            border: Border.all(
                                color:
                                    theme.accent.withValues(alpha: 0.5)),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: loader.value.clamp(0.02, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                gradient: LinearGradient(
                                  colors: [
                                    theme.accentLight,
                                    theme.accent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          loader.value < 1
                              ? 'Setting out the pieces…'
                              : 'Ready!',
                          style: Bibliophile.body(13,
                              theme: theme,
                              color:
                                  theme.ivory.withValues(alpha: 0.75)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 44),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/wajiha_logo.png',
                      width: 30,
                      height: 30,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Credits: WAJIHA',
                      style: Bibliophile.label(14, theme: theme),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

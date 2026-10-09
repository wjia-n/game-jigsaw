import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bibliophile_themes.dart';

/// Persisted settings + profile + stats for Jigsaw. Survives app restarts.
///
/// Stores: audio toggles, player profile name, theme/appearance choices
/// (incl. custom theme colors), puzzle assist options, game-mode setup,
/// Pro unlock state, best records per piece count, and daily-puzzle state.
class JigsawSettings extends ChangeNotifier {
  static const _kMusic = 'jigsaw_music_on';
  static const _kSfx = 'jigsaw_sfx_on';
  static const _kVolume = 'jigsaw_volume';
  static const _kProfileName = 'jigsaw_profile_name';
  static const _kTheme = 'jigsaw_theme_id';
  static const _kMarks = 'jigsaw_apprentice_marks'; // 0 auto, 1 on, 2 off
  static const _kGenerousSnap = 'jigsaw_generous_snap';
  static const _kReference = 'jigsaw_show_reference';
  static const _kLastMode = 'jigsaw_last_mode';
  static const _kLastCount = 'jigsaw_last_count';
  static const _kLastPicture = 'jigsaw_last_picture';
  static const _kIsPro = 'jigsaw_is_pro';
  static const _kWins = 'jigsaw_wins';
  static const _kDaily = 'jigsaw_daily_done'; // StringList of yyyy-MM-dd
  static const _kCustomPrefix = 'jigsaw_custom_';
  static const _kSave = 'jigsaw_save_v1';
  static const _kBestTimePrefix = 'jigsaw_besttime_';
  static const _kBestMovesPrefix = 'jigsaw_bestmoves_';
  static const _kStarsPrefix = 'jigsaw_stars_';

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  String profileName = 'Puzzle Friend';
  String themeId = 'bibliophile';
  int apprenticeMarks = 0; // 0 auto, 1 on, 2 off
  bool generousSnap = false;
  bool showReference = true;
  int lastMode = 0; // 0 classic, 1 timed, 2 relaxed, 3 daily
  int lastPieceCount = 48;
  int lastPictureId = 0;
  bool isPro = false;
  int wins = 0;
  Set<String> dailyDone = {};

  /// Custom theme colors (ARGB ints). Defaults mirror Bibliophile Classic.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'woodDark': 0xFF3B2A1E,
    'woodMid': 0xFF5A4330,
    'woodDeep': 0xFF0C0806,
    'accent': 0xFFC9A227,
    'accentLight': 0xFFE8C96A,
    'accentDark': 0xFF8A6D1A,
    'ivory': 0xFFF3E8CB,
    'ink': 0xFF2B1D12,
    'mat': 0xFF2F5D43,
    'matDark': 0xFF1C3A2A,
    'lampGlow': 0xFFE8A94E,
    'pieceBack': 0xFFB99B6E,
    'folio': 0xFF3E5C43,
  };

  /// Builds the user-designed custom theme from stored colors.
  LibraryThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return LibraryThemeDef(
      id: 'custom',
      name: 'My Creation',
      woodDark: c('woodDark'),
      woodMid: c('woodMid'),
      woodDeep: c('woodDeep'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      ivory: c('ivory'),
      ink: c('ink'),
      mat: c('mat'),
      matDark: c('matDark'),
      lampGlow: c('lampGlow'),
      pieceBack: c('pieceBack'),
      folio: c('folio'),
    );
  }

  SharedPreferences? _prefs;

  /// Apprentice marks effective for a piece count: auto → ON for 24/48,
  /// OFF for 96/192 (RULES.md Section 7).
  bool marksFor(int pieceCount) {
    if (apprenticeMarks == 1) return true;
    if (apprenticeMarks == 2) return false;
    return pieceCount <= 48;
  }

  /// Snap radius as a fraction of the piece edge length: 28% default,
  /// 40% with the generous-snap accessibility option (RULES.md Section 11).
  double get snapRadiusFraction => generousSnap ? 0.40 : 0.28;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    profileName = p.getString(_kProfileName) ?? 'Puzzle Friend';
    themeId = p.getString(_kTheme) ?? 'bibliophile';
    apprenticeMarks = (p.getInt(_kMarks) ?? 0).clamp(0, 2);
    generousSnap = p.getBool(_kGenerousSnap) ?? false;
    showReference = p.getBool(_kReference) ?? true;
    lastMode = (p.getInt(_kLastMode) ?? 0).clamp(0, 3);
    lastPieceCount = p.getInt(_kLastCount) ?? 48;
    lastPictureId = p.getInt(_kLastPicture) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    wins = p.getInt(_kWins) ?? 0;
    dailyDone = Set.of(p.getStringList(_kDaily) ?? const []);
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setString(_kProfileName, profileName);
    await p.setString(_kTheme, themeId);
    await p.setInt(_kMarks, apprenticeMarks);
    await p.setBool(_kGenerousSnap, generousSnap);
    await p.setBool(_kReference, showReference);
    await p.setInt(_kLastMode, lastMode);
    await p.setInt(_kLastCount, lastPieceCount);
    await p.setInt(_kLastPicture, lastPictureId);
    await p.setBool(_kIsPro, isPro);
    await p.setInt(_kWins, wins);
    await p.setStringList(_kDaily, dailyDone.toList());
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (LibraryThemes.isProTheme(themeId)) {
      themeId = 'bibliophile';
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setProfileName(String name) async {
    final clean = name.trim();
    profileName = clean.isEmpty ? 'Puzzle Friend' : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && LibraryThemes.isProTheme(id)) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setApprenticeMarks(int v) async {
    apprenticeMarks = v.clamp(0, 2);
    notifyListeners();
    await _save();
  }

  Future<void> setGenerousSnap(bool v) async {
    generousSnap = v;
    notifyListeners();
    await _save();
  }

  Future<void> setShowReference(bool v) async {
    showReference = v;
    notifyListeners();
    await _save();
  }

  Future<void> setLastSetup(
      {required int mode, required int pieceCount, required int pictureId}) async {
    lastMode = mode.clamp(0, 3);
    lastPieceCount = pieceCount;
    lastPictureId = pictureId;
    notifyListeners();
    await _save();
  }

  // ------------------------------------------------------------ best records
  int bestTimeMs(int pieceCount) =>
      _prefs?.getInt('$_kBestTimePrefix$pieceCount') ?? 0;

  int bestMoves(int pieceCount) =>
      _prefs?.getInt('$_kBestMovesPrefix$pieceCount') ?? 0;

  int stars(int pieceCount) =>
      (_prefs?.getInt('$_kStarsPrefix$pieceCount') ?? 0).clamp(0, 3);

  /// Record a finished puzzle. Returns true if a new best time was set.
  Future<bool> recordWin({
    required int pieceCount,
    required int finalTimeMs,
    required int moves,
    required int starCount,
  }) async {
    final p = _prefs;
    wins++;
    var newRecord = false;
    if (p != null) {
      final prevTime = p.getInt('$_kBestTimePrefix$pieceCount') ?? 0;
      if (prevTime == 0 || finalTimeMs < prevTime) {
        await p.setInt('$_kBestTimePrefix$pieceCount', finalTimeMs);
        newRecord = true;
      }
      final prevMoves = p.getInt('$_kBestMovesPrefix$pieceCount') ?? 0;
      if (prevMoves == 0 || moves < prevMoves) {
        await p.setInt('$_kBestMovesPrefix$pieceCount', moves);
      }
      final prevStars = p.getInt('$_kStarsPrefix$pieceCount') ?? 0;
      if (starCount > prevStars) {
        await p.setInt('$_kStarsPrefix$pieceCount', starCount);
      }
    }
    notifyListeners();
    await _save();
    return newRecord;
  }

  Future<void> markDailyDone(String day) async {
    dailyDone.add(day);
    notifyListeners();
    await _save();
  }

  // ------------------------------------------------------------ save game
  bool get hasSave => (_prefs?.getString(_kSave) ?? '').isNotEmpty;

  Future<void> writeSave(String encoded) async {
    await _prefs?.setString(_kSave, encoded);
  }

  String? readSave() {
    final s = _prefs?.getString(_kSave);
    return (s == null || s.isEmpty) ? null : s;
  }

  Future<void> clearSave() async {
    await _prefs?.remove(_kSave);
    notifyListeners();
  }

  Future<void> resetRecords() async {
    final p = _prefs;
    if (p != null) {
      for (final count in [24, 48, 96, 192]) {
        await p.remove('$_kBestTimePrefix$count');
        await p.remove('$_kBestMovesPrefix$count');
        await p.remove('$_kStarsPrefix$count');
      }
    }
    wins = 0;
    dailyDone = {};
    notifyListeners();
    await _save();
  }
}

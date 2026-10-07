import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const JigsawApp());

class JigsawApp extends StatelessWidget {
  const JigsawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Jigsaw',
      tagline: 'Piece together gorgeous generated art. Pure cozy vibes.',
      emoji: '🧩',
      slug: 'jigsaw',
      howToPlay:
          '• Pick a picture: Sunset Glow, Mountain Air or Beach Day — all painted fresh in-app.\n• Choose 12, 24 or 48 pieces, then drag them onto the frame.\n• Pieces snap in with a happy buzz when they\'re close. The faint guide helps!\n• Finish the whole picture to win. No timer, no stress — just zen. ✨',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) =>
          JigsawScreen(players: players, callbacks: cb),
    );
  }
}

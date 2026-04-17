import 'package:flutter/material.dart';
import '../advance_gui/advance_gui.dart';

/// Simple wrapper for the advanced chess GUI
/// This maintains backward compatibility while using the new features
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdvancedGameScreen();
  }
}
import 'package:flutter/material.dart';

import '../../../domain/entities/player_character.dart';
import 'quiz_card.dart';

/// Lets the player pick who flies. Completes with the choice, or null when
/// the sheet is dismissed.
Future<PlayerCharacter?> showCharacterSheet(
  BuildContext context, {
  required PlayerCharacter current,
}) {
  return showModalBottomSheet<PlayerCharacter>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) => _CharacterSheet(current: current),
  );
}

class _CharacterSheet extends StatelessWidget {
  const _CharacterSheet({required this.current});

  final PlayerCharacter current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose your character',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: quizInk,
              ),
            ),
            const SizedBox(height: 16),
            _Option(
              character: PlayerCharacter.dash,
              selected: current == PlayerCharacter.dash,
              name: 'Dash',
              blurb: 'The Flutter mascot, flapping along.',
              icon: Icons.flutter_dash,
            ),
            const SizedBox(height: 10),
            _Option(
              character: PlayerCharacter.calavera,
              selected: current == PlayerCharacter.calavera,
              name: 'La Calavera',
              blurb:
                  'A Day of the Dead sugar skull in a hat full of marigolds.',
              icon: Icons.local_florist,
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.character,
    required this.selected,
    required this.name,
    required this.blurb,
    required this.icon,
  });

  final PlayerCharacter character;
  final bool selected;
  final String name;
  final String blurb;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE3F0FF) : const Color(0xFFF3F5F8),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pop(character),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, size: 36, color: quizAccent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: quizInk,
                      ),
                    ),
                    Text(
                      blurb,
                      style: const TextStyle(fontSize: 14, color: quizInk),
                    ),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle, color: quizAccent),
            ],
          ),
        ),
      ),
    );
  }
}

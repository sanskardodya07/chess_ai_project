import 'package:flutter/material.dart';

class CapturedPiecesRow extends StatelessWidget {
  final List<String> pieces;
  final int advantage;

  const CapturedPiecesRow({
    super.key,
    required this.pieces,
    required this.advantage,
  });

  @override
  Widget build(BuildContext context) {
    if (pieces.isEmpty) return const SizedBox(height: 24);

    // Sort: Q > R > B > N > P
    const order = {'Q': 0, 'R': 1, 'B': 2, 'N': 3, 'P': 4};
    final sorted = [...pieces]..sort((a, b) =>
        (order[a[1]] ?? 9).compareTo(order[b[1]] ?? 9));

    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Wrap(
            spacing: -4,
            children: sorted
                .map((p) => SizedBox(
                      width: 20,
                      height: 20,
                      child: Image.asset(
                        "assets/pieces/$p.png",
                        fit: BoxFit.contain,
                      ),
                    ))
                .toList(),
          ),
          if (advantage > 0) ...[
            const SizedBox(width: 6),
            Text(
              "+$advantage",
              style: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
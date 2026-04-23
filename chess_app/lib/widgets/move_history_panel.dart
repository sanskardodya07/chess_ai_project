import 'package:flutter/material.dart';
import '../models/move.dart';
import '../logic/move_notation.dart';

class MoveHistoryPanel extends StatefulWidget {
  final List<Move> moves;
  final int? viewingIndex;
  final bool isDesktop;
  final void Function(int?) onTap;

  const MoveHistoryPanel({
    super.key,
    required this.moves,
    required this.viewingIndex,
    required this.isDesktop,
    required this.onTap,
  });

  @override
  State<MoveHistoryPanel> createState() => _MoveHistoryPanelState();
}

class _MoveHistoryPanelState extends State<MoveHistoryPanel> {
  final ScrollController _sc = ScrollController();

  static const double _cellW = 68.0; // Slightly tighter for the single line
  static const double _numW  = 24.0;

  @override
  void didUpdateWidget(MoveHistoryPanel old) {
    super.didUpdateWidget(old);
    if (widget.moves.length != old.moves.length && widget.viewingIndex == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sc.hasClients) {
          _sc.animateTo(
            _sc.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  Widget _numCell(int n) => SizedBox(
        width: _numW,
        child: Text(
          "$n.",
          style: const TextStyle(color: Color(0xFF999999), fontSize: 13),
          textAlign: TextAlign.right,
        ),
      );

  Widget _moveCell(int idx) {
    if (idx >= widget.moves.length) return const SizedBox();

    final bool selected = widget.viewingIndex == idx;
    final String label = getMoveNotation(widget.moves[idx]);

    return GestureDetector(
      onTap: () => widget.onTap(selected ? null : idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: _cellW,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4A90D9).withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? const Color(0xFF4A90D9)
                : const Color(0xFF2C2C2C),
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildDesktop() {
    final pairs = ((widget.moves.length + 1) ~/ 2);
    if (pairs == 0) {
      return Center(
        child: Text(
          "No moves yet",
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      );
    }
    return ListView.builder(
      controller: _sc,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      itemCount: pairs,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(children: [
          _numCell(i + 1),
          const SizedBox(width: 4),
          _moveCell(i * 2),
          _moveCell(i * 2 + 1),
        ]),
      ),
    );
  }

  // UPDATED: Single line horizontal scroll for mobile
  Widget _buildMobile() {
    final pairs = ((widget.moves.length + 1) ~/ 2);
    if (pairs == 0) {
      return Center(
        child: Text(
          "No moves yet",
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      );
    }

    List<Widget> rowItems = [];
    for (int i = 0; i < pairs; i++) {
      rowItems.add(_numCell(i + 1));
      rowItems.add(const SizedBox(width: 4));
      rowItems.add(_moveCell(i * 2));
      if (i * 2 + 1 < widget.moves.length) {
        rowItems.add(_moveCell(i * 2 + 1));
      }
      rowItems.add(const SizedBox(width: 12)); // Gap between turns
    }

    return SingleChildScrollView(
      controller: _sc,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: rowItems,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.isDesktop ? _buildDesktop() : _buildMobile(),
      ),
    );
  }
}
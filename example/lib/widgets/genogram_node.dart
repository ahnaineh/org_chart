import 'package:flutter/material.dart';
import 'package:org_chart/org_chart.dart';
import '../models/family_member.dart';

class GenogramNode extends StatelessWidget {
  final NodeBuilderDetails<FamilyMember> details;
  final void Function(bool? hide) onToggleNodes;

  const GenogramNode({
    super.key,
    required this.details,
    required this.onToggleNodes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = details.item;

    return Container(
      decoration: BoxDecoration(
        boxShadow: details.isBeingDragged
            ? [BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 1)]
            : null,
      ),
      child: CustomPaint(
        painter: GenogramShapePainter(
          gender: member.gender,
          isDeceased: member.isDeceased,
          isSelected: details.isBeingDragged || details.isOverlapped,
          // birthType: member.birthType,
          color: _getNodeColor(theme, member),
          borderColor: _getBorderColor(theme, details.isOverlapped),
        ),
        child: SizedBox(
          width: 150,
          height: 150,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  member.name ?? 'Unknown',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _getTextColor(member.gender),
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                if (member.birthDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(member.birthDate!),
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (member.isDeceased && member.deathDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'D ${_formatDate(member.deathDate!)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (!_isRoot(member) && details.level > 1) ...[
                  const SizedBox(height: 4),
                  _buildCollapseButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton() {
    return IconButton(
      iconSize: 16,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(
        details.nodesHidden
            ? Icons.add_circle_outline
            : Icons.remove_circle_outline,
        color: _getTextColor(details.item.gender),
      ),
      onPressed: () => onToggleNodes(null),
    );
  }

  bool _isRoot(FamilyMember member) {
    return member.fatherId == null && member.motherId == null;
  }

  String _formatDate(DateTime date) {
    return '${date.year}';
  }

  Color _getNodeColor(ThemeData theme, FamilyMember member) {
    switch (member.gender) {
      case 0:
        return Colors.blue.shade50;
      case 1:
        return Colors.pink.shade50;
      case _:
        return Colors.black;
    }
  }

  Color _getBorderColor(ThemeData theme, bool isOverlapped) {
    if (isOverlapped) {
      return theme.colorScheme.primary;
    }
    return Colors.grey.shade500;
  }

  Color _getTextColor(int gender) {
    switch (gender) {
      case 0:
        return Colors.blue.shade900;
      case 1:
        return Colors.pink.shade900;
      case _:
        return Colors.black87;
    }
  }
}

/// Custom painter for genogram node shapes based on gender
class GenogramShapePainter extends CustomPainter {
  final int gender;
  final bool isDeceased;
  final bool isSelected;
  // final BirthType birthType;
  final Color color;
  final Color borderColor;

  GenogramShapePainter({
    required this.gender,
    required this.isDeceased,
    required this.isSelected,
    // required this.birthType,
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 1.5;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw shape based on gender
    switch (gender) {
      case 0:
        // Male: Square
        final square = Rect.fromCenter(
          center: center,
          width: size.width * 0.8,
          height: size.height * 0.8,
        );
        canvas.drawRect(square, paint);
        canvas.drawRect(square, borderPaint);
        break;

      case 1:
        // Female: Circle
        canvas.drawCircle(
          center,
          size.width * 0.4,
          paint,
        );
        canvas.drawCircle(
          center,
          size.width * 0.4,
          borderPaint,
        );
        break;

      case _:
        // Unknown: Diamond
        final path = Path();
        path.moveTo(center.dx, center.dy - size.height * 0.4); // Top
        path.lineTo(center.dx + size.width * 0.4, center.dy); // Right
        path.lineTo(center.dx, center.dy + size.height * 0.4); // Bottom
        path.lineTo(center.dx - size.width * 0.4, center.dy); // Left
        path.close();

        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;
    }

    // Draw deceased indicator (diagonal line through shape)
    if (isDeceased) {
      final deceasedPaint = Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Diagonal line from top-left to bottom-right
      canvas.drawLine(
          Offset(center.dx - size.width * 0.4, center.dy - size.height * 0.4),
          Offset(center.dx + size.width * 0.4, center.dy + size.height * 0.4),
          deceasedPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GenogramShapePainter oldDelegate) {
    return oldDelegate.gender != gender ||
        oldDelegate.isDeceased != isDeceased ||
        oldDelegate.isSelected != isSelected ||
        // oldDelegate.birthType != birthType ||
        oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor;
  }
}

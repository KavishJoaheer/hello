import 'package:flutter/material.dart';

enum CompanionIndicatorType { companion, incompatible }

class CompanionIndicator extends StatelessWidget {
  final CompanionIndicatorType type;
  final String text;
  final bool compact;

  const CompanionIndicator({
    super.key,
    required this.type,
    required this.text,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompanion = type == CompanionIndicatorType.companion;
    final color = isCompanion ? Colors.green : Colors.red;
    final icon = isCompanion ? Icons.favorite : Icons.block;
    final label = isCompanion ? 'Companion' : 'Avoid';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 16 : 20,
          height: compact ? 16 : 20,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: compact ? 10 : 12, color: color),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!compact)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                text,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

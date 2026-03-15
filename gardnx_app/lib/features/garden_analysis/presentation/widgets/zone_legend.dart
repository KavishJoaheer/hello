import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../domain/models/garden_zone.dart';

/// Horizontal scrollable color legend for zone types.
///
/// Each zone type is shown with its color swatch and label. Selected zones
/// are highlighted with a border.
class ZoneLegend extends StatelessWidget {
  final List<GardenZone> zones;
  final Set<String> selectedZoneIds;

  const ZoneLegend({
    super.key,
    required this.zones,
    this.selectedZoneIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    // Deduplicate by zone type for legend display.
    final uniqueTypes = <String, GardenZone>{};
    for (final zone in zones) {
      uniqueTypes.putIfAbsent(zone.type, () => zone);
    }

    if (uniqueTypes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: uniqueTypes.values.map((zone) {
            // Count how many zones of this type are selected.
            final selectedCount = zones
                .where(
                  (z) =>
                      z.type == zone.type &&
                      selectedZoneIds.contains(z.zoneId),
                )
                .length;
            final totalCount =
                zones.where((z) => z.type == zone.type).length;

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _LegendChip(
                color: zone.color,
                label: zone.displayLabel,
                count: totalCount > 1 ? '$selectedCount/$totalCount' : null,
                isActive: selectedCount > 0,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  final String? count;
  final bool isActive;

  const _LegendChip({
    required this.color,
    required this.label,
    this.count,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? color : AppColors.border,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 4),
            Text(
              '($count)',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

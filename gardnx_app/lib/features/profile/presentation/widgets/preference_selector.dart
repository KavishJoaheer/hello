import 'package:flutter/material.dart';

import '../../../../shared/enums/plant_type.dart';

/// A multi-select chip group for selecting plant type preferences.
///
/// Each [PlantType] is displayed as a [FilterChip] with the type's
/// brand color. Selected types are highlighted.
class PreferenceSelector extends StatelessWidget {
  /// Currently selected plant type values (e.g., `['vegetable', 'herb']`).
  final List<String> selectedTypes;

  /// Callback invoked with the updated list of selected type values
  /// whenever a chip is toggled.
  final ValueChanged<List<String>> onChanged;

  const PreferenceSelector({
    super.key,
    required this.selectedTypes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PlantType.values.map((type) {
        final isSelected = selectedTypes.contains(type.value);

        return FilterChip(
          label: Text(type.displayName),
          selected: isSelected,
          onSelected: (selected) {
            final updatedTypes = List<String>.from(selectedTypes);
            if (selected) {
              updatedTypes.add(type.value);
            } else {
              updatedTypes.remove(type.value);
            }
            onChanged(updatedTypes);
          },
          avatar: isSelected
              ? null
              : CircleAvatar(
                  backgroundColor: type.color.withValues(alpha: 0.3),
                  child: Icon(
                    _iconForType(type),
                    size: 14,
                    color: type.color,
                  ),
                ),
          selectedColor: type.color.withValues(alpha: 0.2),
          checkmarkColor: type.color,
          labelStyle: TextStyle(
            color: isSelected ? type.color : null,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
          side: BorderSide(
            color: isSelected ? type.color : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconForType(PlantType type) {
    switch (type) {
      case PlantType.vegetable:
        return Icons.eco_outlined;
      case PlantType.herb:
        return Icons.grass;
      case PlantType.fruit:
        return Icons.apple;
      case PlantType.flower:
        return Icons.local_florist_outlined;
    }
  }
}

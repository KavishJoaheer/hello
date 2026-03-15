import 'package:flutter/material.dart';

enum SunExposureOption { fullSun, partialShade, fullShade }

extension SunExposureOptionExt on SunExposureOption {
  String get label {
    switch (this) {
      case SunExposureOption.fullSun:
        return 'Full Sun';
      case SunExposureOption.partialShade:
        return 'Partial Shade';
      case SunExposureOption.fullShade:
        return 'Full Shade';
    }
  }

  String get value {
    switch (this) {
      case SunExposureOption.fullSun:
        return 'full_sun';
      case SunExposureOption.partialShade:
        return 'partial_shade';
      case SunExposureOption.fullShade:
        return 'full_shade';
    }
  }

  IconData get icon {
    switch (this) {
      case SunExposureOption.fullSun:
        return Icons.wb_sunny;
      case SunExposureOption.partialShade:
        return Icons.wb_cloudy;
      case SunExposureOption.fullShade:
        return Icons.cloud;
    }
  }

  static SunExposureOption fromValue(String value) {
    switch (value) {
      case 'full_sun':
        return SunExposureOption.fullSun;
      case 'partial_shade':
        return SunExposureOption.partialShade;
      case 'full_shade':
        return SunExposureOption.fullShade;
      default:
        return SunExposureOption.fullSun;
    }
  }
}

class SunExposurePicker extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const SunExposurePicker({
    super.key,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = {SunExposureOptionExt.fromValue(selectedValue)};

    return SegmentedButton<SunExposureOption>(
      segments: SunExposureOption.values
          .map(
            (option) => ButtonSegment<SunExposureOption>(
              value: option,
              label: Text(option.label),
              icon: Icon(option.icon),
            ),
          )
          .toList(),
      selected: selected,
      onSelectionChanged: (newSelected) {
        if (newSelected.isNotEmpty) {
          onChanged(newSelected.first.value);
        }
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

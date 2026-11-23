import 'package:flutter/material.dart';

import '../../../core/theme/atmos_text.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/hardware.dart';
import '../../../shared/sheets/component_sheet.dart';
import '../../../shared/widgets/dashed_border.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/clay_icon.dart';

/// Ligne de composant matériel. Les extensions non installées sont
/// présentées en pointillés.
class ComponentTile extends StatelessWidget {
  const ComponentTile({
    super.key,
    required this.component,
    required this.state,
    required this.onTap,
  });

  final HardwareComponent component;
  final ComponentState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final optional = state == ComponentState.notInstalled;
    final radius = BorderRadius.circular(22);

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        children: [
          ClayIcon(glyphForComponent(component.id), size: 46, muted: optional),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.name,
                  style: AtmosText.heading.copyWith(
                    fontSize: 15.5,
                    color: optional ? Palette.inkSoft : Palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(component.role, style: AtmosText.caption),
                const SizedBox(height: 8),
                StateTag(state: state),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Palette.inkMuted),
        ],
      ),
    );

    return Pressable(
      onTap: onTap,
      borderRadius: radius,
      semanticLabel: '${component.name}, ${component.role}. ${state.label}.',
      child: optional
          ? DashedBorder(
              color: Palette.inkMuted.fade(0.5),
              child: ExcludeSemantics(child: content),
            )
          : Ink(
              decoration: BoxDecoration(
                color: Palette.surface,
                borderRadius: radius,
                border: Border.all(color: Palette.line),
              ),
              child: ExcludeSemantics(child: content),
            ),
    );
  }
}

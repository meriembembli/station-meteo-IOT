import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/atmos_text.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/alerts.dart';
import '../../../data/models/metric.dart';
import '../../../shared/widgets/atmos_toggle.dart';
import '../../../shared/widgets/clay_icon.dart';

/// Carte de réglage des seuils d'un capteur : seuil bas et seuil haut,
/// modifiables au curseur double ou pas à pas (− / +), chacun activable.
/// Les changements sont appliqués immédiatement (enregistrement local).
class ThresholdCard extends StatefulWidget {
  const ThresholdCard({
    super.key,
    required this.metric,
    required this.low,
    required this.high,
    required this.current,
    required this.onChanged,
  });

  final MetricKind metric;
  final AlertRule? low;
  final AlertRule? high;

  /// Valeur actuelle mesurée (null pendant le chargement).
  final double? current;
  final ValueChanged<AlertRule> onChanged;

  @override
  State<ThresholdCard> createState() => _ThresholdCardState();
}

class _ThresholdCardState extends State<ThresholdCard> {
  late double _low = _initialLow();
  late double _high = _initialHigh();
  bool _dragging = false;

  MetricKind get _m => widget.metric;

  double _initialLow() => _clamp(widget.low?.threshold ?? _m.minValue);
  double _initialHigh() => _clamp(widget.high?.threshold ?? _m.maxValue);

  double _clamp(double v) => v.clamp(_m.minValue, _m.maxValue).toDouble();

  double _snap(double v) => _clamp((v / _m.step).round() * _m.step);

  @override
  void didUpdateWidget(ThresholdCard old) {
    super.didUpdateWidget(old);
    if (!_dragging) {
      _low = _initialLow();
      _high = _initialHigh();
    }
  }

  void _commit({bool low = true, bool high = true}) {
    final l = widget.low;
    final h = widget.high;
    if (low && l != null && l.threshold != _low) {
      widget.onChanged(l.copyWith(threshold: _low));
    }
    if (high && h != null && h.threshold != _high) {
      widget.onChanged(h.copyWith(threshold: _high));
    }
  }

  void _nudge({required bool isLow, required int direction}) {
    HapticFeedback.selectionClick();
    final step = _m.step;
    setState(() {
      if (isLow) {
        _low = _snap(_low + direction * step);
        if (_low > _high - step) _low = _snap(_high - step);
      } else {
        _high = _snap(_high + direction * step);
        if (_high < _low + step) _high = _snap(_low + step);
      }
    });
    _commit(low: isLow, high: !isLow);
  }

  void _toggle(AlertRule? rule, bool value) {
    if (rule == null) return;
    widget.onChanged(rule.copyWith(enabled: value));
  }

  @override
  Widget build(BuildContext context) {
    final m = _m;
    final current = widget.current;
    final lowOn = widget.low?.enabled ?? false;
    final highOn = widget.high?.enabled ?? false;

    final (String status, Color statusColor) = switch (current) {
      null => ('En attente de mesure', Palette.inkMuted),
      final double v when lowOn && v < _low => (
          'Sous le seuil bas',
          Palette.apricot
        ),
      final double v when highOn && v > _high => (
          'Au-dessus du seuil haut',
          Palette.apricot
        ),
      _ when !lowOn && !highOn => ('Surveillance désactivée', Palette.inkMuted),
      _ => ('Dans la plage', Palette.online),
    };

    final divisions = ((m.maxValue - m.minValue) / m.step).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : capteur, valeur actuelle, état.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClayIcon(m.glyph, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.longLabel, style: AtmosText.heading),
                    const SizedBox(height: 2),
                    Text('Capteur ${m.sensor} · unité ${m.unit}',
                        style: AtmosText.caption),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    current == null ? '—' : m.formatWithUnit(current),
                    style: AtmosText.number(18),
                  ),
                  const SizedBox(height: 2),
                  Text('actuel',
                      style: AtmosText.caption.copyWith(fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    status,
                    style: AtmosText.label.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Seuils bas et haut.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _BoundEditor(
                    label: 'Seuil bas',
                    hint: 'Alerte en dessous',
                    metric: m,
                    value: _low,
                    enabled: lowOn,
                    available: widget.low != null,
                    onMinus: () => _nudge(isLow: true, direction: -1),
                    onPlus: () => _nudge(isLow: true, direction: 1),
                    onToggle: (v) => _toggle(widget.low, v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BoundEditor(
                    label: 'Seuil haut',
                    hint: 'Alerte au-dessus',
                    metric: m,
                    value: _high,
                    enabled: highOn,
                    available: widget.high != null,
                    onMinus: () => _nudge(isLow: false, direction: -1),
                    onPlus: () => _nudge(isLow: false, direction: 1),
                    onToggle: (v) => _toggle(widget.high, v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Curseur double pour régler la plage d'un geste.
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              activeTrackColor: m.color,
              inactiveTrackColor: Palette.surfaceHigh,
              thumbColor: Colors.white,
              overlayColor: m.color.fade(0.18),
              valueIndicatorColor: Palette.sheet,
              showValueIndicator: ShowValueIndicator.onDrag,
            ),
            child: RangeSlider(
              values: RangeValues(_low, _high),
              min: m.minValue,
              max: m.maxValue,
              divisions: divisions,
              labels:
                  RangeLabels(m.formatWithUnit(_low), m.formatWithUnit(_high)),
              semanticFormatterCallback: (v) => m.formatWithUnit(v),
              onChangeStart: (_) => _dragging = true,
              onChanged: (v) => setState(() {
                _low = _snap(v.start);
                _high = _snap(v.end);
              }),
              onChangeEnd: (_) {
                _dragging = false;
                _commit();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(m.formatWithUnit(m.minValue),
                    style: AtmosText.caption.copyWith(fontSize: 11.5)),
                const Spacer(),
                Text(m.formatWithUnit(m.maxValue),
                    style: AtmosText.caption.copyWith(fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoundEditor extends StatelessWidget {
  const _BoundEditor({
    required this.label,
    required this.hint,
    required this.metric,
    required this.value,
    required this.enabled,
    required this.available,
    required this.onMinus,
    required this.onPlus,
    required this.onToggle,
  });

  final String label;
  final String hint;
  final MetricKind metric;
  final double value;
  final bool enabled;
  final bool available;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 10),
      decoration: BoxDecoration(
        color: enabled ? metric.soft : Palette.paperDeep,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: enabled ? metric.color.fade(0.45) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: AtmosText.label.copyWith(color: Palette.ink)),
              ),
              AtmosToggle(
                value: enabled,
                onChanged: available ? onToggle : null,
                semanticLabel: '$label de ${metric.withArticle}',
              ),
            ],
          ),
          Text(hint, style: AtmosText.caption.copyWith(fontSize: 11)),
          const SizedBox(height: 6),
          AnimatedOpacity(
            opacity: enabled ? 1 : 0.55,
            duration: const Duration(milliseconds: 180),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: metric.formatValue(value),
                      style: AtmosText.display(30)),
                  TextSpan(
                    text: ' ${metric.unit}',
                    style: AtmosText.caption
                        .copyWith(fontSize: 14, color: Palette.inkSoft),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StepButton(
                icon: Icons.remove,
                semanticLabel: 'Diminuer le $label',
                onTap: available ? onMinus : null,
              ),
              const SizedBox(width: 8),
              _StepButton(
                icon: Icons.add,
                semanticLabel: 'Augmenter le $label',
                onTap: available ? onPlus : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton(
      {required this.icon, required this.semanticLabel, required this.onTap});

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: Palette.surfaceHigh,
        shape: const CircleBorder(side: BorderSide(color: Palette.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon,
                size: 20,
                color: onTap == null ? Palette.inkMuted : Palette.ink),
          ),
        ),
      ),
    );
  }
}

/// Règle de pluie : présence uniquement, pas de seuil numérique.
class RainRuleCard extends StatelessWidget {
  const RainRuleCard(
      {super.key,
      required this.rule,
      required this.detected,
      required this.onChanged});

  final AlertRule rule;
  final bool? detected;
  final ValueChanged<AlertRule> onChanged;

  @override
  Widget build(BuildContext context) {
    final m = rule.metric;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Palette.line),
      ),
      child: Row(
        children: [
          ClayIcon(m.glyph, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.longLabel, style: AtmosText.heading),
                const SizedBox(height: 2),
                Text(
                  'Présence uniquement, pas de seuil chiffré. '
                  'Actuellement : ${detected == null ? '—' : (detected! ? 'pluie détectée' : 'aucune pluie')}.',
                  style: AtmosText.caption,
                ),
              ],
            ),
          ),
          AtmosToggle(
            value: rule.enabled,
            onChanged: (v) => onChanged(rule.copyWith(enabled: v)),
            semanticLabel: 'Alerte en cas de pluie détectée',
          ),
        ],
      ),
    );
  }
}

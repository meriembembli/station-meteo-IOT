import 'package:atmos/app.dart';
import 'package:atmos/data/models/history.dart';
import 'package:atmos/data/models/metric.dart';
import 'package:atmos/data/models/snapshot.dart';
import 'package:atmos/data/repositories/demo_history_generator.dart';
import 'package:atmos/data/repositories/demo_station_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DemoStationRepository _repo() => DemoStationRepository(
      tick: null,
      initialDelay: const Duration(milliseconds: 10),
      networkDelay: const Duration(milliseconds: 10),
    );

void main() {
  testWidgets('chargement puis station avec les valeurs de démonstration',
      (tester) async {
    await tester.pumpWidget(AtmosApp(repository: _repo()));
    expect(find.text('Connexion à la station…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Jardin — Station 01'), findsWidgets);
    expect(find.text('Mode démo'), findsOneWidget);
    expect(find.text('En ligne'), findsWidgets);

    // Démonte l'application pour arrêter les minuteries.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('navigation vers les quatre destinations', (tester) async {
    await tester.pumpWidget(AtmosApp(repository: _repo()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Historique').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Mesures enregistrées'), findsOneWidget);

    await tester.tap(find.text('Alertes').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Surveillance des seuils'), findsOneWidget);

    await tester.tap(find.text('Équipement').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Composants installés'), findsOneWidget);
    expect(find.text('Humidité du sol'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('les seuils des capteurs sont modifiables', (tester) async {
    await tester.pumpWidget(AtmosApp(repository: _repo()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Alertes').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Seuils des capteurs'), findsOneWidget);

    // Premier « + » : seuil bas de la température (3 °C → 3,5 °C).
    final plus = find.byIcon(Icons.add).first;
    await tester.ensureVisible(plus);
    await tester.pump();
    await tester.tap(plus);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('3,5'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
  });

  test('historique simulé : raccord avec la valeur actuelle', () {
    final now = DateTime(2026, 11, 16, 14, 30);
    final snap = StationSnapshot(
      temperature: 24.6,
      humidity: 62,
      pressure: 1013,
      light: 74,
      rainDetected: false,
      measuredAt: now,
    );
    for (final m in MetricKind.values) {
      for (final r in HistoryRange.values) {
        final pts = generateDemoHistory(m, r, snap);
        expect(pts, isNotEmpty);
        expect(pts.last.value, closeTo(snap.valueOf(m), 1e-9));
        expect(pts.last.time, now);
        for (final p in pts) {
          expect(p.value, inInclusiveRange(m.minValue, m.maxValue));
        }
      }
    }
  });

  test('pas de mesure inventée : pluie binaire, lumière relative', () {
    expect(MetricKind.rain.unit, isEmpty);
    expect(MetricKind.light.unit, '%');
    expect(MetricKind.rain.formatValue(1), 'Détectée');
    expect(MetricKind.rain.formatValue(0), 'Non détectée');
  });
}

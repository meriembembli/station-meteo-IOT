import '../models/alerts.dart';
import '../models/hardware.dart';
import '../models/history.dart';
import '../models/metric.dart';
import '../models/snapshot.dart';

/// Contrat entre l'interface et la source de données.
///
/// [DemoStationRepository] l'implémente avec des données simulées.
/// Une future `FirebaseStationRepository` pourra l'implémenter à partir de
/// Firebase Realtime Database sans modifier les widgets.
abstract interface class StationRepository {
  /// Flux des derniers relevés. Le premier élément est le dernier relevé
  /// connu ; les suivants arrivent à chaque nouvelle mesure.
  Stream<StationSnapshot> watchSnapshot();

  /// Demande une relecture du dernier relevé.
  /// Renvoie `true` si une mesure plus récente a été reçue.
  Future<bool> refresh();

  Future<List<HistoryPoint>> fetchHistory(
      MetricKind metric, HistoryRange range);

  Future<List<AlertRule>> fetchRules();
  Future<void> saveRule(AlertRule rule);

  Future<List<AlertEvent>> fetchEvents();
  Future<void> saveEvent(AlertEvent event);

  Future<DeviceInfo> fetchDevice();
  Future<void> renameStation(String name);

  void dispose();
}

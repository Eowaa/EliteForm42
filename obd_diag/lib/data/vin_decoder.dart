import 'dart:convert';

import 'package:http/http.dart' as http;

/// Von der VIN abgeleitete Fahrzeugdaten.
class VehicleInfo {
  const VehicleInfo({
    required this.vin,
    this.make,
    this.model,
    this.modelYear,
    this.engine,
    this.fuelType,
    this.bodyClass,
    this.plant,
  });

  final String vin;
  final String? make;
  final String? model;
  final String? modelYear;
  final String? engine;
  final String? fuelType;
  final String? bodyClass;
  final String? plant;

  /// Fällt auf die VIN zurück, solange nichts dekodiert wurde.
  String get displayName {
    final parts = [modelYear, make, model]
        .whereType<String>()
        .where((s) => s.isNotEmpty);
    return parts.isEmpty ? vin : parts.join(' ');
  }
}

/// Dekodiert eine VIN über die vPIC-Datenbank der US-Verkehrsbehörde NHTSA.
///
/// Kostenlos, ohne API-Schlüssel, Public Domain. Für Fahrzeuge, die auch in
/// den USA verkauft wurden, sind die Daten sehr vollständig; bei rein
/// europäischen Modellen bleiben Felder leer. Deshalb wird immer ein Objekt
/// mit der VIN geliefert und nur gefüllt, was gefunden wurde.
class VinDecoder {
  VinDecoder({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _base = 'https://vpic.nhtsa.dot.gov/api/vehicles';

  Future<VehicleInfo> decode(String vin) async {
    final uri = Uri.parse('$_base/decodevinvalues/$vin?format=json');

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return VehicleInfo(vin: vin);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final results = body['Results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return VehicleInfo(vin: vin);

      final r = results.first as Map<String, dynamic>;
      String? field(String key) {
        final value = r[key];
        if (value is! String || value.trim().isEmpty) return null;
        return value.trim();
      }

      return VehicleInfo(
        vin: vin,
        make: field('Make'),
        model: field('Model'),
        modelYear: field('ModelYear'),
        engine: field('EngineModel') ?? field('DisplacementL'),
        fuelType: field('FuelTypePrimary'),
        bodyClass: field('BodyClass'),
        plant: field('PlantCity'),
      );
    } catch (_) {
      // Offline in der Werkstatt ist der Normalfall, kein Fehler.
      return VehicleInfo(vin: vin);
    }
  }

  void close() => _client.close();
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Pantalla que muestra la posición actual de la Estación Espacial
/// Internacional (ISS) en tiempo real.
///
/// Usa la API pública y GRATUITA de Open Notify (no requiere API key):
///   http://api.open-notify.org/iss-now.json
///
/// Esa API devuelve únicamente latitud, longitud y un timestamp.
/// El resto de datos de la estación (altitud, velocidad orbital,
/// órbitas por día) son valores de referencia conocidos y estables,
/// ya que la API no los provee.
class IssTrackerScreen extends StatefulWidget {
  const IssTrackerScreen({super.key});

  @override
  State<IssTrackerScreen> createState() => _IssTrackerScreenState();
}

class _IssTrackerScreenState extends State<IssTrackerScreen> {
  // API gratuita y sin key, servida por HTTPS (necesario para que funcione
  // tanto en la vista previa web de FlutLab como en apps móviles reales).
  static const String _issApiUrl = 'https://api.wheretheiss.at/v1/satellites/25544';

  double? _lat;
  double? _lon;
  double? _altitude;
  double? _velocity;
  DateTime? _updatedAt;
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchIssPosition();
    // Refresca automáticamente cada 5 segundos.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchIssPosition(showLoading: false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchIssPosition({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _loading = true);
    }
    try {
      final response = await http
          .get(Uri.parse(_issApiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final lat = double.parse(data['latitude'].toString());
        final lon = double.parse(data['longitude'].toString());
        final altitude = double.parse(data['altitude'].toString());
        final velocity = double.parse(data['velocity'].toString());
        final ts = (data['timestamp'] as num).toInt();

        setState(() {
          _lat = lat;
          _lon = lon;
          _altitude = altitude;
          _velocity = velocity;
          _updatedAt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
          _loading = false;
          _error = null;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'No se pudo obtener la posición (código ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Sin conexión o el servicio no respondió. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF344C63),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Row(
          children: [
            Icon(Icons.satellite_alt_rounded, color: Colors.white),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Rastreador ISS Real-Time',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchIssPosition(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Colors.cyanAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.public_rounded, color: Color(0xFF0D1B2A), size: 46),
              ),
              const SizedBox(height: 22),
              const Text(
                '🛸 Posición Actual de la ISS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _updatedAt == null
                    ? 'Actualizando...'
                    : 'Actualizado: ${dateFormat.format(_updatedAt!.toLocal())}',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
              ),
              const SizedBox(height: 26),
              if (_loading) const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
              if (!_loading && _error != null) _ErrorCard(
                message: _error!,
                onRetry: () => _fetchIssPosition(),
              ),
              if (!_loading && _error == null) ...[
                _InfoCard(
                  icon: Icons.location_on_rounded,
                  iconBg: const Color(0xFF7A2E2E),
                  iconColor: Colors.redAccent,
                  label: 'Latitud',
                  value: '${_lat?.toStringAsFixed(8)}°',
                  helper: 'Posición Norte/Sur respecto al Ecuador',
                ),
                const SizedBox(height: 18),
                _InfoCard(
                  icon: Icons.explore_rounded,
                  iconBg: const Color(0xFF1A4A4A),
                  iconColor: Colors.tealAccent,
                  label: 'Longitud',
                  value: '${_lon?.toStringAsFixed(8)}°',
                  helper: 'Posición Este/Oeste respecto al Meridiano',
                ),
              ],
              const SizedBox(height: 18),
              _StationDataCard(altitude: _altitude, velocity: _velocity),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String helper;

  const _InfoCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(helper,
                    style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StationDataCard extends StatelessWidget {
  final double? altitude;
  final double? velocity;

  const _StationDataCard({this.altitude, this.velocity});

  @override
  Widget build(BuildContext context) {
    // Si la API ya trajo datos reales, se muestran esos; si no, se usan
    // valores de referencia conocidos como respaldo.
    final altitudeText =
        altitude != null ? '${altitude!.toStringAsFixed(1)} km' : '~408 km';
    final velocityText = velocity != null
        ? '${velocity!.toStringAsFixed(0)} km/h'
        : '~27,600 km/h';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.lightBlueAccent),
          const SizedBox(height: 10),
          const Text(
            'Datos de la Estación',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.12)),
          const SizedBox(height: 6),
          _StatRow(label: 'Altitud actual', value: altitudeText),
          _StatRow(label: 'Velocidad orbital', value: velocityText),
          const _StatRow(label: 'Órbitas por día', value: '~15.5'),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14.5)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 32),
          const SizedBox(height: 10),
          Text(message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

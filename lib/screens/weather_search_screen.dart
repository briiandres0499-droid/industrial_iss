import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Pantalla para buscar cualquier lugar de Colombia y ver su
/// ubicación (latitud/longitud) e información climática actualizada
/// (temperatura, humedad, viento, condición del cielo).
///
/// Usa la API pública y GRATUITA de Open-Meteo (no requiere API key,
/// HTTPS, sin límite estricto de uso para proyectos personales):
///   Geocodificación: https://geocoding-api.open-meteo.com/v1/search
///   Clima actual:    https://api.open-meteo.com/v1/forecast
class WeatherSearchScreen extends StatefulWidget {
  const WeatherSearchScreen({super.key});

  @override
  State<WeatherSearchScreen> createState() => _WeatherSearchScreenState();
}

class _PlaceResult {
  final String name;
  final String? admin1; // departamento
  final String country;
  final double lat;
  final double lon;

  _PlaceResult({
    required this.name,
    required this.admin1,
    required this.country,
    required this.lat,
    required this.lon,
  });
}

class _WeatherData {
  final double temperature;
  final double humidity;
  final double windSpeed;
  final int weatherCode;
  final DateTime updatedAt;

  _WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.updatedAt,
  });
}

class _WeatherSearchScreenState extends State<WeatherSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _searching = false;
  String? _searchError;
  List<_PlaceResult> _results = [];

  _PlaceResult? _selectedPlace;
  _WeatherData? _weather;
  bool _loadingWeather = false;
  String? _weatherError;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query.trim());
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final uri = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search'
        '?name=${Uri.encodeComponent(query)}&count=10&language=es&format=json',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawResults = (data['results'] as List<dynamic>?) ?? [];

        final colombiaResults = rawResults
            .map((r) => r as Map<String, dynamic>)
            .where((r) => r['country_code'] == 'CO')
            .map((r) => _PlaceResult(
                  name: r['name'] as String,
                  admin1: r['admin1'] as String?,
                  country: r['country'] as String? ?? 'Colombia',
                  lat: (r['latitude'] as num).toDouble(),
                  lon: (r['longitude'] as num).toDouble(),
                ))
            .toList();

        setState(() {
          _results = colombiaResults;
          _searching = false;
          _searchError = colombiaResults.isEmpty
              ? 'No se encontraron lugares en Colombia con ese nombre.'
              : null;
        });
      } else {
        setState(() {
          _searching = false;
          _searchError = 'No se pudo buscar (código ${response.statusCode}).';
        });
      }
    } catch (e) {
      setState(() {
        _searching = false;
        _searchError = 'Sin conexión o el servicio no respondió.';
      });
    }
  }

  Future<void> _selectPlace(_PlaceResult place) async {
    setState(() {
      _selectedPlace = place;
      _results = [];
      _searchController.clear();
      _loadingWeather = true;
      _weatherError = null;
      _weather = null;
    });
    await _fetchWeather(place);
  }

  Future<void> _fetchWeather(_PlaceResult place) async {
    setState(() {
      _loadingWeather = true;
      _weatherError = null;
    });
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${place.lat}&longitude=${place.lon}'
        '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m'
        '&timezone=auto',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>;

        setState(() {
          _weather = _WeatherData(
            temperature: (current['temperature_2m'] as num).toDouble(),
            humidity: (current['relative_humidity_2m'] as num).toDouble(),
            windSpeed: (current['wind_speed_10m'] as num).toDouble(),
            weatherCode: (current['weather_code'] as num).toInt(),
            updatedAt: DateTime.parse(current['time'] as String),
          );
          _loadingWeather = false;
        });
      } else {
        setState(() {
          _loadingWeather = false;
          _weatherError = 'No se pudo obtener el clima (código ${response.statusCode}).';
        });
      }
    } catch (e) {
      setState(() {
        _loadingWeather = false;
        _weatherError = 'Sin conexión o el servicio no respondió.';
      });
    }
  }

  // Traduce el código meteorológico WMO a una descripción y un ícono.
  static const Map<int, String> _weatherDescriptions = {
    0: 'Cielo despejado',
    1: 'Mayormente despejado',
    2: 'Parcialmente nublado',
    3: 'Nublado',
    45: 'Niebla',
    48: 'Niebla con escarcha',
    51: 'Llovizna ligera',
    53: 'Llovizna moderada',
    55: 'Llovizna intensa',
    61: 'Lluvia ligera',
    63: 'Lluvia moderada',
    65: 'Lluvia intensa',
    71: 'Nevada ligera',
    73: 'Nevada moderada',
    75: 'Nevada intensa',
    80: 'Chubascos ligeros',
    81: 'Chubascos moderados',
    82: 'Chubascos intensos',
    95: 'Tormenta eléctrica',
    96: 'Tormenta con granizo',
    99: 'Tormenta fuerte con granizo',
  };

  static IconData _weatherIcon(int code) {
    if (code == 0 || code == 1) return Icons.wb_sunny_rounded;
    if (code == 2) return Icons.wb_cloudy_rounded;
    if (code == 3) return Icons.cloud_rounded;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 65) return Icons.grain_rounded;
    if (code >= 71 && code <= 75) return Icons.ac_unit_rounded;
    if (code >= 80 && code <= 82) return Icons.beach_access_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    return Icons.help_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF344C63),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Row(
          children: [
            Icon(Icons.travel_explore_rounded, color: Colors.white),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Clima y Ubicación - Colombia',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _SearchBox(
                controller: _searchController,
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 14),
              if (_searching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                ),
              if (!_searching && _results.isNotEmpty)
                _ResultsList(results: _results, onSelect: _selectPlace),
              if (!_searching && _searchError != null && _results.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _searchError!,
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedPlace == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.location_searching_rounded,
                color: Colors.white.withOpacity(0.25), size: 64),
            const SizedBox(height: 16),
            Text(
              'Busca una ciudad o municipio de Colombia\npara ver su ubicación y clima actual',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final place = _selectedPlace!;

    return Column(
      children: [
        const SizedBox(height: 4),
        Text(
          place.name,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          [if (place.admin1 != null) place.admin1!, place.country].join(', '),
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
        ),
        const SizedBox(height: 20),
        if (_loadingWeather)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          ),
        if (!_loadingWeather && _weatherError != null)
          _ErrorCard(message: _weatherError!, onRetry: () => _fetchWeather(place)),
        if (!_loadingWeather && _weatherError == null && _weather != null) ...[
          _InfoCard(
            icon: Icons.location_on_rounded,
            iconBg: const Color(0xFF7A2E2E),
            iconColor: Colors.redAccent,
            label: 'Latitud / Longitud',
            value:
                '${place.lat.toStringAsFixed(5)}°, ${place.lon.toStringAsFixed(5)}°',
            helper: 'Coordenadas geográficas del lugar',
          ),
          const SizedBox(height: 16),
          _InfoCard(
            icon: _weatherIcon(_weather!.weatherCode),
            iconBg: const Color(0xFF1A4A4A),
            iconColor: Colors.tealAccent,
            label: 'Temperatura',
            value: '${_weather!.temperature.toStringAsFixed(1)} °C',
            helper: _weatherDescriptions[_weather!.weatherCode] ?? 'Condición actual',
          ),
          const SizedBox(height: 16),
          _WeatherExtrasCard(
            humidity: _weather!.humidity,
            windSpeed: _weather!.windSpeed,
            updatedAt: _weather!.updatedAt,
            dateFormat: dateFormat,
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Busca una ciudad, municipio o pueblo...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.cyanAccent),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.6)),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<_PlaceResult> results;
  final ValueChanged<_PlaceResult> onSelect;

  const _ResultsList({required this.results, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: results.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: Colors.white.withOpacity(0.08),
        ),
        itemBuilder: (context, index) {
          final r = results[index];
          return ListTile(
            leading: const Icon(Icons.place_rounded, color: Colors.cyanAccent),
            title: Text(r.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              [if (r.admin1 != null) r.admin1!, r.country].join(', '),
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12.5),
            ),
            onTap: () => onSelect(r),
          );
        },
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
                    fontSize: 24,
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

class _WeatherExtrasCard extends StatelessWidget {
  final double humidity;
  final double windSpeed;
  final DateTime updatedAt;
  final DateFormat dateFormat;

  const _WeatherExtrasCard({
    required this.humidity,
    required this.windSpeed,
    required this.updatedAt,
    required this.dateFormat,
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
      child: Column(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.lightBlueAccent),
          const SizedBox(height: 10),
          const Text(
            'Más información',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.12)),
          const SizedBox(height: 6),
          _StatRow(label: 'Humedad relativa', value: '${humidity.toStringAsFixed(0)}%'),
          _StatRow(label: 'Velocidad del viento', value: '${windSpeed.toStringAsFixed(1)} km/h'),
          _StatRow(label: 'Última actualización', value: dateFormat.format(updatedAt)),
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

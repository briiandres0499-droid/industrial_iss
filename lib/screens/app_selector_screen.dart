import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'iss_tracker_screen.dart';
import 'weather_search_screen.dart';

/// Panel de control inicial.
/// Es la primera pantalla que ve el usuario al abrir la app.
/// Permite elegir entre las dos aplicaciones disponibles:
///  1) La app de Registro de Variables Industriales (ya existente).
///  2) El Rastreador ISS en tiempo real (nueva).
class AppSelectorScreen extends StatelessWidget {
  const AppSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.apps_rounded,
                  color: Colors.cyanAccent,
                  size: 46,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Panel de Control',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona la aplicación que deseas abrir',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _AppOptionCard(
                icon: Icons.factory_rounded,
                iconBg: const Color(0xFF1565C0),
                title: 'Registro Industrial',
                subtitle: 'Registra y consulta variables de planta',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _AppOptionCard(
                icon: Icons.satellite_alt_rounded,
                iconBg: const Color(0xFF00838F),
                title: 'Rastreador ISS',
                subtitle: 'Ubicación en tiempo real de la Estación Espacial',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const IssTrackerScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _AppOptionCard(
                icon: Icons.travel_explore_rounded,
                iconBg: const Color(0xFF2E7D32),
                title: 'Clima y Ubicación',
                subtitle: 'Busca cualquier lugar de Colombia y su clima',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WeatherSearchScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AppOptionCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/app_user.dart';
import 'history_screen.dart';
import 'chart_screen.dart';
import 'login_screen.dart';

/// Pantalla de acceso para invitados (sin usuario/contraseña).
/// Permite consultar el Historial y la Gráfica en modo SOLO LECTURA:
/// no pueden registrar, editar ni eliminar mediciones.
class GuestScreen extends StatelessWidget {
  const GuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usuario invitado "de mentiras": no es Administrador, así que
    // MeasurementCard oculta automáticamente Editar/Eliminar.
    final guestUser = AppUser(username: 'Invitado', role: 'Invitado');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Invitado'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.azulOscuro.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility_outlined,
                      color: AppTheme.azulOscuro),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Estás en modo solo lectura. Puedes ver el historial '
                      'y las gráficas, pero no registrar, editar ni eliminar '
                      'mediciones.',
                      style: TextStyle(
                        color: AppTheme.azulOscuro,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Opciones disponibles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.azulOscuro,
              ),
            ),
            const SizedBox(height: 12),
            _menuTile(
              context,
              icon: Icons.history,
              title: 'Historial',
              subtitle: 'Consulta las mediciones registradas',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryScreen(user: guestUser),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _menuTile(
              context,
              icon: Icons.bar_chart,
              title: 'Gráfica',
              subtitle: 'Visualiza tendencias de las mediciones',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChartScreen(),
                  ),
                );
              },
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('¿Tienes usuario? Inicia sesión'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.azulOscuro.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.azulOscuro),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

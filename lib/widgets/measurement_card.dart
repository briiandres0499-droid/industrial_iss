import 'package:flutter/material.dart';
import '../models/measurement.dart';
import '../config/app_theme.dart';

class MeasurementCard extends StatelessWidget {
  final Measurement measurement;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MeasurementCard({
    super.key,
    required this.measurement,
    required this.isAdmin,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.precision_manufacturing,
                    color: AppTheme.azulOscuro),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    measurement.equipo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.azulOscuro,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.azulMedio.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    measurement.variable,
                    style: const TextStyle(
                      color: AppTheme.azulMedio,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.location_on_outlined, 'Área', measurement.area),
            _infoRow(
              Icons.speed,
              'Valor',
              '${measurement.valor} ${measurement.unidad}',
            ),
            _infoRow(
              Icons.calendar_today_outlined,
              'Fecha',
              '${measurement.fecha}  ${measurement.hora}',
            ),
            if (measurement.observaciones.trim().isNotEmpty)
              _infoRow(Icons.notes_outlined, 'Observaciones',
                  measurement.observaciones),
            if (isAdmin) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit,
                        size: 18, color: AppTheme.azulMedio),
                    label: const Text('Editar',
                        style: TextStyle(color: AppTheme.azulMedio)),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.red),
                    label: const Text('Eliminar',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

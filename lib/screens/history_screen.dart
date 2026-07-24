import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/app_user.dart';
import '../models/measurement.dart';
import '../widgets/measurement_card.dart';
import 'edit_measurement_screen.dart';

class HistoryScreen extends StatefulWidget {
  final AppUser user;

  const HistoryScreen({super.key, required this.user});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Future<List<Measurement>> _futureMediciones;

  @override
  void initState() {
    super.initState();
    _cargarMediciones();
  }

  void _cargarMediciones() {
    setState(() {
      _futureMediciones = _dbHelper.getAllMeasurements();
    });
  }

  Future<void> _confirmarEliminar(Measurement medicion) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar medición'),
          content: const Text(
              '¿Estás seguro de eliminar este registro? Esta acción no se puede deshacer.'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmar == true && medicion.id != null) {
      await _dbHelper.deleteMeasurement(medicion.id!);
      _cargarMediciones();
    }
  }

  Future<void> _editarMedicion(Measurement medicion) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditMeasurementScreen(measurement: medicion),
      ),
    );
    _cargarMediciones();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Mediciones'),
      ),
      body: FutureBuilder<List<Measurement>>(
        future: _futureMediciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No hay mediciones registradas',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final mediciones = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _cargarMediciones();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: mediciones.length,
              itemBuilder: (context, index) {
                final medicion = mediciones[index];
                return MeasurementCard(
                  measurement: medicion,
                  isAdmin: widget.user.isAdmin,
                  onEdit: () => _editarMedicion(medicion),
                  onDelete: () => _confirmarEliminar(medicion),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

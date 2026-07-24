import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../database/database_helper.dart';
import '../models/measurement.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class EditMeasurementScreen extends StatefulWidget {
  final Measurement measurement;

  const EditMeasurementScreen({super.key, required this.measurement});

  @override
  State<EditMeasurementScreen> createState() => _EditMeasurementScreenState();
}

class _EditMeasurementScreenState extends State<EditMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _equipoController;
  late TextEditingController _areaController;
  late TextEditingController _valorController;
  late TextEditingController _unidadController;
  late TextEditingController _observacionesController;

  late String _variableSeleccionada;
  late DateTime _fechaSeleccionada;
  late TimeOfDay _horaSeleccionada;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    final m = widget.measurement;
    _equipoController = TextEditingController(text: m.equipo);
    _areaController = TextEditingController(text: m.area);
    _valorController = TextEditingController(text: m.valor.toString());
    _unidadController = TextEditingController(text: m.unidad);
    _observacionesController = TextEditingController(text: m.observaciones);
    _variableSeleccionada = m.variable;
    _fechaSeleccionada = DateFormat('yyyy-MM-dd').parse(m.fecha);
    final partesHora = m.hora.split(':');
    _horaSeleccionada = TimeOfDay(
      hour: int.parse(partesHora[0]),
      minute: int.parse(partesHora[1]),
    );
  }

  @override
  void dispose() {
    _equipoController.dispose();
    _areaController.dispose();
    _valorController.dispose();
    _unidadController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
    );
    if (picked != null) {
      setState(() {
        _horaSeleccionada = picked;
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String fechaTexto =
        DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);
    final String horaTexto =
        '${_horaSeleccionada.hour.toString().padLeft(2, '0')}:${_horaSeleccionada.minute.toString().padLeft(2, '0')}';

    final medicionActualizada = widget.measurement.copyWith(
      equipo: _equipoController.text.trim(),
      area: _areaController.text.trim(),
      variable: _variableSeleccionada,
      valor: double.parse(_valorController.text.trim()),
      unidad: _unidadController.text.trim(),
      fecha: fechaTexto,
      hora: horaTexto,
      observaciones: _observacionesController.text.trim(),
    );

    await _dbHelper.updateMeasurement(medicionActualizada);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medición actualizada correctamente')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final String fechaTexto =
        DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);
    final String horaTexto =
        '${_horaSeleccionada.hour.toString().padLeft(2, '0')}:${_horaSeleccionada.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Medición'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _equipoController,
                label: 'Equipo',
                icon: Icons.precision_manufacturing_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el equipo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _areaController,
                label: 'Área',
                icon: Icons.location_on_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el área';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _variableSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Variable',
                  prefixIcon: Icon(Icons.tune),
                ),
                items: AppConstants.variables.map((String variable) {
                  return DropdownMenuItem<String>(
                    value: variable,
                    child: Text(variable),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() {
                    _variableSeleccionada = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _valorController,
                      label: 'Valor',
                      icon: Icons.speed,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el valor';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Valor inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _unidadController,
                      label: 'Unidad',
                      icon: Icons.straighten,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa la unidad';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: TextEditingController(text: fechaTexto),
                      label: 'Fecha',
                      icon: Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap: _seleccionarFecha,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: TextEditingController(text: horaTexto),
                      label: 'Hora',
                      icon: Icons.access_time,
                      readOnly: true,
                      onTap: _seleccionarHora,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _observacionesController,
                label: 'Observaciones',
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 28),
              CustomButton(
                label: 'Guardar Cambios',
                icon: Icons.save_outlined,
                onPressed: _guardarCambios,
                color: AppTheme.azulOscuro,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

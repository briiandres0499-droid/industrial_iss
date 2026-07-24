class Measurement {
  final int? id;
  final String equipo;
  final String area;
  final String variable;
  final double valor;
  final String unidad;
  final String fecha;
  final String hora;
  final String observaciones;

  Measurement({
    this.id,
    required this.equipo,
    required this.area,
    required this.variable,
    required this.valor,
    required this.unidad,
    required this.fecha,
    required this.hora,
    required this.observaciones,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipo': equipo,
      'area': area,
      'variable': variable,
      'valor': valor,
      'unidad': unidad,
      'fecha': fecha,
      'hora': hora,
      'observaciones': observaciones,
    };
  }

  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'] as int?,
      equipo: map['equipo'] as String,
      area: map['area'] as String,
      variable: map['variable'] as String,
      valor: (map['valor'] as num).toDouble(),
      unidad: map['unidad'] as String,
      fecha: map['fecha'] as String,
      hora: map['hora'] as String,
      observaciones: map['observaciones'] as String,
    );
  }

  Measurement copyWith({
    int? id,
    String? equipo,
    String? area,
    String? variable,
    double? valor,
    String? unidad,
    String? fecha,
    String? hora,
    String? observaciones,
  }) {
    return Measurement(
      id: id ?? this.id,
      equipo: equipo ?? this.equipo,
      area: area ?? this.area,
      variable: variable ?? this.variable,
      valor: valor ?? this.valor,
      unidad: unidad ?? this.unidad,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}

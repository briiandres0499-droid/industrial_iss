class AppConstants {
  static const String appName = 'Registro de Variables Industriales';

  static const List<String> variables = [
    'Temperatura',
    'Presión',
    'Nivel',
    'Caudal',
    'Humedad',
    'pH',
    'Voltaje',
    'Corriente',
  ];

  static const Map<String, String> unidadesSugeridas = {
    'Temperatura': '°C',
    'Presión': 'bar',
    'Nivel': '%',
    'Caudal': 'L/min',
    'Humedad': '%HR',
    'pH': 'pH',
    'Voltaje': 'V',
    'Corriente': 'A',
  };

  static const String rolAdministrador = 'Administrador';
  static const String rolOperador = 'Operador';
}

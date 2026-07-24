import '../models/app_user.dart';
import '../utils/constants.dart';

class AuthService {
  static AppUser? login(String username, String password) {
    final String user = username.trim();
    final String pass = password.trim();

    if (user == 'admin' && pass == '1234') {
      return AppUser(username: 'admin', role: AppConstants.rolAdministrador);
    }

    if (user == 'operador' && pass == '5678') {
      return AppUser(username: 'operador', role: AppConstants.rolOperador);
    }

    return null;
  }
}

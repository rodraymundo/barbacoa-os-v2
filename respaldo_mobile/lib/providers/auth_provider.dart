import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

/// Sesion del usuario. El JWT se guarda en SharedPreferences para no pedir login cada vez.
class AuthProvider extends ChangeNotifier {
  final ApiService api;
  AuthProvider(this.api) {
    api.onUnauthorized = () => cerrarSesion();
  }

  bool listo = false; // ya intentamos restaurar la sesion guardada
  String? nombre;

  bool get autenticado => api.token != null;

  Future<void> restaurarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    api.token = prefs.getString('token');
    nombre = prefs.getString('nombre');
    listo = true;
    notifyListeners();
  }

  /// Devuelve null si todo salio bien, o el mensaje de error para mostrar.
  Future<String?> iniciarSesion(String usuario, String password) async {
    try {
      final data = await api.login(usuario, password);
      if (data['rol'] != 'MESERO') {
        return 'Esta app es solo para meseros';
      }
      api.token = data['token'] as String;
      nombre = data['nombre'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', api.token!);
      await prefs.setString('nombre', nombre!);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message; // mensaje generico del servidor; nunca se imprimen credenciales
    } catch (_) {
      return 'No se pudo iniciar sesión';
    }
  }

  Future<void> cerrarSesion() async {
    api.token = null;
    nombre = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('nombre');
    notifyListeners();
  }
}

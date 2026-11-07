import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

const vino = Color(0xFF7A1C24);
const ambar = Color(0xFFF2B632);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  final auth = AuthProvider(api);
  await auth.restaurarSesion();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider(create: (_) => OrderProvider(api)),
    ],
    child: const BarbacoaApp(),
  ));
}

class BarbacoaApp extends StatelessWidget {
  const BarbacoaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barbacoa OS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: vino, primary: vino, secondary: ambar),
        scaffoldBackgroundColor: const Color(0xFFF4F4F4),
        appBarTheme: const AppBarTheme(backgroundColor: vino, foregroundColor: Colors.white),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: vino, foregroundColor: Colors.white),
      ),
      home: Consumer<AuthProvider>(
        builder: (_, auth, __) {
          if (!auth.listo) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return auth.autenticado ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}

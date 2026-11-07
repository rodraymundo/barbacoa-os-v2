import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import 'order_screen.dart';
import 'scanner_screen.dart';

/// Diseño Americano: AppBar arriba, BottomAppBar abajo, FAB central para el escaner.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  Future<void> _escanear() async {
    final codigo = await Navigator.push<String>(
        context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
    if (codigo == null || !mounted) return;
    final orden = context.read<OrderProvider>();
    final ok = await orden.abrirDesdeQr(codigo);
    if (!mounted) return;
    if (ok) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(orden.error ?? 'No se pudo abrir la orden')));
    }
  }

  void _tomarOrden() {
    if (context.read<OrderProvider>().pedido != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderScreen()));
    } else {
      _escanear();
    }
  }

  Future<void> _salir() async {
    context.read<OrderProvider>().limpiar();
    await context.read<AuthProvider>().cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final cargando = context.watch<OrderProvider>().cargando;
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Dashboard - Mesero' : 'Perfil'),
        actions: [IconButton(onPressed: _salir, icon: const Icon(Icons.logout), tooltip: 'Cerrar sesión')],
        bottom: cargando ? const PreferredSize(preferredSize: Size.fromHeight(3), child: LinearProgressIndicator()) : null,
      ),
      body: _tab == 0 ? _OrdenesTab(onTomarOrden: _tomarOrden) : const _PerfilTab(),
      floatingActionButton: FloatingActionButton(
        onPressed: _escanear,
        tooltip: 'Escanear QR de la mesa',
        child: const Icon(Icons.qr_code_scanner),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: [
            Expanded(child: _NavItem(icon: Icons.receipt_long, label: 'Órdenes', activo: _tab == 0, onTap: () => setState(() => _tab = 0))),
            const SizedBox(width: 64),
            Expanded(child: _NavItem(icon: Icons.person, label: 'Perfil', activo: _tab == 1, onTap: () => setState(() => _tab = 1))),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool activo;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = activo ? Theme.of(context).colorScheme.primary : Colors.black45;
    return InkWell(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ]),
    );
  }
}

class _OrdenesTab extends StatelessWidget {
  final VoidCallback onTomarOrden;
  const _OrdenesTab({required this.onTomarOrden});

  @override
  Widget build(BuildContext context) {
    final pedido = context.watch<OrderProvider>().pedido;
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.table_restaurant, size: 44, color: tema.colorScheme.primary),
                const SizedBox(height: 10),
                const Text('Mesa actual', style: TextStyle(color: Colors.black54)),
                Text(pedido == null ? 'Sin mesa asignada' : 'Mesa ${pedido.mesaNumero}',
                    style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                if (pedido != null) ...[
                  const SizedBox(height: 8),
                  Chip(label: Text(pedido.estadoTexto), backgroundColor: tema.colorScheme.secondary.withOpacity(0.35)),
                ],
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: tema.colorScheme.secondary, foregroundColor: Colors.black87),
                  onPressed: onTomarOrden,
                  icon: const Icon(Icons.edit_note),
                  label: Text(pedido == null ? 'Tomar Orden' : 'Ver orden'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Toca el botón flotante central para escanear el QR de la mesa.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.black45)),
        ]),
      ),
    );
  }
}

class _PerfilTab extends StatelessWidget {
  const _PerfilTab();

  @override
  Widget build(BuildContext context) {
    final nombre = context.watch<AuthProvider>().nombre ?? 'Mesero';
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 42)),
        const SizedBox(height: 12),
        Text(nombre, style: Theme.of(context).textTheme.titleLarge),
        const Text('Rol: Mesero', style: TextStyle(color: Colors.black54)),
      ]),
    );
  }
}

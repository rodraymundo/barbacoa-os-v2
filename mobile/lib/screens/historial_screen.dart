import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  late Future<List<Pedido>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = context.read<ApiService>().historial();
  }

  void _recargar() {
    setState(() {
      _futuro = context.read<ApiService>().historial();
    });
  }

  String _mensaje(Object e) => e is ApiException ? e.message : 'No se pudo cargar el historial';

  Color _color(String estado) {
    switch (estado) {
      case 'ENTREGADO':
        return Colors.green.shade100;
      case 'CANCELADO':
        return Colors.red.shade100;
      default:
        return Colors.amber.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de pedidos'),
        actions: [IconButton(onPressed: _recargar, icon: const Icon(Icons.refresh), tooltip: 'Actualizar')],
      ),
      body: FutureBuilder<List<Pedido>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_mensaje(snap.error!), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _recargar, child: const Text('Reintentar')),
                ]),
              ),
            );
          }
          final pedidos = snap.data!;
          if (pedidos.isEmpty) {
            return const Center(child: Text('Todavía no has tomado pedidos', style: TextStyle(color: Colors.black45)));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: pedidos.length,
            itemBuilder: (_, i) {
              final p = pedidos[i];
              return Card(
                margin: const EdgeInsets.fromLTRB(12, 5, 12, 5),
                child: ExpansionTile(
                  title: Text('Mesa ${p.mesaNumero} · \$${p.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text(formatoFecha(p.fecha)),
                    Chip(
                      label: Text(p.estadoTexto, style: const TextStyle(fontSize: 11)),
                      backgroundColor: _color(p.estado),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ]),
                  children: [
                    if (p.items.isEmpty) const ListTile(dense: true, title: Text('Sin productos')),
                    for (final it in p.items)
                      ListTile(
                        dense: true,
                        leading: Text('${it.cantidad}×', style: const TextStyle(fontWeight: FontWeight.bold)),
                        title: Text(it.productoNombre),
                        trailing: Text('\$${it.subtotal.toStringAsFixed(2)}'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
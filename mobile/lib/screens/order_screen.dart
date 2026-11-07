import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  void _aviso(BuildContext context, String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final orden = context.watch<OrderProvider>();
    final pedido = orden.pedido;
    if (pedido == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Mesa ${pedido.mesaNumero}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar estado',
            onPressed: () async {
              final ok = await orden.actualizar();
              if (!context.mounted) return;
              if (!ok) _aviso(context, orden.error ?? 'No se pudo actualizar');
              if (orden.pedido == null) Navigator.pop(context);
            },
          ),
        ],
        bottom: orden.cargando ? const PreferredSize(preferredSize: Size.fromHeight(3), child: LinearProgressIndicator()) : null,
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(pedido.estadoTexto, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        if (pedido.abierto)
          Expanded(
            flex: 3,
            child: ListView(
              children: [
                for (final entrada in orden.porCategoria.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Text(entrada.key, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  ),
                  for (final prod in entrada.value)
                    ListTile(
                      dense: true,
                      title: Text(prod.nombre),
                      subtitle: Text('\$${prod.precio.toStringAsFixed(2)}'),
                      trailing: IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        onPressed: orden.cargando
                            ? null
                            : () async {
                                final ok = await orden.agregar(prod);
                                if (!ok && context.mounted) _aviso(context, orden.error ?? 'Error');
                              },
                      ),
                    ),
                ],
              ],
            ),
          ),
        const Divider(height: 1),
        Expanded(
          flex: pedido.abierto ? 2 : 1,
          child: pedido.items.isEmpty
              ? const Center(child: Text('Aún no hay productos en la orden', style: TextStyle(color: Colors.black45)))
              : ListView(
                  children: [
                    for (final it in pedido.items)
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(radius: 14, child: Text('${it.cantidad}', style: const TextStyle(fontSize: 12))),
                        title: Text(it.productoNombre),
                        subtitle: Text('\$${it.subtotal.toStringAsFixed(2)}'),
                        trailing: pedido.abierto
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: orden.cargando ? null : () => orden.quitar(it),
                              )
                            : null,
                      ),
                  ],
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(children: [
              Expanded(
                child: Text('Total: \$${pedido.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              _accion(context, orden),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _accion(BuildContext context, OrderProvider orden) {
    final pedido = orden.pedido!;
    if (pedido.abierto) {
      return FilledButton.icon(
        icon: const Icon(Icons.send),
        label: const Text('Enviar a cocina'),
        onPressed: orden.cargando || pedido.items.isEmpty
            ? null
            : () async {
                final ok = await orden.enviarACocina();
                if (!context.mounted) return;
                if (ok) {
                  _aviso(context, 'Orden enviada a cocina');
                  Navigator.pop(context);
                } else {
                  _aviso(context, orden.error ?? 'Error');
                }
              },
      );
    }
    if (pedido.listo) {
      return FilledButton.icon(
        icon: const Icon(Icons.check_circle),
        label: const Text('Marcar entregado'),
        onPressed: orden.cargando
            ? null
            : () async {
                final ok = await orden.marcarEntregado();
                if (!context.mounted) return;
                if (ok) {
                  _aviso(context, 'Orden entregada. Mesa liberada');
                  Navigator.pop(context);
                } else {
                  _aviso(context, orden.error ?? 'Error');
                }
              },
      );
    }
    return OutlinedButton.icon(
      icon: const Icon(Icons.refresh),
      label: const Text('Actualizar estado'),
      onPressed: orden.cargando ? null : () => orden.actualizar(),
    );
  }
}

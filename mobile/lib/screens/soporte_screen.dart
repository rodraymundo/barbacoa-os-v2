import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class SoporteScreen extends StatefulWidget {
  const SoporteScreen({super.key});

  @override
  State<SoporteScreen> createState() => _SoporteScreenState();
}

class _SoporteScreenState extends State<SoporteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _asunto = TextEditingController();
  final _descripcion = TextEditingController();
  late Future<List<Ticket>> _futuro;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _futuro = context.read<ApiService>().misTickets();
  }

  @override
  void dispose() {
    _asunto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    final api = context.read<ApiService>();
    setState(() => _enviando = true);
    try {
      await api.crearTicket(_asunto.text.trim(), _descripcion.text.trim());
      _asunto.clear();
      _descripcion.clear();
      if (!mounted) return;
      _aviso('Solicitud enviada. Soporte la revisará pronto.');
      setState(() {
        _futuro = api.misTickets();
      });
    } on ApiException catch (e) {
      if (mounted) _aviso(e.message);
    } catch (_) {
      if (mounted) _aviso('No se pudo enviar la solicitud');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _recargar() {
    setState(() {
      _futuro = context.read<ApiService>().misTickets();
    });
  }

  Color _color(String estado) {
    switch (estado) {
      case 'RESUELTO':
        return Colors.green.shade100;
      case 'EN_PROCESO':
        return Colors.blue.shade100;
      default:
        return Colors.amber.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte técnico'),
        actions: [IconButton(onPressed: _recargar, icon: const Icon(Icons.refresh), tooltip: 'Actualizar')],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Nueva solicitud', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Cuéntanos qué problema tuviste. El administrador te responderá aquí.',
                      style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _asunto,
                    maxLength: 120,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Asunto', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().length < 3) ? 'Escribe un asunto (mínimo 3 letras)' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descripcion,
                    maxLength: 1000,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Descripción', alignLabelWithHint: true, border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().length < 10) ? 'Describe el problema (mínimo 10 caracteres)' : null,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _enviando ? null : _enviar,
                      icon: const Icon(Icons.send),
                      label: Text(_enviando ? 'Enviando...' : 'Enviar solicitud'),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Mis solicitudes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<List<Ticket>>(
            future: _futuro,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError) {
                final e = snap.error;
                return Text(e is ApiException ? e.message : 'No se pudieron cargar tus solicitudes');
              }
              final tickets = snap.data!;
              if (tickets.isEmpty) {
                return const Text('Aún no has enviado solicitudes.', style: TextStyle(color: Colors.black45));
              }
              return Column(children: [
                for (final t in tickets)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(t.asunto, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Chip(
                            label: Text(t.estadoTexto, style: const TextStyle(fontSize: 11)),
                            backgroundColor: _color(t.estado),
                            visualDensity: VisualDensity.compact,
                          ),
                        ]),
                        Text(formatoFecha(t.fecha), style: const TextStyle(color: Colors.black45, fontSize: 12)),
                        const SizedBox(height: 6),
                        Text(t.descripcion),
                        if (t.respuesta != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              border: const Border(left: BorderSide(color: Colors.amber, width: 4)),
                            ),
                            child: Text('Respuesta de soporte: ${t.respuesta}'),
                          ),
                        ],
                      ]),
                    ),
                  ),
              ]);
            },
          ),
        ],
      ),
    );
  }
}
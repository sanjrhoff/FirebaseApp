import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart' as ll;

import 'notifications.dart';
import 'maps.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final createController = TextEditingController();

  String? editingId;
  final inlineController = TextEditingController();
  final inlineFocus = FocusNode();

  bool loading = false;
  String? message;

  CollectionReference<Map<String, dynamic>> get _col {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes');
  }

  @override
  void dispose() {
    createController.dispose();
    inlineController.dispose();
    inlineFocus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = createController.text.trim();
    if (text.isEmpty) {
      setState(() => message = 'Preencha a descrição.');
      return;
    }
    setState(() {
      loading = true;
      message = null;
    });
    try {
      await _col
          .add({
            'description': text,
            'createdAt': FieldValue.serverTimestamp(),
            'date': null,
            'timeMinutes': null,
          })
          .then(
            (note) => Notifications.show(
              id: note.id.hashCode,
              title: 'Nota criada',
              body: text,
              payload: note.id,
            ),
          );
      createController.clear();
    } catch (e) {
      setState(() => message = 'Erro: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _startInlineEdit(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    setState(() {
      editingId = doc.id;
      inlineController.text = (data?['description'] ?? '').toString();
    });
    Future.microtask(() => inlineFocus.requestFocus());
  }

  void _cancelInlineEdit() {
    setState(() {
      editingId = null;
      inlineController.clear();
      inlineFocus.unfocus();
    });
  }

  Future<void> _commitInlineEdit(String docId) async {
    final newText = inlineController.text.trim();
    if (newText.isEmpty) {
      setState(() => message = 'A descrição não pode ser vazia.');
      return;
    }
    try {
      await _col.doc(docId).update({
        'description': newText,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _cancelInlineEdit();
    } catch (e) {
      setState(() => message = 'Erro ao atualizar: $e');
    }
  }

  Future<void> _remove(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover nota'),
        content: const Text('Tem certeza que deseja remover esta nota?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _col.doc(docId).delete();
      if (editingId == docId) _cancelInlineEdit();
    }
  }

  void _openMapViewer(
    DocumentReference<Map<String, dynamic>> noteRef,
    Map<String, dynamic> data,
  ) {
    GeoPoint? gp;
    final pos = data['position'];
    if (pos is GeoPoint) {
      gp = pos;
    } else if (pos is Map && pos['geopoint'] is GeoPoint) {
      gp = pos['geopoint'] as GeoPoint;
    }

    ll.LatLng? initialLatLng = gp == null
        ? null
        : ll.LatLng(gp.latitude, gp.longitude);
    final double? initialZoom = (data['zoom'] as num?)?.toDouble();
    String? initialAddress =
        (data['address'] as String?)?.trim().isEmpty == true
        ? null
        : data['address']?.toString();

    ll.LatLng? finalLatLng;
    String? finalAddress;

    final init = data['initial'];
    if (init is Map) {
      final ipos = init['position'];
      GeoPoint? igp;
      if (ipos is GeoPoint) {
        igp = ipos;
      } else if (ipos is Map && ipos['geopoint'] is GeoPoint) {
        igp = ipos['geopoint'] as GeoPoint;
      }
      if (igp != null) initialLatLng = ll.LatLng(igp.latitude, igp.longitude);
      final ia = (init['address'] as String?)?.trim();
      if (ia != null && ia.isNotEmpty) initialAddress = ia;
    }

    final fin = data['final'];
    if (fin is Map) {
      final fpos = fin['position'];
      GeoPoint? fgp;
      if (fpos is GeoPoint) {
        fgp = fpos;
      } else if (fpos is Map && fpos['geopoint'] is GeoPoint) {
        fgp = fpos['geopoint'] as GeoPoint;
      }
      if (fgp != null) finalLatLng = ll.LatLng(fgp.latitude, fgp.longitude);
      final fa = (fin['address'] as String?)?.trim();
      if (fa != null && fa.isNotEmpty) finalAddress = fa;
    }

    final legacyRoute = data['route'];
    if (legacyRoute is Map) {
      final origin = legacyRoute['origin'];
      if (origin is Map) {
        final oPos = origin['position'];
        GeoPoint? ogp;
        if (oPos is GeoPoint) {
          ogp = oPos;
        } else if (oPos is Map && oPos['geopoint'] is GeoPoint) {
          ogp = oPos['geopoint'] as GeoPoint;
        }
        if (ogp != null) initialLatLng = ll.LatLng(ogp.latitude, ogp.longitude);
        final oa = (origin['address'] as String?)?.trim();
        if (oa != null && oa.isNotEmpty) initialAddress = oa;
      }

      final dest = legacyRoute['destination'];
      if (dest is Map) {
        final dPos = dest['position'];
        GeoPoint? dgp;
        if (dPos is GeoPoint) {
          dgp = dPos;
        } else if (dPos is Map && dPos['geopoint'] is GeoPoint) {
          dgp = dPos['geopoint'] as GeoPoint;
        }
        if (dgp != null) finalLatLng = ll.LatLng(dgp.latitude, dgp.longitude);
        final da = (dest['address'] as String?)?.trim();
        if (da != null && da.isNotEmpty) finalAddress = da;
      }
    }

    String? polyline6 = (data['polyline6'] as String?)?.trim();
    double? distanceM = (data['distanceM'] as num?)?.toDouble();
    double? durationS = (data['durationS'] as num?)?.toDouble();

    if ((polyline6 == null || polyline6.isEmpty) && legacyRoute is Map) {
      polyline6 = (legacyRoute['polyline6'] as String?)?.trim();
      distanceM ??= (legacyRoute['distanceM'] as num?)?.toDouble();
      durationS ??= (legacyRoute['durationS'] as num?)?.toDouble();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapViewerEditorPage(
          noteRef: noteRef,
          initialLatLng: initialLatLng,
          initialZoom: initialZoom,
          initialAddress: initialAddress,
          finalLatLng: finalLatLng,
          finalAddress: finalAddress,
          initialPolyline6: polyline6,
          initialDistanceM: distanceM,
          initialDurationS: durationS,
        ),
      ),
    );
  }

  String? _routeSubtitle(Map<String, dynamic> data) {
    String? iAddr;
    String? fAddr;
    double? distM = (data['distanceM'] as num?)?.toDouble();
    double? durS = (data['durationS'] as num?)?.toDouble();

    final init = data['initial'];
    if (init is Map) {
      final ia = (init['address'] as String?)?.trim();
      if (ia != null && ia.isNotEmpty) iAddr = ia;
    }
    final fin = data['final'];
    if (fin is Map) {
      final fa = (fin['address'] as String?)?.trim();
      if (fa != null && fa.isNotEmpty) fAddr = fa;
    }

    if (iAddr == null || fAddr == null) {
      final route = data['route'];
      if (route is Map) {
        final origin = route['origin'];
        if (origin is Map) {
          final oa = (origin['address'] as String?)?.trim();
          if (oa != null && oa.isNotEmpty) iAddr = oa;
        }
        final dest = route['destination'];
        if (dest is Map) {
          final da = (dest['address'] as String?)?.trim();
          if (da != null && da.isNotEmpty) fAddr = da;
        }
        distM ??= (route['distanceM'] as num?)?.toDouble();
        durS ??= (route['durationS'] as num?)?.toDouble();
      }
    }

    if (iAddr != null && fAddr != null) {
      final parts = <String>['$iAddr → $fAddr'];
      if (distM != null) parts.add('${(distM / 1000).toStringAsFixed(2)} km');
      if (durS != null) parts.add('${(durS / 60).toStringAsFixed(0)} min');
      return parts.join(' · ');
    }

    iAddr ??= (data['address'] as String?)?.trim();
    if (iAddr != null && iAddr.isNotEmpty) return iAddr;

    return null;
  }

  String formatDate(Timestamp? ts) {
    if (ts == null) return '--';
    final d = ts.toDate();
    return '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String formatTimeMinutes(int? minutes) {
    if (minutes == null) return '--';
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickDate(
    DocumentReference<Map<String, dynamic>> noteRef,
    Timestamp? current,
  ) async {
    final initial = (current ?? Timestamp.fromDate(DateTime.now())).toDate();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      try {
        await noteRef.update({
          'date': Timestamp.fromDate(selected),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) setState(() {});
      } catch (e) {
        setState(() => message = 'Erro ao salvar data: $e');
      }
    }
  }

  Future<void> _pickTime(
    DocumentReference<Map<String, dynamic>> noteRef,
    int? currentMinutes,
  ) async {
    final initialHour = (currentMinutes ?? 540) ~/ 60;
    final initialMinute = (currentMinutes ?? 540) % 60;

    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );
    if (selected != null) {
      final minutes = selected.hour * 60 + selected.minute;
      try {
        await noteRef.update({
          'timeMinutes': minutes,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) setState(() {});
      } catch (e) {
        setState(() => message = 'Erro ao salvar horário: $e');
      }
    }
  }

  Widget _iconWithLabel({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(icon, size: 20),
            tooltip: tooltip,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 40, height: 36),
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            onPressed: onPressed,
          ),
          const SizedBox(height: 2),
          Text(
            label.isEmpty ? '—' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              height: 1.0,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notas')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: createController,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                      onSubmitted: (_) => _add(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: loading ? null : _add,
                        child: const Text('Adicionar'),
                      ),
                    ),
                  ],
                ),
              ),
              if (loading) const CircularProgressIndicator(),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    message!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _col
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('Nenhuma nota cadastrada.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (context, i) {
                        final doc = docs[i];
                        final data = doc.data();
                        final isEditing = editingId == doc.id;

                        
                        final subtitleText = _routeSubtitle(data);

                        final Timestamp? tsDate = data['date'] as Timestamp?;
                        final int? timeMinutes = (data['timeMinutes'] as num?)?.toInt();

                        if (isEditing) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: inlineController,
                                    focusNode: inlineFocus,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Editar descrição',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    onSubmitted: (_) =>
                                        _commitInlineEdit(doc.id),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Salvar',
                                  onPressed: () => _commitInlineEdit(doc.id),
                                  icon: const Icon(Icons.check_circle_outline),
                                ),
                                IconButton(
                                  tooltip: 'Cancelar',
                                  onPressed: _cancelInlineEdit,
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListTile(
                          isThreeLine: subtitleText != null,
                          minVerticalPadding: 8,
                          title: Text((data['description'] ?? '').toString()),
                          subtitle: subtitleText == null
                              ? null
                              : Text(
                                  subtitleText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          onTap: () => _startInlineEdit(doc),
                          trailing: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _iconWithLabel(
                                  icon: Icons.map_rounded,
                                  label: 'Mapa',
                                  tooltip: 'Abrir mapa',
                                  onPressed: () =>
                                      _openMapViewer(_col.doc(doc.id), data),
                                ),
                                const SizedBox(width: 4),
                                _iconWithLabel(
                                  icon: Icons.event,
                                  label: formatDate(tsDate),
                                  tooltip: 'Selecionar data',
                                  onPressed: () =>
                                      _pickDate(_col.doc(doc.id), tsDate),
                                ),
                                const SizedBox(width: 4),
                                _iconWithLabel(
                                  icon: Icons.access_time,
                                  label: formatTimeMinutes(timeMinutes),
                                  tooltip: 'Selecionar horário',
                                  onPressed: () =>
                                      _pickTime(_col.doc(doc.id), timeMinutes),
                                ),
                                const SizedBox(width: 4),
                                _iconWithLabel(
                                  icon: Icons.delete_outline,
                                  label: 'Remover',
                                  tooltip: 'Remover nota',
                                  onPressed: () => _remove(doc.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
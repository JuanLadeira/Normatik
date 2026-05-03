import 'package:flutter/material.dart';
import 'package:normatiq_ui/normatiq_ui.dart';

class PhotosEditor extends StatefulWidget {
  final List<String> initialPhotos;
  final bool enabled;

  const PhotosEditor({
    super.key,
    this.initialPhotos = const [],
    this.enabled = true,
  });

  @override
  State<PhotosEditor> createState() => PhotosEditorState();
}

class PhotosEditorState extends State<PhotosEditor> {
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialPhotos.isEmpty) {
      _controllers.add(TextEditingController());
    } else {
      for (final p in widget.initialPhotos) {
        _controllers.add(TextEditingController(text: p));
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> getPhotos() => _controllers
      .map((c) => c.text.trim())
      .where((text) => text.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FOTOS (URLs)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _controllers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            return Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controllers[i],
                    decoration: const InputDecoration(
                      hintText: 'https://exemplo.com/foto.jpg',
                      isDense: true,
                    ),
                    enabled: widget.enabled,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  color: NormatiqColors.danger700,
                  onPressed: widget.enabled && _controllers.length > 1
                      ? () => setState(() {
                            _controllers[i].dispose();
                            _controllers.removeAt(i);
                          })
                      : null,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: widget.enabled
              ? () => setState(() => _controllers.add(TextEditingController()))
              : null,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Adicionar outra foto'),
          style: TextButton.styleFrom(
            foregroundColor: NormatiqColors.primary600,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

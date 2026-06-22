import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import '../certificados_padrao_provider.dart';
import '../../settings/templates_medicao_page.dart';

class TemplateSelectorField extends ConsumerWidget {
  final FormularioTemplateModel? selectedTemplate;
  final Function(FormularioTemplateModel?) onSelected;
  final bool isLoading;

  const TemplateSelectorField({
    super.key,
    required this.selectedTemplate,
    required this.onSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Template de Medição',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: NormatiqColors.neutral500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: isLoading ? null : () => _showSelector(context, ref),
          borderRadius: BorderRadius.circular(NormatiqRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: NormatiqSpacing.s3,
              vertical: NormatiqSpacing.s3,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: NormatiqColors.neutral300),
              borderRadius: BorderRadius.circular(NormatiqRadius.md),
              color: isLoading ? NormatiqColors.neutral100 : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.table_chart_outlined,
                  size: 20,
                  color: selectedTemplate != null
                      ? NormatiqColors.primary600
                      : NormatiqColors.neutral400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedTemplate?.nome ?? 'Selecionar template...',
                    style: TextStyle(
                      color: selectedTemplate != null
                          ? Theme.of(context).colorScheme.onSurface
                          : NormatiqColors.neutral500,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: NormatiqColors.neutral400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TemplateSelectionSheet(
        selectedTemplate: selectedTemplate,
        onSelected: onSelected,
      ),
    );
  }
}

class _TemplateSelectionSheet extends ConsumerWidget {
  final FormularioTemplateModel? selectedTemplate;
  final Function(FormularioTemplateModel?) onSelected;

  const _TemplateSelectionSheet({
    required this.selectedTemplate,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesCertificadoProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NormatiqColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Selecionar Template',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: templatesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
                data: (templates) {
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: templates.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListTile(
                          leading: const Icon(Icons.block, color: NormatiqColors.neutral500),
                          title: const Text('Nenhum template'),
                          selected: selectedTemplate == null,
                          onTap: () {
                            onSelected(null);
                            Navigator.pop(context);
                          },
                        );
                      }
                      final t = templates[index - 1];
                      return ListTile(
                        leading: const Icon(Icons.table_chart_outlined, color: NormatiqColors.primary600),
                        title: Text(t.nome),
                        subtitle: Text('${t.campos.length} colunas | ${t.tipoRegressaoDefault}'),
                        selected: selectedTemplate?.id == t.id,
                        onTap: () {
                          onSelected(t);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('CRIAR NOVO TEMPLATE'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final sheetContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TemplateFormDialog(
        ref: ref,
        onSaved: (newTemplate) {
          onSelected(newTemplate);
          Navigator.pop(sheetContext); // fecha a bottom sheet de seleção
        },
      ),
    );
  }
}

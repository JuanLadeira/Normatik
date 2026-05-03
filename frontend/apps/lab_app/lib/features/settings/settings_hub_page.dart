import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:normatiq_ui/normatiq_ui.dart';

class SettingsHubPage extends StatelessWidget {
  const SettingsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configurações',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(NormatiqSpacing.s4),
        children: [
          _SectionHeader('Laboratório'),
          _SettingsTile(
            icon: Icons.straighten_outlined,
            title: 'Grandezas e Unidades',
            subtitle: 'Gerencie grandezas físicas e suas unidades de medida',
            onTap: () => context.push('/more/grandezas'),
          ),
          const SizedBox(height: NormatiqSpacing.s2),
          _SettingsTile(
            icon: Icons.category_outlined,
            title: 'Tipos de Instrumento',
            subtitle: 'Gerencie tipos de equipamento e modelos',
            onTap: () => context.push('/more/tipos-instrumento'),
          ),
          const SizedBox(height: NormatiqSpacing.s4),
          _SectionHeader('Acesso'),
          _SettingsTile(
            icon: Icons.group_outlined,
            title: 'Usuários',
            subtitle: 'Gerencie membros da equipe e convites',
            onTap: () => context.push('/more/usuarios'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: 4, bottom: NormatiqSpacing.s2, top: NormatiqSpacing.s1),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: NormatiqColors.primary600.withOpacity(0.1),
            borderRadius: BorderRadius.circular(NormatiqRadius.sm),
          ),
          child: Icon(icon, size: 20, color: NormatiqColors.primary600),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: NormatiqColors.neutral500)),
        trailing: const Icon(Icons.chevron_right,
            color: NormatiqColors.neutral400),
        onTap: onTap,
      ),
    );
  }
}

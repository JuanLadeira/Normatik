import 'package:flutter/material.dart';
import 'package:normatiq_ui/normatiq_ui.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Laboratório Normatiq Demo · Abril 2026",
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 13),
            ),
            const SizedBox(height: 24),
            
            // Stats Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.2,
                  children: const [
                    NormatiqStatCard(value: "47", label: "Calibrações este mês", sub: "↑ 12 vs. março"),
                    NormatiqStatCard(value: "38", label: "Certificados emitidos", sub: "mês atual", color: Color(0xFF00B5A4)),
                    NormatiqStatCard(value: "1", label: "Padrão vencido", sub: "ação necessária", color: NormatiqColors.danger700),
                    NormatiqStatCard(value: "5", label: "Em rascunho", sub: "aguardando conclusão", color: Color(0xFFD97706)),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Columns
            if (MediaQuery.of(context).size.width > 900)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildAlertsSection(context)),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildRecentSection(context)),
                ],
              )
            else ...[
              _buildAlertsSection(context),
              const SizedBox(height: 24),
              _buildRecentSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildAlertsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, "Alertas ativos"),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              _buildAlertItem(context, "PAT-003 — Termômetro de referência vencido há 40 dias", true),
              _buildAlertItem(context, "PAT-002 — Bloco padrão grau 1 vence em 17 dias", false),
              _buildAlertItem(context, "5 calibrações em rascunho aguardando conclusão", false, isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertItem(BuildContext context, String label, bool isDanger, {bool isLast = false}) {
    final color = isDanger ? NormatiqColors.danger700 : const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color, width: 3),
          bottom: isLast ? BorderSide.none : BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label, 
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, "Calibrações recentes"),
        const Card(
          margin: EdgeInsets.zero,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text("Tabela de calibrações em breve..."),
            ),
          ),
        ),
      ],
    );
  }
}

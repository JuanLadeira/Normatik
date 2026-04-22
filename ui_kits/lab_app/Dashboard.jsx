// Dashboard.jsx — Normatiq lab_app dashboard screen

const MOCK_ALERTS = [
  { id: 1, type: 'danger', label: 'PAT-003 — Termômetro de referência vencido há 40 dias', action: 'Ver padrão' },
  { id: 2, type: 'warning', label: 'PAT-002 — Bloco padrão grau 1 vence em 17 dias', action: 'Agendar' },
  { id: 3, type: 'warning', label: '5 calibrações em rascunho aguardando conclusão', action: 'Ver lista' },
];

const MOCK_RECENT = [
  { id: 1, cert: 'LAB-2025-0051', cliente: 'Usinagem Alfa Ltda', instrumento: 'Micrômetro 0–25 mm', status: 'concluida', data: '18/04/2025' },
  { id: 2, cert: '—', cliente: 'Metais Beta S.A.', instrumento: 'Paquímetro 150 mm', status: 'em_andamento', data: '17/04/2025' },
  { id: 3, cert: '—', cliente: 'TechParts Ind.', instrumento: 'Termômetro digital', status: 'rascunho', data: '16/04/2025' },
  { id: 4, cert: 'LAB-2025-0050', cliente: 'Fundição Central', instrumento: 'Relógio comparador', status: 'concluida', data: '15/04/2025' },
];

const STATUS_CFG = {
  rascunho:     { label: 'Rascunho',     bg: '#F1F4F8', fg: '#475569', border: '#94A3B8' },
  em_andamento: { label: 'Em andamento', bg: '#EFF6FF', fg: '#1D4ED8', border: '#3B82F6' },
  concluida:    { label: 'Concluída',    bg: '#E6FAFA', fg: '#006960', border: '#00B5A4' },
};

const StatCard = ({ value, label, sub, color = '#1A3A6C', onNav }) => (
  <div style={dashStyles.statCard} onClick={onNav}>
    <div style={{ fontSize: 32, fontWeight: 700, color, letterSpacing: '-0.03em', lineHeight: 1 }}>{value}</div>
    <div style={{ fontSize: 13, fontWeight: 500, color: '#334155', marginTop: 4 }}>{label}</div>
    {sub && <div style={{ fontSize: 11, color: '#94A3B8', marginTop: 2 }}>{sub}</div>}
  </div>
);

const AlertItem = ({ type, label, action }) => (
  <div style={{ ...dashStyles.alertItem, borderLeftColor: type === 'danger' ? '#DC2626' : '#D97706' }}>
    <IconAlert size={14} style={{ color: type === 'danger' ? '#DC2626' : '#D97706', flexShrink: 0, marginTop: 1 }} />
    <span style={{ flex: 1, fontSize: 13, color: '#334155' }}>{label}</span>
    <span style={dashStyles.alertAction}>{action}</span>
  </div>
);

const Badge = ({ status }) => {
  const cfg = STATUS_CFG[status] || STATUS_CFG.rascunho;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', padding: '2px 8px',
      borderRadius: 9999, fontSize: 11, fontWeight: 500,
      background: cfg.bg, color: cfg.fg, border: `1px solid ${cfg.border}`,
    }}>{cfg.label}</span>
  );
};

const Dashboard = ({ onNav }) => (
  <div style={dashStyles.root}>
    <div style={dashStyles.pageHeader}>
      <div>
        <div style={dashStyles.pageTitle}>Dashboard</div>
        <div style={{ fontSize: 13, color: '#64748B', marginTop: 2 }}>Laboratório Normatiq Demo · Abril 2025</div>
      </div>
      <button style={dashStyles.btnPrimary} onClick={() => onNav('calibracoes')}>
        <IconPlus size={14} style={{ color: '#fff' }} /> Nova calibração
      </button>
    </div>

    {/* Stats */}
    <div style={dashStyles.statsGrid}>
      <StatCard value="47" label="Calibrações este mês" sub="↑ 12 vs. março" onNav={() => onNav('calibracoes')} />
      <StatCard value="38" label="Certificados emitidos" sub="mês atual" color="#006960" onNav={() => onNav('certificados')} />
      <StatCard value="1" label="Padrão vencido" sub="ação necessária" color="#DC2626" onNav={() => onNav('padroes')} />
      <StatCard value="5" label="Em rascunho" sub="aguardando conclusão" color="#D97706" onNav={() => onNav('calibracoes')} />
    </div>

    <div style={dashStyles.columns}>
      {/* Alerts */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={dashStyles.sectionTitle}>Alertas ativos</div>
        <div style={dashStyles.card}>
          {MOCK_ALERTS.map(a => <AlertItem key={a.id} {...a} />)}
        </div>
      </div>

      {/* Recent calibrations */}
      <div style={{ flex: 2, minWidth: 0 }}>
        <div style={dashStyles.sectionTitle}>Calibrações recentes</div>
        <div style={{ ...dashStyles.card, padding: 0, overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: '#F8FAFC' }}>
                {['Certificado', 'Cliente', 'Instrumento', 'Status', 'Data'].map(h => (
                  <th key={h} style={dashStyles.th}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {MOCK_RECENT.map((row, i) => (
                <tr key={row.id} style={{ borderBottom: '1px solid #F1F4F8' }}
                  onMouseEnter={e => e.currentTarget.style.background = '#F8FAFC'}
                  onMouseLeave={e => e.currentTarget.style.background = 'transparent'}>
                  <td style={dashStyles.td}>
                    <span style={{ fontFamily: "'IBM Plex Mono', monospace", fontSize: 12, color: row.cert === '—' ? '#94A3B8' : '#334155' }}>{row.cert}</span>
                  </td>
                  <td style={dashStyles.td}><span style={{ fontSize: 13 }}>{row.cliente}</span></td>
                  <td style={dashStyles.td}><span style={{ fontSize: 12, color: '#64748B' }}>{row.instrumento}</span></td>
                  <td style={dashStyles.td}><Badge status={row.status} /></td>
                  <td style={dashStyles.td}><span style={{ fontSize: 12, color: '#94A3B8', fontFamily: "'IBM Plex Mono', monospace" }}>{row.data}</span></td>
                </tr>
              ))}
            </tbody>
          </table>
          <div style={{ padding: '10px 16px', borderTop: '1px solid #F1F4F8' }}>
            <span style={{ fontSize: 12, color: '#1A3A6C', fontWeight: 500, cursor: 'pointer' }}
              onClick={() => onNav('calibracoes')}>Ver todas as calibrações →</span>
          </div>
        </div>
      </div>
    </div>
  </div>
);

const dashStyles = {
  root: { flex: 1, overflow: 'auto', background: '#F1F4F8', padding: 28, fontFamily: "'IBM Plex Sans', sans-serif" },
  pageHeader: { display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 24 },
  pageTitle: { fontSize: 22, fontWeight: 600, color: '#0F172A', letterSpacing: '-0.02em' },
  statsGrid: { display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 28 },
  statCard: {
    background: '#fff', borderRadius: 8, border: '1px solid #E2E8F0',
    boxShadow: '0 1px 3px rgba(0,0,0,0.06)', padding: '18px 20px', cursor: 'pointer',
    transition: 'box-shadow 150ms',
  },
  columns: { display: 'flex', gap: 20, alignItems: 'flex-start' },
  sectionTitle: { fontSize: 12, fontWeight: 600, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 8 },
  card: { background: '#fff', borderRadius: 8, border: '1px solid #E2E8F0', boxShadow: '0 1px 3px rgba(0,0,0,0.06)', padding: '4px 0' },
  alertItem: {
    display: 'flex', alignItems: 'flex-start', gap: 10, padding: '10px 14px',
    borderBottom: '1px solid #F1F4F8', borderLeft: '3px solid', cursor: 'pointer',
  },
  alertAction: { fontSize: 11, color: '#1A3A6C', fontWeight: 600, flexShrink: 0, paddingTop: 1 },
  th: { fontSize: 11, fontWeight: 600, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.05em', padding: '9px 14px', textAlign: 'left', borderBottom: '1px solid #E2E8F0', whiteSpace: 'nowrap' },
  td: { padding: '10px 14px', verticalAlign: 'middle' },
  btnPrimary: {
    display: 'inline-flex', alignItems: 'center', gap: 6, padding: '0 16px', height: 36,
    background: '#1A3A6C', color: '#fff', border: 'none', borderRadius: 6,
    fontFamily: "'IBM Plex Sans', sans-serif", fontSize: 13, fontWeight: 500, cursor: 'pointer',
  },
};

Object.assign(window, { Dashboard, dashStyles, Badge, STATUS_CFG });

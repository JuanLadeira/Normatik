// StandardsModule.jsx — standards management with status indicators

const STANDARDS = [
  { id: 1, tag: 'PAT-001', descricao: 'Micrômetro padrão externo 0–25 mm', fabricante: 'Mitutoyo', modelo: '103-137-10', serie: 'MT2024001', cert: 'CERT-EXT-0019', lab_emissor: 'LAMETRO-SP', cal_date: '15/01/2025', venc: '15/01/2026', dias: 269, status: 'em_dia' },
  { id: 2, tag: 'PAT-002', descricao: 'Bloco padrão grau 1 — conjunto 30 peças', fabricante: 'Starrett', modelo: 'C930', serie: 'ST2023044', cert: 'CERT-EXT-0017', lab_emissor: 'RNI-RJ', cal_date: '08/05/2024', venc: '08/05/2025', dias: 17, status: 'vencendo' },
  { id: 3, tag: 'PAT-003', descricao: 'Termômetro de referência PT100', fabricante: 'Omega', modelo: 'TH-N', serie: 'OM2022099', cert: 'CERT-EXT-0014', lab_emissor: 'LAMETRO-SP', cal_date: '12/03/2024', venc: '12/03/2025', dias: -40, status: 'vencido' },
  { id: 4, tag: 'PAT-004', descricao: 'Calibrador de pressão 0–10 bar', fabricante: 'Fluke', modelo: '700PA5', serie: 'FL2024055', cert: 'CERT-EXT-0021', lab_emissor: 'IPT-SP', cal_date: '20/02/2025', venc: '20/02/2026', dias: 305, status: 'em_dia' },
  { id: 5, tag: 'PAT-005', descricao: 'Voltímetro de referência 1000 V', fabricante: 'Fluke', modelo: '8846A', serie: 'FL2023188', cert: 'CERT-EXT-0018', lab_emissor: 'IPT-SP', cal_date: '10/06/2024', venc: '10/06/2025', dias: 50, status: 'em_dia' },
];

const STD_STATUS = {
  em_dia:   { label: 'Em dia',           bg: '#F0FDF4', fg: '#15803D', border: '#22C55E', dot: '#16A34A' },
  vencendo: { label: 'Vencendo em breve', bg: '#FFFBEB', fg: '#B45309', border: '#F59E0B', dot: '#D97706' },
  vencido:  { label: 'Vencido',          bg: '#FEF2F2', fg: '#B91C1C', border: '#EF4444', dot: '#DC2626' },
};

const StandardsModule = () => {
  const [filter, setFilter] = React.useState('all');

  const filtered = filter === 'all' ? STANDARDS : STANDARDS.filter(s => s.status === filter);

  return (
    <div style={calStyles.root}>
      <div style={dashStyles.pageHeader}>
        <div>
          <div style={dashStyles.pageTitle}>Padrões de Referência</div>
          <div style={{ fontSize: 13, color: '#64748B', marginTop: 2 }}>
            {STANDARDS.filter(s => s.status === 'vencido').length} vencido · {STANDARDS.filter(s => s.status === 'vencendo').length} vencendo em breve
          </div>
        </div>
        <button style={dashStyles.btnPrimary}>
          <IconPlus size={14} style={{ color: '#fff' }} /> Cadastrar padrão
        </button>
      </div>

      {/* Filter tabs */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 16 }}>
        {[['all','Todos'], ['em_dia','Em dia'], ['vencendo','Vencendo'], ['vencido','Vencido']].map(([val, label]) => (
          <button key={val} onClick={() => setFilter(val)} style={{
            padding: '5px 14px', borderRadius: 6, border: '1px solid',
            fontSize: 12, fontWeight: 500, cursor: 'pointer', fontFamily: "'IBM Plex Sans', sans-serif",
            background: filter === val ? '#1A3A6C' : '#fff',
            color: filter === val ? '#fff' : '#475569',
            borderColor: filter === val ? '#1A3A6C' : '#E2E8F0',
            transition: 'all 120ms',
          }}>{label}</button>
        ))}
      </div>

      {/* Table */}
      <div style={{ background: '#fff', borderRadius: 8, border: '1px solid #E2E8F0', boxShadow: '0 1px 3px rgba(0,0,0,0.06)', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ background: '#F8FAFC' }}>
              {['Tag', 'Descrição', 'Certificado', 'Lab. Emissor', 'Vencimento', 'Dias', 'Situação', 'Ações'].map(h => (
                <th key={h} style={{ fontSize: 10, fontWeight: 600, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.06em', padding: '9px 14px', textAlign: 'left', borderBottom: '1px solid #E2E8F0', whiteSpace: 'nowrap' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {filtered.map(s => {
              const cfg = STD_STATUS[s.status];
              return (
                <tr key={s.id} style={{ borderBottom: '1px solid #F1F4F8', transition: 'background 100ms' }}
                  onMouseEnter={e => e.currentTarget.style.background = '#F8FAFC'}
                  onMouseLeave={e => e.currentTarget.style.background = 'transparent'}>
                  <td style={{ padding: '10px 14px' }}>
                    <span style={{ fontFamily: "'IBM Plex Mono', monospace", fontSize: 12, fontWeight: 600, color: '#1A3A6C' }}>{s.tag}</span>
                  </td>
                  <td style={{ padding: '10px 14px' }}>
                    <div style={{ fontSize: 13, fontWeight: 500, color: '#0F172A' }}>{s.descricao}</div>
                    <div style={{ fontSize: 11, color: '#94A3B8', marginTop: 1 }}>{s.fabricante} {s.modelo} · {s.serie}</div>
                  </td>
                  <td style={{ padding: '10px 14px' }}>
                    <span style={{ fontFamily: "'IBM Plex Mono', monospace", fontSize: 11, color: '#64748B' }}>{s.cert}</span>
                  </td>
                  <td style={{ padding: '10px 14px', fontSize: 12, color: '#64748B' }}>{s.lab_emissor}</td>
                  <td style={{ padding: '10px 14px' }}>
                    <span style={{ fontFamily: "'IBM Plex Mono', monospace", fontSize: 12, color: s.status === 'vencido' ? '#DC2626' : s.status === 'vencendo' ? '#D97706' : '#334155', fontWeight: s.status !== 'em_dia' ? 600 : 400 }}>{s.venc}</span>
                  </td>
                  <td style={{ padding: '10px 14px' }}>
                    <span style={{ fontFamily: "'IBM Plex Mono', monospace", fontSize: 12, fontWeight: 600, color: s.dias < 0 ? '#DC2626' : s.dias <= 30 ? '#D97706' : '#64748B' }}>
                      {s.dias < 0 ? `${Math.abs(s.dias)}d atraso` : `${s.dias}d`}
                    </span>
                  </td>
                  <td style={{ padding: '10px 14px' }}>
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5, padding: '3px 9px', borderRadius: 9999, fontSize: 11, fontWeight: 500, background: cfg.bg, color: cfg.fg, border: `1px solid ${cfg.border}` }}>
                      <span style={{ width: 5, height: 5, borderRadius: '50%', background: cfg.dot, flexShrink: 0 }}></span>
                      {cfg.label}
                    </span>
                  </td>
                  <td style={{ padding: '10px 14px' }}>
                    <div style={{ display: 'flex', gap: 6 }}>
                      <button style={stdStyles.actionBtn}>Ver</button>
                      <button style={stdStyles.actionBtn}>Histórico</button>
                      {s.status !== 'em_dia' && <button style={{ ...stdStyles.actionBtn, color: '#DC2626' }}>Renovar</button>}
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
};

const stdStyles = {
  actionBtn: {
    background: 'none', border: 'none', fontSize: 12, fontFamily: "'IBM Plex Sans', sans-serif",
    fontWeight: 500, color: '#1A3A6C', cursor: 'pointer', padding: '2px 6px',
    borderRadius: 4, transition: 'background 100ms',
  },
};

Object.assign(window, { StandardsModule });

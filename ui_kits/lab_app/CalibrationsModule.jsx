// CalibrationsModule.jsx — list + detail with GUM table

const CALIBRATIONS = [
  { id: 1, cert: 'LAB-2025-0051', cliente: 'Usinagem Alfa Ltda', instrumento: 'Micrômetro externo 0–25 mm', tag: 'MIC-001', status: 'concluida', tecnico: 'Carlos Melo', data: '18/04/2025', padrao: 'PAT-001' },
  { id: 2, cert: null, cliente: 'Metais Beta S.A.', instrumento: 'Paquímetro 150 mm', tag: 'PAQ-003', status: 'em_andamento', tecnico: 'Ana Souza', data: '17/04/2025', padrao: 'PAT-001' },
  { id: 3, cert: null, cliente: 'TechParts Ind.', instrumento: 'Termômetro digital PT100', tag: 'TERM-007', status: 'rascunho', tecnico: 'Carlos Melo', data: '16/04/2025', padrao: 'PAT-003' },
  { id: 4, cert: 'LAB-2025-0050', cliente: 'Fundição Central', instrumento: 'Relógio comparador 0–10 mm', tag: 'REL-002', status: 'concluida', tecnico: 'Ana Souza', data: '15/04/2025', padrao: 'PAT-001' },
  { id: 5, cert: null, cliente: 'Ferramentaria Sul', instrumento: 'Bloco de bitola passagem', tag: 'BIT-009', status: 'rascunho', tecnico: 'João Lima', data: '14/04/2025', padrao: 'PAT-002' },
];

const GUM_POINTS = [
  { ponto: 'P1', nominal: '0,000', media: '0,002', uA: '0,0008', uB1: '0,0006', uB2: '0,0003', uc: '0,0010', U: '0,0020', k: '2', erro: '+0,002', corr: '−0,002' },
  { ponto: 'P2', nominal: '5,000', media: '5,003', uA: '0,0009', uB1: '0,0006', uB2: '0,0003', uc: '0,0011', U: '0,0022', k: '2', erro: '+0,003', corr: '−0,003' },
  { ponto: 'P3', nominal: '10,000', media: '10,005', uA: '0,0011', uB1: '0,0006', uB2: '0,0003', uc: '0,0013', U: '0,0026', k: '2', erro: '+0,005', corr: '−0,005' },
  { ponto: 'P4', nominal: '15,000', media: '15,004', uA: '0,0010', uB1: '0,0006', uB2: '0,0003', uc: '0,0012', U: '0,0024', k: '2', erro: '+0,004', corr: '−0,004' },
  { ponto: 'P5', nominal: '20,000', media: '20,006', uA: '0,0012', uB1: '0,0006', uB2: '0,0003', uc: '0,0014', U: '0,0028', k: '2', erro: '+0,006', corr: '−0,006' },
  { ponto: 'P6', nominal: '25,000', media: '25,007', uA: '0,0013', uB1: '0,0006', uB2: '0,0003', uc: '0,0015', U: '0,0030', k: '2', erro: '+0,007', corr: '−0,007' },
];

const CalibrationsModule = ({ onNav }) => {
  const [selected, setSelected] = React.useState(null);
  const cal = selected ? CALIBRATIONS.find(c => c.id === selected) : null;

  return (
    <div style={calStyles.root}>
      {/* Header */}
      <div style={dashStyles.pageHeader}>
        <div>
          <div style={dashStyles.pageTitle}>Calibrações</div>
          <div style={{ fontSize: 13, color: '#64748B', marginTop: 2 }}>{CALIBRATIONS.length} registros · Abril 2025</div>
        </div>
        <button style={dashStyles.btnPrimary}>
          <IconPlus size={14} style={{ color: '#fff' }} /> Nova calibração
        </button>
      </div>

      <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start' }}>
        {/* List */}
        <div style={{ width: 340, flexShrink: 0 }}>
          <div style={{ background: '#fff', borderRadius: 8, border: '1px solid #E2E8F0', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' }}>
            {CALIBRATIONS.map((c, i) => {
              const cfg = STATUS_CFG[c.status];
              const isActive = selected === c.id;
              return (
                <div key={c.id}
                  style={{
                    padding: '12px 14px', cursor: 'pointer', borderBottom: i < CALIBRATIONS.length - 1 ? '1px solid #F1F4F8' : 'none',
                    background: isActive ? '#EEF3FB' : 'transparent',
                    borderLeft: isActive ? '3px solid #1A3A6C' : '3px solid transparent',
                    transition: 'background 100ms',
                  }}
                  onClick={() => setSelected(c.id === selected ? null : c.id)}
                  onMouseEnter={e => { if (!isActive) e.currentTarget.style.background = '#F8FAFC'; }}
                  onMouseLeave={e => { if (!isActive) e.currentTarget.style.background = 'transparent'; }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8 }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 600, color: '#0F172A', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{c.instrumento}</div>
                      <div style={{ fontSize: 11, color: '#64748B', marginTop: 2 }}>{c.cliente}</div>
                    </div>
                    <span style={{ display: 'inline-flex', padding: '2px 7px', borderRadius: 9999, fontSize: 10, fontWeight: 500, background: cfg.bg, color: cfg.fg, border: `1px solid ${cfg.border}`, flexShrink: 0 }}>{cfg.label}</span>
                  </div>
                  <div style={{ display: 'flex', gap: 12, marginTop: 6 }}>
                    <span style={{ fontSize: 11, color: '#94A3B8', fontFamily: "'IBM Plex Mono', monospace" }}>{c.tag}</span>
                    <span style={{ fontSize: 11, color: '#94A3B8' }}>{c.data}</span>
                    <span style={{ fontSize: 11, color: '#94A3B8' }}>{c.tecnico}</span>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Detail */}
        {cal ? (
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ background: '#fff', borderRadius: 8, border: '1px solid #E2E8F0', boxShadow: '0 1px 3px rgba(0,0,0,0.06)', overflow: 'hidden' }}>
              {/* Detail header */}
              <div style={{ padding: '16px 20px', borderBottom: '1px solid #E2E8F0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ fontSize: 15, fontWeight: 600, color: '#0F172A' }}>{cal.instrumento}</div>
                  <div style={{ fontSize: 12, color: '#64748B', marginTop: 2, fontFamily: "'IBM Plex Mono', monospace" }}>{cal.tag} · {cal.cliente}</div>
                </div>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                  <Badge status={cal.status} />
                  {cal.status === 'concluida' && (
                    <button style={{ ...dashStyles.btnPrimary, background: '#00B5A4', height: 32, fontSize: 12 }}>
                      <IconCert size={13} style={{ color: '#fff' }} /> Ver certificado
                    </button>
                  )}
                </div>
              </div>

              {/* Meta */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 0, borderBottom: '1px solid #E2E8F0' }}>
                {[
                  ['Técnico', cal.tecnico],
                  ['Data', cal.data],
                  ['Padrão', cal.padrao],
                  ['Certificado', cal.cert || '—'],
                ].map(([label, val]) => (
                  <div key={label} style={{ padding: '12px 16px', borderRight: '1px solid #F1F4F8' }}>
                    <div style={{ fontSize: 10, fontWeight: 600, color: '#94A3B8', textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: 4 }}>{label}</div>
                    <div style={{ fontSize: 13, fontWeight: 500, color: '#334155', fontFamily: ['Data','Certificado'].includes(label) ? "'IBM Plex Mono', monospace" : 'inherit' }}>{val}</div>
                  </div>
                ))}
              </div>

              {/* GUM Table */}
              <div style={{ padding: '16px 20px 10px' }}>
                <div style={{ fontSize: 11, fontWeight: 600, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: 10 }}>Resultados — Cálculo GUM (ISO/IEC Guide 98-3) · unidade: mm</div>
                <div style={{ overflowX: 'auto' }}>
                  <table style={{ width: '100%', borderCollapse: 'collapse', fontFamily: "'IBM Plex Mono', monospace", fontSize: 11 }}>
                    <thead>
                      <tr style={{ background: '#F8FAFC' }}>
                        {['Ponto', 'Nominal', 'Média', 'Erro', 'Correção', 'u_A', 'u_B1', 'u_B2', 'u_c', 'U', 'k'].map(h => (
                          <th key={h} style={{ padding: '7px 10px', textAlign: 'right', fontFamily: "'IBM Plex Sans', monospace", fontSize: 10, fontWeight: 600, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.05em', borderBottom: '1px solid #E2E8F0', whiteSpace: 'nowrap' }}>{h}</th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {GUM_POINTS.map((row, i) => (
                        <tr key={i} style={{ borderBottom: '1px solid #F1F4F8' }}
                          onMouseEnter={e => e.currentTarget.style.background = '#F8FAFC'}
                          onMouseLeave={e => e.currentTarget.style.background = 'transparent'}>
                          {[row.ponto, row.nominal, row.media, row.erro, row.corr, row.uA, row.uB1, row.uB2, row.uc, row.U, row.k].map((v, j) => (
                            <td key={j} style={{ padding: '7px 10px', textAlign: 'right', color: j === 3 ? '#1A3A6C' : j === 9 ? '#006960' : '#334155', fontWeight: j === 9 ? 600 : 400 }}>{v}</td>
                          ))}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <div style={{ marginTop: 10, padding: '8px 10px', background: '#F8FAFC', borderRadius: 6, fontSize: 11, color: '#64748B', fontFamily: "'IBM Plex Sans', sans-serif" }}>
                  k = 2 · Nível de confiança ≈ 95% · Distribuição normal
                </div>
              </div>
            </div>
          </div>
        ) : (
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', height: 200, color: '#94A3B8', fontSize: 13 }}>
            Selecione uma calibração para ver os detalhes
          </div>
        )}
      </div>
    </div>
  );
};

const calStyles = {
  root: { flex: 1, overflow: 'auto', background: '#F1F4F8', padding: 28, fontFamily: "'IBM Plex Sans', sans-serif" },
};

Object.assign(window, { CalibrationsModule });

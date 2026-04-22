// CertificatesModule.jsx — certificates list + preview panel

const CERTIFICATES = [
  { id: 1, num: 'LAB-2025-0051', instrumento: 'Micrômetro externo 0–25 mm', tag: 'MIC-001', cliente: 'Usinagem Alfa Ltda', tecnico: 'Carlos Melo', emissao: '18/04/2025', proxima: '18/04/2026', status: 'aprovado' },
  { id: 2, num: 'LAB-2025-0050', instrumento: 'Relógio comparador 0–10 mm', tag: 'REL-002', cliente: 'Fundição Central', tecnico: 'Ana Souza', emissao: '15/04/2025', proxima: '15/04/2026', status: 'aprovado' },
  { id: 3, num: 'LAB-2025-0049', instrumento: 'Paquímetro 200 mm', tag: 'PAQ-001', cliente: 'Metais Beta S.A.', tecnico: 'Carlos Melo', emissao: '10/04/2025', proxima: '10/04/2026', status: 'aprovado' },
  { id: 4, num: 'LAB-2025-0044', instrumento: 'Torquímetro 5–50 N·m', tag: 'TRQ-003', cliente: 'AutoPeças Norte', tecnico: 'João Lima', emissao: '02/04/2025', proxima: '02/04/2026', status: 'revogado' },
  { id: 5, num: 'LAB-2025-0043', instrumento: 'Termômetro de contato', tag: 'TERM-002', cliente: 'Lab Qualidade SP', tecnico: 'Ana Souza', emissao: '01/04/2025', proxima: '01/04/2026', status: 'aprovado' },
];

const CERT_STATUS = {
  aprovado: { label: 'Aprovado', bg: '#E6FAFA', fg: '#006960', border: '#00B5A4' },
  revogado: { label: 'Revogado', bg: '#FEF2F2', fg: '#B91C1C', border: '#EF4444' },
};

const CertificatesModule = () => {
  const [selected, setSelected] = React.useState(1);
  const cert = CERTIFICATES.find(c => c.id === selected);
  const cfg = cert ? CERT_STATUS[cert.status] : null;

  return (
    <div style={calStyles.root}>
      <div style={dashStyles.pageHeader}>
        <div>
          <div style={dashStyles.pageTitle}>Certificados</div>
          <div style={{ fontSize: 13, color: '#64748B', marginTop: 2 }}>
            {CERTIFICATES.filter(c => c.status === 'aprovado').length} ativos · {CERTIFICATES.filter(c => c.status === 'revogado').length} revogado
          </div>
        </div>
      </div>

      <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start' }}>
        {/* List */}
        <div style={{ width: 340, flexShrink: 0, background: '#fff', borderRadius: 8, border: '1px solid #E2E8F0', boxShadow: '0 1px 3px rgba(0,0,0,0.06)', overflow: 'hidden' }}>
          {CERTIFICATES.map((c, i) => {
            const st = CERT_STATUS[c.status];
            const isActive = selected === c.id;
            return (
              <div key={c.id}
                style={{ padding: '12px 14px', cursor: 'pointer', borderBottom: i < CERTIFICATES.length - 1 ? '1px solid #F1F4F8' : 'none', background: isActive ? '#EEF3FB' : 'transparent', borderLeft: isActive ? '3px solid #1A3A6C' : '3px solid transparent', transition: 'background 100ms' }}
                onClick={() => setSelected(c.id)}
                onMouseEnter={e => { if (!isActive) e.currentTarget.style.background = '#F8FAFC'; }}
                onMouseLeave={e => { if (!isActive) e.currentTarget.style.background = 'transparent'; }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8 }}>
                  <span style={{ fontFamily: "'IBM Plex Mono', monospace", fontSize: 12, fontWeight: 600, color: '#1A3A6C' }}>{c.num}</span>
                  <span style={{ display: 'inline-flex', padding: '1px 7px', borderRadius: 9999, fontSize: 10, fontWeight: 500, background: st.bg, color: st.fg, border: `1px solid ${st.border}`, flexShrink: 0 }}>{st.label}</span>
                </div>
                <div style={{ fontSize: 12, fontWeight: 500, color: '#334155', marginTop: 4, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{c.instrumento}</div>
                <div style={{ fontSize: 11, color: '#94A3B8', marginTop: 2 }}>{c.cliente} · {c.emissao}</div>
              </div>
            );
          })}
        </div>

        {/* Preview panel */}
        {cert && (
          <div style={{ flex: 1, minWidth: 0 }}>
            {/* Preview header */}
            <div style={{ background: '#fff', borderRadius: 8, border: '1px solid #E2E8F0', boxShadow: '0 1px 3px rgba(0,0,0,0.06)', overflow: 'hidden' }}>
              <div style={{ padding: '16px 20px', borderBottom: '1px solid #E2E8F0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ fontSize: 15, fontWeight: 600, color: '#0F172A' }}>Certificado de Calibração</div>
                  <div style={{ fontFamily: "'IBM Plex Mono', monospace", fontSize: 12, color: '#64748B', marginTop: 2 }}>{cert.num}</div>
                </div>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                  <span style={{ display: 'inline-flex', padding: '3px 10px', borderRadius: 9999, fontSize: 11, fontWeight: 500, background: cfg.bg, color: cfg.fg, border: `1px solid ${cfg.border}` }}>{cfg.label}</span>
                  {cert.status === 'aprovado' && (
                    <button style={{ ...dashStyles.btnPrimary, height: 32, fontSize: 12, gap: 5 }}>
                      <IconDownload size={13} style={{ color: '#fff' }} /> Download PDF
                    </button>
                  )}
                  {cert.status === 'aprovado' && (
                    <button style={{ ...dashStyles.btnPrimary, background: '#DC2626', height: 32, fontSize: 12 }}>Revogar</button>
                  )}
                </div>
              </div>

              {/* Certificate body mock */}
              <div style={{ padding: '20px 24px' }}>
                {/* ISO header */}
                <div style={{ border: '1.5px solid #E2E8F0', borderRadius: 8, padding: '16px 20px', marginBottom: 16 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <div>
                      <div style={{ fontSize: 16, fontWeight: 700, color: '#1A3A6C', letterSpacing: '-0.01em' }}>Normatiq Demo Lab</div>
                      <div style={{ fontSize: 12, color: '#64748B', marginTop: 2 }}>CNPJ 00.000.000/0001-00 · Rua da Metrologia, 100 — São Paulo, SP</div>
                      <div style={{ fontSize: 11, color: '#94A3B8', marginTop: 1 }}>Acreditado CGCRE/INMETRO · Escopo: dimensional, temperatura</div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ fontSize: 10, color: '#94A3B8', textTransform: 'uppercase', letterSpacing: '0.07em' }}>Certificado Nº</div>
                      <div style={{ fontFamily: "'IBM Plex Mono', monospace", fontSize: 16, fontWeight: 700, color: '#1A3A6C' }}>{cert.num}</div>
                      <div style={{ fontSize: 11, color: '#94A3B8', marginTop: 2 }}>Emitido em {cert.emissao}</div>
                    </div>
                  </div>
                </div>

                {/* Fields grid */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 16 }}>
                  {[
                    ['Cliente', cert.cliente],
                    ['Instrumento', cert.instrumento],
                    ['Tag / Código', cert.tag],
                    ['Técnico responsável', cert.tecnico],
                    ['Data de emissão', cert.emissao],
                    ['Próxima calibração', cert.proxima],
                  ].map(([label, val]) => (
                    <div key={label} style={{ background: '#F8FAFC', borderRadius: 6, padding: '10px 14px' }}>
                      <div style={{ fontSize: 10, fontWeight: 600, color: '#94A3B8', textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: 3 }}>{label}</div>
                      <div style={{ fontSize: 13, fontWeight: 500, color: '#334155' }}>{val}</div>
                    </div>
                  ))}
                </div>

                {/* Results table preview */}
                <div style={{ fontSize: 10, fontWeight: 600, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: 8 }}>Tabela de resultados (extrato)</div>
                <div style={{ border: '1px solid #E2E8F0', borderRadius: 6, overflow: 'hidden' }}>
                  <table style={{ width: '100%', borderCollapse: 'collapse', fontFamily: "'IBM Plex Mono', monospace", fontSize: 11 }}>
                    <thead>
                      <tr style={{ background: '#F8FAFC' }}>
                        {['Ponto', 'Nominal', 'Indicação média', 'Erro', 'U (k=2)', 'Nível conf.'].map(h => (
                          <th key={h} style={{ padding: '6px 10px', textAlign: 'right', fontSize: 10, fontWeight: 600, color: '#64748B', fontFamily: "'IBM Plex Sans', sans-serif", textTransform: 'uppercase', letterSpacing: '0.05em', borderBottom: '1px solid #E2E8F0' }}>{h}</th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {[['P1','0,000 mm','0,002 mm','+0,002 mm','0,0020 mm','95%'],['P3','10,000 mm','10,005 mm','+0,005 mm','0,0026 mm','95%'],['P6','25,000 mm','25,007 mm','+0,007 mm','0,0030 mm','95%']].map((row, i) => (
                        <tr key={i} style={{ borderBottom: i < 2 ? '1px solid #F1F4F8' : 'none' }}>
                          {row.map((v, j) => (
                            <td key={j} style={{ padding: '6px 10px', textAlign: 'right', color: '#334155' }}>{v}</td>
                          ))}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                {cert.status === 'revogado' && (
                  <div style={{ marginTop: 14, background: '#FEF2F2', border: '1px solid #FCA5A5', borderRadius: 6, padding: '10px 14px', display: 'flex', gap: 8, alignItems: 'center' }}>
                    <IconAlert size={14} style={{ color: '#DC2626', flexShrink: 0 }} />
                    <span style={{ fontSize: 12, color: '#B91C1C', fontWeight: 500 }}>Este certificado foi revogado. Não é válido para fins de rastreabilidade.</span>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

Object.assign(window, { CertificatesModule });

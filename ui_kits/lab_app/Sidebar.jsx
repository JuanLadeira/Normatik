// Sidebar.jsx — Normatiq lab_app sidebar navigation

const Sidebar = ({ active, onNav, alerts }) => {
  const items = [
    { id: 'dashboard', label: 'Dashboard', icon: IconGrid },
    { id: 'calibracoes', label: 'Calibrações', icon: IconRuler, badge: alerts.calibracoes },
    { id: 'padroes', label: 'Padrões', icon: IconShield, badge: alerts.padroes, badgeType: 'danger' },
    { id: 'certificados', label: 'Certificados', icon: IconCert },
    { id: 'pedidos', label: 'Pedidos', icon: IconClipboard },
    { id: 'clientes', label: 'Clientes', icon: IconUsers },
    { id: 'instrumentos', label: 'Instrumentos', icon: IconGauge },
  ];

  const sections = [
    { label: null, items: ['dashboard'] },
    { label: 'Laboratório', items: ['calibracoes', 'padroes', 'certificados', 'pedidos'] },
    { label: 'Cadastros', items: ['clientes', 'instrumentos'] },
  ];

  const itemMap = Object.fromEntries(items.map(i => [i.id, i]));

  return (
    <div style={sidebarStyles.root}>
      {/* Logo */}
      <div style={sidebarStyles.logo}>
        <div style={sidebarStyles.logoIcon}>
          <div style={{...sidebarStyles.logoBar, height: 10}} />
          <div style={{...sidebarStyles.logoBar, height: 16}} />
          <div style={{...sidebarStyles.logoBar, height: 7, opacity: 0.5}} />
          <div style={{...sidebarStyles.logoBar, height: 4, opacity: 0.3}} />
        </div>
        <span style={sidebarStyles.logoText}>Normatiq</span>
      </div>

      {/* Nav */}
      <nav style={{ flex: 1 }}>
        {sections.map((section, si) => (
          <div key={si} style={{ marginBottom: 4 }}>
            {section.label && (
              <div style={sidebarStyles.sectionLabel}>{section.label}</div>
            )}
            <div style={{ padding: '0 8px' }}>
              {section.items.map(id => {
                const item = itemMap[id];
                const isActive = active === id;
                return (
                  <div
                    key={id}
                    style={{
                      ...sidebarStyles.navItem,
                      ...(isActive ? sidebarStyles.navItemActive : {}),
                    }}
                    onClick={() => onNav(id)}
                  >
                    <item.icon
                      size={16}
                      style={{ flexShrink: 0, opacity: isActive ? 1 : 0.6, color: isActive ? '#00B5A4' : 'rgba(255,255,255,0.8)' }}
                    />
                    <span style={{ flex: 1 }}>{item.label}</span>
                    {item.badge > 0 && (
                      <span style={{
                        ...sidebarStyles.badge,
                        background: item.badgeType === 'danger' ? '#DC2626' : '#D97706',
                      }}>{item.badge}</span>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        ))}
      </nav>

      {/* User */}
      <div style={sidebarStyles.user}>
        <div style={sidebarStyles.avatar}>JL</div>
        <div>
          <div style={{ fontSize: 12, fontWeight: 600, color: '#fff' }}>Juan Ladeira</div>
          <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.45)' }}>Admin</div>
        </div>
      </div>
    </div>
  );
};

const sidebarStyles = {
  root: {
    width: 220, background: '#1A3A6C', display: 'flex', flexDirection: 'column',
    height: '100vh', flexShrink: 0, fontFamily: "'IBM Plex Sans', sans-serif",
  },
  logo: {
    padding: '20px 16px 16px', borderBottom: '1px solid rgba(255,255,255,0.08)',
    marginBottom: 8, display: 'flex', alignItems: 'center', gap: 10,
  },
  logoIcon: {
    width: 28, height: 28, background: '#00B5A4', borderRadius: 6,
    display: 'flex', alignItems: 'flex-end', padding: '4px 4px', gap: 2, flexShrink: 0,
  },
  logoBar: { background: '#1A3A6C', borderRadius: 1, flex: 1 },
  logoText: { fontSize: 16, fontWeight: 600, color: '#fff', letterSpacing: '-0.02em' },
  sectionLabel: {
    fontSize: 10, fontWeight: 600, color: 'rgba(255,255,255,0.3)',
    textTransform: 'uppercase', letterSpacing: '0.1em',
    padding: '10px 16px 3px', marginTop: 4,
  },
  navItem: {
    display: 'flex', alignItems: 'center', gap: 10, padding: '8px 10px',
    borderRadius: 6, fontSize: 13, fontWeight: 500, color: 'rgba(255,255,255,0.65)',
    cursor: 'pointer', transition: 'all 120ms', userSelect: 'none',
  },
  navItemActive: { background: 'rgba(255,255,255,0.12)', color: '#fff' },
  badge: {
    color: '#fff', fontSize: 10, fontWeight: 600,
    padding: '1px 5px', borderRadius: 9999,
  },
  user: {
    padding: '12px 14px', borderTop: '1px solid rgba(255,255,255,0.08)',
    display: 'flex', alignItems: 'center', gap: 10,
  },
  avatar: {
    width: 30, height: 30, borderRadius: '50%', background: '#00B5A4',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    fontSize: 11, fontWeight: 700, color: '#1A3A6C', flexShrink: 0,
  },
};

// Icon components (inline SVG stubs)
const Ico = ({ d, size = 16, style, viewBox = "0 0 16 16", fill = "none", stroke = "currentColor" }) => (
  <svg width={size} height={size} viewBox={viewBox} fill={fill} stroke={stroke} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" style={style}>
    {typeof d === 'string' ? <path d={d} /> : d}
  </svg>
);

const IconGrid = ({ size, style }) => <Ico size={size} style={style} d={<><rect x="2" y="2" width="5" height="5" rx="1"/><rect x="9" y="2" width="5" height="5" rx="1"/><rect x="2" y="9" width="5" height="5" rx="1"/><rect x="9" y="9" width="5" height="5" rx="1"/></>} />;
const IconRuler = ({ size, style }) => <Ico size={size} style={style} d="M2 11L11 2l3 3-9 9-3-3z M7 4l2 2 M5 6l2 2 M9 8l2 2" />;
const IconShield = ({ size, style }) => <Ico size={size} style={style} d="M8 2l5 2.5v4C13 11.5 11 14 8 15c-3-1-5-3.5-5-6.5v-4L8 2z" />;
const IconCert = ({ size, style }) => <Ico size={size} style={style} d={<><rect x="3" y="2" width="10" height="12" rx="1.5"/><line x1="5.5" y1="6" x2="10.5" y2="6"/><line x1="5.5" y1="8.5" x2="10.5" y2="8.5"/><line x1="5.5" y1="11" x2="8" y2="11"/></>} />;
const IconClipboard = ({ size, style }) => <Ico size={size} style={style} d={<><rect x="3" y="3" width="10" height="12" rx="1.5"/><path d="M6 3V2h4v1"/><line x1="5.5" y1="7" x2="10.5" y2="7"/><line x1="5.5" y1="9.5" x2="10.5" y2="9.5"/><line x1="5.5" y1="12" x2="8" y2="12"/></>} />;
const IconUsers = ({ size, style }) => <Ico size={size} style={style} d="M11 13c0-2-1.3-3.5-3-3.5S5 11 5 13 M10 7a2 2 0 11-4 0 2 2 0 014 0z M14 13c0-1.5-1-2.8-2.5-3.2 M13 7a2 2 0 100-4" />;
const IconGauge = ({ size, style }) => <Ico size={size} style={style} d={<><circle cx="8" cy="8" r="6"/><path d="M8 8l3-3"/><circle cx="8" cy="8" r="1" fill="currentColor" stroke="none"/></>} />;
const IconBell = ({ size, style }) => <Ico size={size} style={style} d="M8 2a4 4 0 014 4v3l1.5 2.5h-11L4 9V6a4 4 0 014-4z M6.5 13.5a1.5 1.5 0 003 0" />;
const IconPlus = ({ size, style }) => <Ico size={size} style={style} d="M8 3v10 M3 8h10" />;
const IconDownload = ({ size, style }) => <Ico size={size} style={style} d="M8 3v8 M5 8l3 3 3-3 M3 13h10" />;
const IconCheck = ({ size, style }) => <Ico size={size} style={style} d="M3 8l3 3 7-6" />;
const IconAlert = ({ size, style }) => <Ico size={size} style={style} d={<><path d="M8 2L2 13h12L8 2z"/><line x1="8" y1="7" x2="8" y2="10"/><circle cx="8" cy="12" r="0.5" fill="currentColor"/></>} />;
const IconChevronRight = ({ size, style }) => <Ico size={size} style={style} d="M6 4l4 4-4 4" />;
const IconCalendar = ({ size, style }) => <Ico size={size} style={style} d={<><rect x="2" y="3" width="12" height="11" rx="1.5"/><line x1="2" y1="7" x2="14" y2="7"/><line x1="5" y1="2" x2="5" y2="4"/><line x1="11" y1="2" x2="11" y2="4"/></>} />;

Object.assign(window, {
  Sidebar,
  IconGrid, IconRuler, IconShield, IconCert, IconClipboard,
  IconUsers, IconGauge, IconBell, IconPlus, IconDownload,
  IconCheck, IconAlert, IconChevronRight, IconCalendar, Ico,
  sidebarStyles,
});

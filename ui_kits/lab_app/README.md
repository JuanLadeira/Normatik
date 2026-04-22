# UI Kit — lab_app

## Overview
Interactive click-through prototype of the Normatiq **lab_app** — the primary tool for lab managers, technicians, and attendants.

## Design width
360dp mobile-first base; prototype renders at 1280px desktop (sidebar + content layout).

## Screens covered
1. **Dashboard** — KPI cards, alerts, recent calibrations
2. **Calibrações** — list view, calibration detail with GUM measurement table
3. **Padrões** — standards list with status indicators
4. **Certificados** — certificates list, certificate preview

## Files
- `index.html` — entry point, loads all components
- `Sidebar.jsx` — sidebar navigation + branding
- `TopBar.jsx` — top bar with page title + actions
- `Dashboard.jsx` — dashboard screen
- `CalibrationsModule.jsx` — calibrations list + detail
- `StandardsModule.jsx` — standards management
- `CertificatesModule.jsx` — certificates list

## Notes
- All data is mocked; no API calls
- Language: pt-BR throughout
- Font: IBM Plex Sans + IBM Plex Mono (Google Fonts)

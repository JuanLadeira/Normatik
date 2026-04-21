# Normatiq Design System

## Product Overview

**Normatiq** is a multi-tenant metrology SaaS for calibration laboratories in Brazil. It automates uncertainty calculations (GUM / ISO/IEC Guide 98-3), manages calibration standards traceability, generates ISO/IEC 17025-compliant certificates, and provides a client portal for lab customers to access their instruments and certificates.

**Tech stack:** FastAPI backend · Flutter frontend (mobile-first, 360dp base) · PostgreSQL with RLS multi-tenancy · Celery + Redis for async jobs

**Three Flutter apps in the monorepo:**
- `lab_app` — primary tool for lab managers, technicians, and attendants
- `client_portal` — external portal for lab customers
- `admin_app` — superadmin panel for managing all tenants and plans

**Sources provided:**
- Product planning document (Normatiq — Planejamento do Sistema) — full module/epic breakdown
- GitHub repo: https://github.com/JuanLadeira/Normatik (empty at time of design system creation — greenfield)
- No Figma link provided

> Because the repository was empty, this design system was designed from first principles, informed by the product description, the Flutter/mobile-first constraint, and the technical/professional nature of the metrology domain.

---

## Personas

| ID | Role | Access |
|----|------|--------|
| P1 | Superadmin (Normatiq team) | admin_app |
| P2 | Lab Manager | lab_app |
| P3 | Calibration Technician | lab_app |
| P4 | Attendant / Sales | lab_app |
| P5 | Lab Customer | client_portal |

---

## CONTENT FUNDAMENTALS

**Language:** Portuguese (Brazil). All UI copy is in pt-BR. Technical terms follow ABNT/INMETRO conventions (incerteza, rastreabilidade, calibração, padrão de referência, etc.).

**Tone:** Professional and precise — this is a tool for ISO-accredited (or accreditation-seeking) laboratories. No casual language. Errors and warnings are clear and actionable, never alarming. System feedback uses direct, imperative verbs: *Salvar*, *Emitir certificado*, *Aprovar pedido*.

**Casing:** Sentence case for all UI labels, navigation, and buttons. Title case only for proper names (e.g., "Certificado de Calibração" as a document title).

**Numbers and units:** Always include units (e.g., `25,3 °C`, `0,005 mm`, `U = 0,012 mm (k=2)`). Comma as decimal separator (Brazilian standard). Scientific notation where appropriate for very small uncertainties.

**Status labels (Portuguese):**
- `Em dia` · `Vencendo em breve` · `Vencido`
- `Rascunho` · `Em andamento` · `Concluída` · `Aprovado` · `Revogado`
- `Ativo` · `Suspenso` · `Trial`

**Emoji:** Never used in UI. This is a professional B2B tool.

**Micro-copy:** Validation messages reference the ISO clause or business rule. E.g.: *"Padrão vencido não pode ser vinculado a uma calibração."*

---

## VISUAL FOUNDATIONS

### Color

Primary palette is deep cobalt blue (`#1A3A6C`) — authority, precision, trust — paired with a vibrant teal accent (`#00B5A4`) representing measurement and accuracy. Backgrounds are cool off-white. The palette intentionally avoids the startup-purple-gradient cliché.

See `colors_and_type.css` for all tokens.

### Typography

**IBM Plex Sans** for all UI text — designed for technical/scientific products, highly legible at small sizes, and carries an engineering precision feel. **IBM Plex Mono** is used for all measurement values, uncertainty results, and certificate numbers — the monospace treatment signals "this is a precise number."

### Spacing & Layout

8px base grid. Mobile-first at 360dp (Flutter baseline). Comfortable density — lab technicians read data tables in the field on phones. Min touch target: 44dp.

### Backgrounds

Clean white surfaces (`#FFFFFF`) on a cool `#F4F6F9` page background. No gradients on backgrounds. Cards use a single-level elevation system (subtle `box-shadow`). Full-bleed imagery is not part of the UI language — content is data-dense.

### Cards

`border-radius: 8px`. Single shadow level: `0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04)`. No colored left-border accents. Borders: `1px solid #E2E8F0`.

### Animation

Subtle and functional only. Fade + translate-up for modals/sheets (150ms ease-out). No bounces. Status chips update with a brief opacity fade. No decorative animation.

### Hover / Press States

- Links/buttons: darken primary 8% on hover; scale(0.97) on press
- Rows/cards: `background: #F8FAFC` on hover
- Destructive actions: red tint on hover

### Borders & Dividers

`#E2E8F0` for dividers and card borders. `#CBD5E1` for input borders. `2px solid` primary for focused inputs.

### Corner Radii

- Inputs, cards: `8px`
- Chips/badges: `999px` (pill)
- Buttons: `6px`
- Bottom sheets / modals: `16px` top corners

### Status Colors

| Status | Color | Hex |
|--------|-------|-----|
| Success / Em dia | Green | `#16A34A` |
| Warning / Vencendo | Amber | `#D97706` |
| Danger / Vencido | Red | `#DC2626` |
| Info | Blue | `#2563EB` |
| Neutral | Gray | `#64748B` |

### Iconography

See ICONOGRAPHY section below.

---

## ICONOGRAPHY

**No custom icon font in the codebase** (greenfield). The design system uses **[Lucide Icons](https://lucide.dev)** loaded from CDN — a clean, consistent 24px stroke-weight icon set well-suited to professional data interfaces.

Flutter apps use the `lucide_icons` pub package or the Material Icons subset (for platform-native feel on mobile).

Key icons used by module:
- Standards (Padrões): `shield-check`, `award`
- Calibrations: `ruler`, `activity`  
- Certificates: `file-check`, `download`
- Clients: `building-2`, `users`
- Instruments: `gauge`, `wrench`
- Calendar / Alerts: `calendar`, `bell`, `alert-triangle`
- Orders: `clipboard-list`, `package`
- Stock: `boxes`, `trending-down`

No emoji. No custom SVG illustrations. Placeholder boxes for complex imagery.

Lucide CDN: `https://unpkg.com/lucide@latest/dist/umd/lucide.min.js`

---

## FILES

```
README.md                    — This file
SKILL.md                     — Agent skill descriptor
colors_and_type.css          — All CSS design tokens (colors, type, spacing)
assets/
  logo.svg                   — Normatiq wordmark
  logo-icon.svg              — Normatiq icon mark
preview/
  colors-primary.html        — Primary color scale
  colors-neutral.html        — Neutral/gray scale
  colors-semantic.html       — Status/semantic colors
  type-display.html          — Display & heading type specimens
  type-body.html             — Body & mono type specimens
  spacing-tokens.html        — Spacing scale
  spacing-radii.html         — Border radius & shadow tokens
  components-buttons.html    — Button variants
  components-inputs.html     — Form inputs
  components-badges.html     — Status badges & chips
  components-cards.html      — Card variants
  components-tables.html     — Data table component
  components-navigation.html — Sidebar & nav patterns
ui_kits/
  lab_app/
    README.md
    index.html               — Interactive lab app prototype
    Sidebar.jsx
    TopBar.jsx
    Dashboard.jsx
    CalibrationsModule.jsx
    StandardsModule.jsx
    CertificatesModule.jsx
```

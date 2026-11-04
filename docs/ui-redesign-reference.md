# TT Staff Pro UI redesign reference notes

## Source and use

- [Mobbin](https://mobbin.com/) public landing-page examples, viewed without MCP.
- Mobbin examples are used to identify interaction patterns. Do not copy another product's branding, copy, or complete screen layouts.
- The account's Free plan does not include Mobbin MCP, so the implementation does not depend on private library search or access.

## Patterns to carry into TT Staff Pro

| Mobbin pattern | Apply to | TT Staff Pro treatment |
| --- | --- | --- |
| Clean dashboards | Home and attendance | Put current status and the next action first; keep secondary summaries below and avoid decorative metric cards without live data. |
| Multi-step forms | Leave, expense, regularization, document requests | Group related fields, keep labels visible, show validation next to the field, and make the primary submit action easy to find. |
| Editable profiles | Account and profile | Separate identity and contact details from preferences and security actions; make profile editing an explicit action. |
| Focused onboarding | Sign-in, organization selection, permissions | Explain one decision per step, show clear progress, and keep recovery/help actions visible. |

## Design direction

- Use neutral surfaces with navy structure and blue primary actions; reserve semantic colors for status.
- Keep dark mode, the selectable accent color, supported languages, and organization-enabled modules.
- Preserve existing data sources, routes, and request behavior while improving hierarchy and clarity.

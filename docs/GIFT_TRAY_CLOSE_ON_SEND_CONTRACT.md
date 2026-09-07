# Gift Tray Close-on-Send Contract

Approved 2026-09-07.

When a viewer successfully sends any gift from the Fameverse gift tray, the tray closes immediately after the server-authoritative gift transaction is accepted.

- Applies to normal one-tap sends and Custom quantity sends.
- Failed, rejected, reconnecting, or insufficient-balance sends do not close the tray.
- Gift animation/audio may continue after the tray closes.
- The close is driven by the existing `useGiftSystem` accepted-send path; UI code must not bypass backend confirmation.

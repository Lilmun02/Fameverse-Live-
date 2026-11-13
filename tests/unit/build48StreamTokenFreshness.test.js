import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import {
  isFreshViewerRoom,
  LIVE_ROOM_STALE_MS,
} from "../../supabase/functions/stream-token/room_freshness.ts";

const now = Date.parse("2026-11-13T20:00:00.000Z");
const at = (offset) => new Date(now + offset).toISOString();

describe("Build 48 viewer Stream-token presence gate", () => {
  it("uses the same 45-second presence window as Live discovery", () => {
    expect(LIVE_ROOM_STALE_MS).toBe(45_000);
    expect(isFreshViewerRoom(at(0), now)).toBe(true);
    expect(isFreshViewerRoom(at(-15_000), now)).toBe(true);
    expect(isFreshViewerRoom(at(-44_999), now)).toBe(true);
    expect(isFreshViewerRoom(at(-45_000), now)).toBe(true);
  });

  it("rejects expired and invalid heartbeats", () => {
    expect(isFreshViewerRoom(at(-45_001), now)).toBe(false);
    expect(isFreshViewerRoom(at(-10 * 60_000), now)).toBe(false);
    expect(isFreshViewerRoom(null, now)).toBe(false);
    expect(isFreshViewerRoom("", now)).toBe(false);
    expect(isFreshViewerRoom("not-a-date", now)).toBe(false);
  });

  it("allows minor clock skew but rejects implausible future values", () => {
    expect(isFreshViewerRoom(at(20_000), now)).toBe(true);
    expect(isFreshViewerRoom(at(31_000), now)).toBe(false);
    expect(isFreshViewerRoom(at(0), Number.NaN)).toBe(false);
  });

  it("enforces the viewer check before any Stream JWT is signed", () => {
    const source = readFileSync(
      new URL("../../supabase/functions/stream-token/index.ts", import.meta.url),
      "utf8",
    );
    expect(source).toContain(
      '.select("id, host_user_id, status, heartbeat_at")',
    );
    const viewerGate = source.indexOf(
      'if (role === "viewer" && !isFreshViewerRoom(room.heartbeat_at))',
    );
    const tokenSigning = source.indexOf(
      "const userToken = await signUserToken",
    );
    expect(viewerGate).toBeGreaterThan(0);
    expect(tokenSigning).toBeGreaterThan(viewerGate);
    expect(source).toContain('"room-presence-expired"');
    expect(source).toContain('if (role === "host") {');
  });
});

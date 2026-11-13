/** The Live presence window matches the existing 45-second discovery rule. */
export const LIVE_ROOM_STALE_MS = 45_000;
const MAX_FUTURE_CLOCK_SKEW_MS = 30_000;

/** Do not issue new viewer tokens for a disconnected/expired room. */
export function isFreshViewerRoom(
  heartbeatAt: string | null | undefined,
  nowMs = Date.now(),
): boolean {
  if (
    typeof heartbeatAt !== "string" ||
    !heartbeatAt.trim() ||
    !Number.isFinite(nowMs)
  ) return false;
  const heartbeatMs = Date.parse(heartbeatAt);
  if (!Number.isFinite(heartbeatMs)) return false;
  return heartbeatMs >= nowMs - LIVE_ROOM_STALE_MS &&
    heartbeatMs <= nowMs + MAX_FUTURE_CLOCK_SKEW_MS;
}

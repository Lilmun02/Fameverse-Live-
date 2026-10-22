/** Pure host-token authorization decision. Viewer credentials stay available. */
export type HostPolicyDecision = "allow" | "deny" | "unavailable";

export function evaluateHostPolicyAccess(input: {
  role: string;
  enabled: boolean;
  permissions?: { can_go_live?: unknown } | null;
  error?: unknown;
}): HostPolicyDecision {
  if (input.role !== "host" || !input.enabled) return "allow";
  if (input.error || !input.permissions ||
      typeof input.permissions.can_go_live !== "boolean") {
    return "unavailable";
  }
  return input.permissions.can_go_live ? "allow" : "deny";
}

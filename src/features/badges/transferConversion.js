// Fameverse DRAFT migration policy — recognition only, never local spending.
// Mirror of public.calculate_badge_transfer_level in the staged SQL migration.
// The SQL function is authoritative; this helper only previews the result.
export const SUPPORTED_BADGE_SOURCES = Object.freeze(['tiktok', 'favorited', 'epic'])
export const MAX_IMPORTED_RECOGNITION_LEVEL = 25

export function suggestedTransferLevel(sourcePlatform, sourceLevel) {
  const source = String(sourcePlatform || '').trim().toLowerCase()
  const number = Number(sourceLevel)
  if (!SUPPORTED_BADGE_SOURCES.includes(source) ||
      !Number.isInteger(number) || number < 1 || number > 99 ||
      (source === 'tiktok' && number > 50)) {
    return null
  }
  return Math.min(MAX_IMPORTED_RECOGNITION_LEVEL, 5 + Math.floor(number * 2 / 5))
}

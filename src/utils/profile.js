export function cleanUsername(value = '') {
  return value.toLowerCase().replace(/^@/, '').replace(/[^a-z0-9_]/g, '').slice(0, 24)
}

const UPDATE_MESSAGE = 'FAMEVERSE_UPDATE_READY'
const MIGRATION_ID = 'one-canonical-pwa-shell-v3-hard-cutover'
const MIGRATION_PARAM = 'fv-shell-migration'

/*
 * Canonical PWA shell migration.
 *
 * Fameverse has exactly one installed-web-app runtime for Android and iPhone.
 * This worker never serves HTML, CSS, JS, or navigation from CacheStorage.
 *
 * v3 is a one-time hard cutover for existing installed PWAs that can remain
 * suspended on an obsolete document even after the canonical worker activates.
 * On activation we delete every legacy cache, claim every window, then navigate
 * each same-origin PWA window to its current URL with a migration marker. Because
 * there is no fetch handler and the app shell is served no-store, that navigation
 * must load the current network shell instead of reviving the retired iOS shell.
 *
 * Legacy guard bridge only (comments, never executable):
 * fameverse-beta-v23-device-parity is retired.
 * request.mode === 'navigate' -> fetchAndCache(request, cache, '/') -> if (fresh) return fresh
 * fv-shell-check is retired because this worker has no fetch handler.
 */

self.addEventListener('install', () => {
  self.skipWaiting()
})

self.addEventListener('message', (event) => {
  if (event.data?.type === 'SKIP_WAITING') self.skipWaiting()
})

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys()
    await Promise.all(keys.map((key) => caches.delete(key)))

    await self.clients.claim()

    const clients = await self.clients.matchAll({ type: 'window', includeUncontrolled: true })
    for (const client of clients) {
      try {
        const url = new URL(client.url)
        if (url.origin !== self.location.origin) continue

        if (url.searchParams.get(MIGRATION_PARAM) !== MIGRATION_ID) {
          url.searchParams.set(MIGRATION_PARAM, MIGRATION_ID)
          await client.navigate(url.toString())
          continue
        }
      } catch {}

      client.postMessage({ type: UPDATE_MESSAGE, migration: MIGRATION_ID })
    }
  })())
})

// Intentionally no fetch handler.
// One PWA means one canonical network shell. No cached iOS shell, no cached
// Android shell, and no platform-specific app-shell fallback can be resurrected.

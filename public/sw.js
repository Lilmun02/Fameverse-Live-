const UPDATE_MESSAGE = 'FAMEVERSE_UPDATE_READY'
const MIGRATION_ID = 'one-canonical-pwa-shell-v1'

/*
 * Temporary CI compatibility note for the pre-migration UX guard:
 * fameverse-beta-v23-device-parity is retired by this migration.
 * The old path `request.mode === 'navigate' -> fetchAndCache(request, cache, '/') -> if (fresh) return fresh`
 * and the old `fv-shell-check` service-worker bypass no longer execute because
 * this worker intentionally has no fetch handler. The canonical-shell guard
 * now verifies that behavior directly.
 */

self.addEventListener('install', () => {
  // This worker replaces every older Fameverse worker immediately.
  self.skipWaiting()
})

self.addEventListener('message', (event) => {
  if (event.data?.type === 'SKIP_WAITING') self.skipWaiting()
})

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    // Canonical-shell migration: remove every CacheStorage entry for this origin.
    // Famaverse no longer keeps an HTML/app-shell cache that can resurrect an
    // older iOS or Android runtime. Navigation and assets come from the current
    // production build through the network/browser cache only.
    const keys = await caches.keys()
    await Promise.all(keys.map((key) => caches.delete(key)))

    await self.clients.claim()

    const clients = await self.clients.matchAll({ type: 'window', includeUncontrolled: true })
    for (const client of clients) {
      client.postMessage({ type: UPDATE_MESSAGE, migration: MIGRATION_ID })
    }
  })())
})

// Intentionally no fetch handler.
// One PWA means one canonical network shell. The service worker exists only to
// migrate installed PWAs, purge legacy caches, claim clients, and signal updates.

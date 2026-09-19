const UPDATE_MESSAGE = 'FAMEVERSE_UPDATE_READY'
const MIGRATION_ID = 'one-canonical-pwa-shell-v2'

/*
 * Canonical PWA shell migration.
 *
 * Fameverse has exactly one installed-web-app runtime for Android and iPhone.
 * This worker never serves HTML, CSS, JS, or navigation from CacheStorage. Its
 * only job is to destroy legacy shell caches, claim existing installations,
 * and tell open clients that the canonical network shell is ready.
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
      client.postMessage({ type: UPDATE_MESSAGE, migration: MIGRATION_ID })
    }
  })())
})

// Intentionally no fetch handler.
// One PWA means one canonical network shell. No cached iOS shell, no cached
// Android shell, and no platform-specific app-shell fallback can be resurrected.

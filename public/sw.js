const UPDATE_MESSAGE = 'FAMEVERSE_UPDATE_READY'
const MIGRATION_ID = 'one-canonical-pwa-shell-v4-visible-updater'
const MIGRATION_PARAM = 'fv-shell-migration'

/*
 * Canonical Fameverse PWA worker.
 *
 * There is one installed-web-app runtime for iPhone and Android. This worker
 * never serves HTML, CSS, JS, or navigation from CacheStorage. On activation it
 * removes all legacy caches, claims every same-origin window, and performs one
 * network cutover so older installed PWAs can reach the current updater code.
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

// Intentionally no fetch handler: the app shell always comes from the network.

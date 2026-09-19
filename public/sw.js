const UPDATE_MESSAGE = 'FAMEVERSE_UPDATE_READY'
const SHELL_GENERATION = 'canonical-single-pwa-v1'

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

    const clients = await self.clients.matchAll({
      type: 'window',
      includeUncontrolled: true,
    })

    for (const client of clients) {
      client.postMessage({
        type: UPDATE_MESSAGE,
        generation: SHELL_GENERATION,
      })
    }
  })())
})

// Canonical single-PWA runtime:
// - no HTML/app-shell caching
// - no platform-specific shell
// - no cached navigation fallback that can resurrect an older build
// - immutable Vite assets rely on normal HTTP caching instead
// All requests intentionally fall through to the browser/network.

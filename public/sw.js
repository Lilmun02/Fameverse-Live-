const CACHE = 'fameverse-beta-v18'
const APP_SHELL = ['/manifest.webmanifest', '/icon.svg']

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(APP_SHELL)))
  self.skipWaiting()
})

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys()
    await Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key)))
    await self.clients.claim()
  })())
})

async function fetchAndCache(request, cache) {
  try {
    const response = await fetch(request, { cache: 'no-store' })
    if (response && response.ok) await cache.put(request, response.clone())
    return response
  } catch {
    return null
  }
}

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return

  const request = event.request
  const url = new URL(request.url)
  if (url.origin !== self.location.origin) return

  if (request.mode === 'navigate') {
    event.respondWith((async () => {
      const cache = await caches.open(CACHE)
      const network = await fetchAndCache(request, cache)
      if (network) return network

      const cached = await cache.match(request)
      if (cached) return cached

      return new Response('Fameverse is temporarily unavailable.', {
        status: 503,
        headers: { 'Content-Type': 'text/plain; charset=utf-8' },
      })
    })())
    return
  }

  if (url.pathname.startsWith('/assets/')) {
    event.respondWith((async () => {
      const cache = await caches.open(CACHE)
      const cached = await cache.match(request)
      if (cached) return cached

      const response = await fetch(request)
      if (response && response.ok) await cache.put(request, response.clone())
      return response
    })())
    return
  }

  event.respondWith((async () => {
    const cache = await caches.open(CACHE)
    const cached = await cache.match(request)
    const networkPromise = fetchAndCache(request, cache)

    if (cached) {
      event.waitUntil(networkPromise)
      return cached
    }

    return (await networkPromise) || new Response('', { status: 504 })
  })())
})

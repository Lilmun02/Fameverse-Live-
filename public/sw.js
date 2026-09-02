const CACHE = 'fameverse-beta-v21-device-parity'
const APP_SHELL = ['/', '/manifest.webmanifest', '/icon.svg']

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

async function fetchFresh(request) {
  try {
    return await fetch(request, { cache: 'no-store' })
  } catch {
    return null
  }
}

async function fetchAndCache(request, cache, cacheKey = request) {
  const response = await fetchFresh(request)
  if (response && response.ok) await cache.put(cacheKey, response.clone())
  return response
}

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return

  const request = event.request
  const url = new URL(request.url)
  if (url.origin !== self.location.origin) return

  if (url.searchParams.has('fv-shell-check')) {
    event.respondWith((async () => {
      const response = await fetchFresh(request)
      return response || new Response('', { status: 504 })
    })())
    return
  }

  if (request.mode === 'navigate') {
    event.respondWith((async () => {
      const cache = await caches.open(CACHE)
      const forceRefresh = url.searchParams.has('fv-force-refresh')

      if (forceRefresh) {
        const fresh = await fetchAndCache(request, cache, '/')
        if (fresh) return fresh
        const fallback = await cache.match('/')
        if (fallback) return fallback
      }

      const cached = (await cache.match(request)) || (await cache.match('/'))
      const networkPromise = fetchAndCache(request, cache, '/')

      if (cached) {
        event.waitUntil(networkPromise)
        return cached
      }

      const network = await networkPromise
      if (network) return network

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

      const response = await fetchFresh(request)
      if (response && response.ok) await cache.put(request, response.clone())
      return response || new Response('', { status: 504 })
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

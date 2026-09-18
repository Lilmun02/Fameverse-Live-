const CACHE = 'fameverse-one-pwa-v24'
const UPDATE_MESSAGE = 'FAMEVERSE_UPDATE_READY'
const STATIC_SHELL = ['/manifest.webmanifest', '/icon.svg']

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(STATIC_SHELL)))
  self.skipWaiting()
})

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys()
    await Promise.all(
      keys
        .filter((key) => key !== CACHE && key.startsWith('fameverse-'))
        .map((key) => caches.delete(key)),
    )

    await self.clients.claim()

    const clients = await self.clients.matchAll({ type: 'window', includeUncontrolled: true })
    for (const client of clients) {
      client.postMessage({ type: UPDATE_MESSAGE, cache: CACHE })
    }
  })())
})

async function fetchFresh(request) {
  try {
    return await fetch(request, { cache: 'no-store' })
  } catch {
    return null
  }
}

async function networkFirst(request, cacheKey = request) {
  const cache = await caches.open(CACHE)
  const fresh = await fetchFresh(request)

  if (fresh && fresh.ok) {
    await cache.put(cacheKey, fresh.clone())
    return fresh
  }

  return (await cache.match(cacheKey)) || null
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
      const response = await networkFirst(request, '/')
      if (response) return response

      return new Response('Fameverse is temporarily unavailable.', {
        status: 503,
        headers: { 'Content-Type': 'text/plain; charset=utf-8' },
      })
    })())
    return
  }

  if (url.pathname.startsWith('/assets/')) {
    event.respondWith((async () => {
      const response = await networkFirst(request)
      return response || new Response('', { status: 504 })
    })())
    return
  }

  event.respondWith((async () => {
    const cache = await caches.open(CACHE)
    const cached = await cache.match(request)
    const fresh = await fetchFresh(request)

    if (fresh && fresh.ok) {
      await cache.put(request, fresh.clone())
      return fresh
    }

    return cached || new Response('', { status: 504 })
  })())
})

export function registerFameversePwaUpdates() {
  if (!('serviceWorker' in navigator)) return

  let registration = null
  let reloading = false
  let lastShellCheckAt = 0
  const pendingKey = 'fameverse-pwa-update-pending'
  const updateMessageType = 'FAMEVERSE_UPDATE_READY'
  const shellCheckIntervalMs = 15000
  const watchedRegistrations = new WeakSet()

  // Host Live is intentionally removed during the hard reset. Viewer Live remains
  // protected so an update never interrupts somebody who is currently watching.
  const liveIsActive = () => Boolean(document.querySelector('.fv-viewer-live'))

  const purgeLegacyCaches = async () => {
    if (!('caches' in window)) return
    try {
      const keys = await caches.keys()
      await Promise.all(keys.map((key) => caches.delete(key)))
    } catch {}
  }

  const readPending = () => {
    try {
      if (localStorage.getItem(pendingKey) === '1') return true
    } catch {}
    try {
      return sessionStorage.getItem(pendingKey) === '1'
    } catch {
      return false
    }
  }

  const storePending = () => {
    try { localStorage.setItem(pendingKey, '1') } catch {}
    try { sessionStorage.setItem(pendingKey, '1') } catch {}
  }

  const clearPending = () => {
    try { localStorage.removeItem(pendingKey) } catch {}
    try { sessionStorage.removeItem(pendingKey) } catch {}
  }

  const shellAssetSignature = (doc, baseUrl) => {
    const assets = []
    const nodes = doc.querySelectorAll('script[type="module"][src], link[rel="stylesheet"][href]')

    nodes.forEach((node) => {
      const raw = node.getAttribute('src') || node.getAttribute('href')
      if (!raw) return
      try {
        const url = new URL(raw, baseUrl)
        if (url.origin !== window.location.origin) return
        assets.push(url.pathname)
      } catch {}
    })

    if (!assets.length) return null
    return JSON.stringify([...new Set(assets)].sort())
  }

  const currentShellSignature = () => shellAssetSignature(document, window.location.href)

  const latestShellSignature = async () => {
    const url = new URL('/', window.location.origin)
    url.searchParams.set('fv-shell-check', String(Date.now()))
    const response = await fetch(url, {
      cache: 'no-store',
      headers: { 'Cache-Control': 'no-cache' },
    })
    if (!response.ok) return null

    const html = await response.text()
    const doc = new DOMParser().parseFromString(html, 'text/html')
    return shellAssetSignature(doc, window.location.origin)
  }

  const forceNewestShell = () => {
    const url = new URL(window.location.href)
    url.searchParams.set('fv-force-refresh', String(Date.now()))
    window.location.replace(url.toString())
  }

  const applyUpdateNow = () => {
    if (reloading || !readPending()) return
    if (liveIsActive()) {
      showNotice('deferred')
      return
    }

    reloading = true
    showNotice('applying')
    clearPending()
    window.setTimeout(forceNewestShell, 650)
  }

  const showNotice = (mode) => {
    let notice = document.querySelector('[data-fameverse-update-notice]')
    if (!notice) {
      notice = document.createElement('div')
      notice.dataset.fameverseUpdateNotice = 'true'
      notice.className = 'fv-update-notice'
      notice.setAttribute('role', 'status')
      notice.setAttribute('aria-live', 'polite')
      notice.innerHTML = '<span class="fv-update-dot" aria-hidden="true"></span><div><strong></strong><small></small></div><button type="button" data-fameverse-update-action>Update now</button>'
      document.body.appendChild(notice)
      notice.querySelector('[data-fameverse-update-action]')?.addEventListener('click', applyUpdateNow)
    }

    const title = notice.querySelector('strong')
    const detail = notice.querySelector('small')
    const action = notice.querySelector('[data-fameverse-update-action]')

    if (mode === 'deferred') {
      title.textContent = 'Fameverse update ready'
      detail.textContent = 'Finish this Live, then update to the newest version.'
      if (action) action.hidden = true
      notice.dataset.mode = 'deferred'
      return
    }

    if (mode === 'applying') {
      title.textContent = 'Updating Fameverse'
      detail.textContent = 'Restarting into the newest version…'
      if (action) action.hidden = true
      notice.dataset.mode = 'applying'
      return
    }

    title.textContent = 'Fameverse update available'
    detail.textContent = 'Tap Update now to load the newest version.'
    if (action) action.hidden = false
    notice.dataset.mode = 'available'
  }

  const markPending = () => {
    storePending()
    showNotice(liveIsActive() ? 'deferred' : 'available')
  }

  const presentPendingUpdate = () => {
    if (reloading || !readPending()) return
    showNotice(liveIsActive() ? 'deferred' : 'available')
  }

  const checkAppShell = async ({ force = false } = {}) => {
    const now = Date.now()
    if (!force && now - lastShellCheckAt < shellCheckIntervalMs) return
    lastShellCheckAt = now

    try {
      const current = currentShellSignature()
      const latest = await latestShellSignature()
      if (!current || !latest || current === latest) return
      markPending()
    } catch {}
  }

  const cleanForceRefreshMarker = () => {
    const url = new URL(window.location.href)
    if (!url.searchParams.has('fv-force-refresh')) return
    url.searchParams.delete('fv-force-refresh')
    window.history.replaceState({}, '', `${url.pathname}${url.search}${url.hash}`)
  }

  const activateWaitingWorker = () => {
    if (!registration?.waiting) return
    try { registration.waiting.postMessage({ type: 'SKIP_WAITING' }) } catch {}
  }

  const markWaitingWorker = () => {
    if (!registration?.waiting || !navigator.serviceWorker.controller) return
    activateWaitingWorker()
    markPending()
  }

  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (!navigator.serviceWorker.controller) return
    void purgeLegacyCaches()
    markPending()
  })

  navigator.serviceWorker.addEventListener('message', (event) => {
    if (event.data?.type !== updateMessageType) return
    void purgeLegacyCaches()
    markPending()
  })

  const watchRegistration = (nextRegistration) => {
    if (!nextRegistration || watchedRegistrations.has(nextRegistration)) return
    watchedRegistrations.add(nextRegistration)

    nextRegistration.addEventListener('updatefound', () => {
      const worker = nextRegistration.installing
      if (!worker) return

      worker.addEventListener('statechange', () => {
        if (worker.state !== 'installed' || !navigator.serviceWorker.controller) return
        activateWaitingWorker()
        markPending()
      })
    })
  }

  const pollForUpdates = async () => {
    if (document.visibilityState !== 'visible') return

    await purgeLegacyCaches()
    try {
      registration ||= await navigator.serviceWorker.getRegistration()
      watchRegistration(registration)
      await registration?.update()
      markWaitingWorker()
    } catch {}

    await checkAppShell({ force: true })
    presentPendingUpdate()
  }

  window.addEventListener('load', async () => {
    cleanForceRefreshMarker()
    await purgeLegacyCaches()
    try {
      registration = await navigator.serviceWorker.register('/sw.js', { updateViaCache: 'none' })
      watchRegistration(registration)
      await registration.update()
      markWaitingWorker()
    } catch {}
    await checkAppShell({ force: true })
    presentPendingUpdate()
  })

  document.addEventListener('visibilitychange', async () => {
    if (document.visibilityState !== 'visible') return
    await purgeLegacyCaches()
    try {
      registration ||= await navigator.serviceWorker.getRegistration()
      watchRegistration(registration)
      await registration?.update()
      markWaitingWorker()
    } catch {}
    await checkAppShell()
    presentPendingUpdate()
  })

  window.addEventListener('online', async () => {
    await purgeLegacyCaches()
    try {
      registration ||= await navigator.serviceWorker.getRegistration()
      watchRegistration(registration)
      await registration?.update()
      markWaitingWorker()
    } catch {}
    await checkAppShell({ force: true })
    presentPendingUpdate()
  })

  window.setInterval(() => {
    void pollForUpdates()
  }, shellCheckIntervalMs)

  const liveObserver = new MutationObserver(() => {
    if (readPending()) presentPendingUpdate()
  })

  liveObserver.observe(document.documentElement, {
    subtree: true,
    childList: true,
    attributes: true,
    attributeFilter: ['class'],
  })
}

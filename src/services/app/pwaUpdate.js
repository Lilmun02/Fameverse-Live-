export function registerFameversePwaUpdates() {
  if (!('serviceWorker' in navigator)) return

  let registration = null
  let reloading = false
  let lastShellCheckAt = 0
  const pendingKey = 'fameverse-pwa-update-pending'
  const shellCheckIntervalMs = 15000

  const liveIsActive = () => Boolean(
    document.querySelector('.mobile-live-shell.is-live, .fv-viewer-live'),
  )

  const currentBundlePath = () => {
    const script = document.querySelector('script[type="module"][src]')
    if (!script?.src) return null
    try { return new URL(script.src, window.location.href).pathname }
    catch { return null }
  }

  const latestBundlePath = async () => {
    const url = new URL('/', window.location.origin)
    url.searchParams.set('fv-shell-check', String(Date.now()))
    const response = await fetch(url, {
      cache: 'no-store',
      headers: { 'Cache-Control': 'no-cache' },
    })
    if (!response.ok) return null

    const html = await response.text()
    const doc = new DOMParser().parseFromString(html, 'text/html')
    const script = doc.querySelector('script[type="module"][src]')
    const src = script?.getAttribute('src')
    if (!src) return null
    try { return new URL(src, window.location.origin).pathname }
    catch { return null }
  }

  const showNotice = (mode) => {
    let notice = document.querySelector('[data-fameverse-update-notice]')
    if (!notice) {
      notice = document.createElement('div')
      notice.dataset.fameverseUpdateNotice = 'true'
      notice.className = 'fv-update-notice'
      notice.setAttribute('role', 'status')
      notice.setAttribute('aria-live', 'polite')
      notice.innerHTML = '<span class="fv-update-dot" aria-hidden="true"></span><div><strong></strong><small></small></div>'
      document.body.appendChild(notice)
    }

    const title = notice.querySelector('strong')
    const detail = notice.querySelector('small')
    if (mode === 'deferred') {
      title.textContent = 'Fameverse update ready'
      detail.textContent = 'It will install automatically after this Live ends.'
      notice.dataset.mode = 'deferred'
    } else {
      title.textContent = 'Updating Fameverse'
      detail.textContent = 'Restarting into the newest version…'
      notice.dataset.mode = 'applying'
    }
  }

  const markPending = () => {
    sessionStorage.setItem(pendingKey, '1')
    showNotice(liveIsActive() ? 'deferred' : 'applying')
  }

  const forceNewestShell = () => {
    const url = new URL(window.location.href)
    url.searchParams.set('fv-force-refresh', String(Date.now()))
    window.location.replace(url.toString())
  }

  const applyPendingUpdate = () => {
    if (reloading || sessionStorage.getItem(pendingKey) !== '1') return
    if (liveIsActive()) {
      showNotice('deferred')
      return
    }

    reloading = true
    showNotice('applying')
    sessionStorage.removeItem(pendingKey)
    window.setTimeout(forceNewestShell, 350)
  }

  const checkAppShell = async ({ force = false } = {}) => {
    const now = Date.now()
    if (!force && now - lastShellCheckAt < shellCheckIntervalMs) return
    lastShellCheckAt = now

    try {
      const current = currentBundlePath()
      const latest = await latestBundlePath()
      if (!current || !latest || current === latest) return
      markPending()
      applyPendingUpdate()
    } catch {}
  }

  const cleanForceRefreshMarker = () => {
    const url = new URL(window.location.href)
    if (!url.searchParams.has('fv-force-refresh')) return
    url.searchParams.delete('fv-force-refresh')
    window.history.replaceState({}, '', `${url.pathname}${url.search}${url.hash}`)
  }

  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (!navigator.serviceWorker.controller) return
    markPending()
    applyPendingUpdate()
  })

  const watchRegistration = (nextRegistration) => {
    nextRegistration?.addEventListener('updatefound', () => {
      const worker = nextRegistration.installing
      if (!worker) return

      worker.addEventListener('statechange', () => {
        if (worker.state !== 'installed' || !navigator.serviceWorker.controller) return
        markPending()
      })
    })
  }

  window.addEventListener('load', async () => {
    cleanForceRefreshMarker()
    try {
      registration = await navigator.serviceWorker.register('/sw.js', { updateViaCache: 'none' })
      watchRegistration(registration)
      await registration.update()
    } catch {}
    await checkAppShell({ force: true })
    applyPendingUpdate()
  })

  document.addEventListener('visibilitychange', async () => {
    if (document.visibilityState !== 'visible') return
    try {
      registration ||= await navigator.serviceWorker.getRegistration()
      if (registration) watchRegistration(registration)
      await registration?.update()
    } catch {}
    await checkAppShell()
    applyPendingUpdate()
  })

  window.addEventListener('online', async () => {
    try {
      registration ||= await navigator.serviceWorker.getRegistration()
      await registration?.update()
    } catch {}
    await checkAppShell({ force: true })
    applyPendingUpdate()
  })

  const liveObserver = new MutationObserver(() => {
    if (sessionStorage.getItem(pendingKey) === '1') applyPendingUpdate()
  })

  liveObserver.observe(document.documentElement, {
    subtree: true,
    childList: true,
    attributes: true,
    attributeFilter: ['class'],
  })
}

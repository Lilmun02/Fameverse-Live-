export function registerFameversePwaUpdates() {
  if (!('serviceWorker' in navigator)) return

  let registration = null
  let reloading = false
  const pendingKey = 'fameverse-pwa-update-pending'
  const updateMessageType = 'FAMEVERSE_UPDATE_READY'

  const liveIsActive = () => Boolean(
    document.querySelector('.mobile-live-shell.is-live, .fv-viewer-live'),
  )

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
      return
    }

    title.textContent = 'Updating Fameverse'
    detail.textContent = 'Restarting into the newest version…'
    notice.dataset.mode = 'applying'
  }

  const forceNewestShell = () => {
    const url = new URL(window.location.href)
    url.searchParams.set('fv-shell', String(Date.now()))
    window.location.replace(url.toString())
  }

  const applyPendingUpdate = () => {
    if (reloading || !readPending()) return
    if (liveIsActive()) {
      showNotice('deferred')
      return
    }

    reloading = true
    showNotice('applying')
    clearPending()
    window.setTimeout(forceNewestShell, 250)
  }

  const markPending = () => {
    storePending()
    applyPendingUpdate()
  }

  const activateWaitingWorker = () => {
    if (!registration?.waiting) return
    try { registration.waiting.postMessage({ type: 'SKIP_WAITING' }) } catch {}
  }

  const refreshWorker = async () => {
    try {
      registration ||= await navigator.serviceWorker.getRegistration()
      if (!registration) return
      activateWaitingWorker()
      await registration.update()
      activateWaitingWorker()
    } catch {}
  }

  navigator.serviceWorker.addEventListener('message', (event) => {
    if (event.data?.type !== updateMessageType) return
    markPending()
  })

  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (!navigator.serviceWorker.controller) return
    markPending()
  })

  window.addEventListener('load', async () => {
    try {
      registration = await navigator.serviceWorker.register('/sw.js', { updateViaCache: 'none' })
      activateWaitingWorker()
      await registration.update()
      activateWaitingWorker()
    } catch {}
    applyPendingUpdate()
  })

  document.addEventListener('visibilitychange', async () => {
    if (document.visibilityState !== 'visible') return
    await refreshWorker()
    applyPendingUpdate()
  })

  window.addEventListener('online', async () => {
    await refreshWorker()
    applyPendingUpdate()
  })

  const liveObserver = new MutationObserver(() => {
    if (readPending()) applyPendingUpdate()
  })

  liveObserver.observe(document.documentElement, {
    subtree: true,
    childList: true,
    attributes: true,
    attributeFilter: ['class'],
  })
}

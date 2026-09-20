import { supabase } from '../supabase.js'

const BACKEND_RELEASE_CHANNEL = 'pwa'
const BACKEND_REVISION_KEY = 'fameverse-backend-revision-v1'
const RELEASE_CHECK_TIMEOUT_MS = 4000
const UPDATE_SPLASH_MIN_MS = 850

function setBootStatus(message) {
  const status = document.querySelector('[data-fameverse-boot-status]') || document.querySelector('.boot-splash small')
  if (status) status.textContent = message
}

function sleep(ms) {
  return new Promise((resolve) => window.setTimeout(resolve, ms))
}

async function purgeLegacyCaches() {
  if (!('caches' in window)) return
  try {
    const keys = await caches.keys()
    await Promise.all(keys.map((key) => caches.delete(key)))
  } catch {}
}

function shellAssetSignature(doc, baseUrl) {
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

function currentShellSignature() {
  return shellAssetSignature(document, window.location.href)
}

async function latestShellSignature() {
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

function readSeenBackendRevision() {
  try {
    const value = Number(localStorage.getItem(BACKEND_REVISION_KEY) || 0)
    return Number.isSafeInteger(value) && value >= 0 ? value : 0
  } catch {
    return 0
  }
}

function storeSeenBackendRevision(revision) {
  try { localStorage.setItem(BACKEND_REVISION_KEY, String(revision)) } catch {}
}

async function readBackendRelease() {
  const request = supabase
    .from('app_release_state')
    .select('backend_revision, release_label, updated_at')
    .eq('channel', BACKEND_RELEASE_CHANNEL)
    .maybeSingle()

  const timeout = new Promise((resolve) => {
    window.setTimeout(() => resolve({ data: null, error: new Error('backend release check timed out') }), RELEASE_CHECK_TIMEOUT_MS)
  })

  const { data, error } = await Promise.race([request, timeout])
  if (error || !data) return null

  const revision = Number(data.backend_revision)
  if (!Number.isSafeInteger(revision) || revision < 1) return null

  return {
    revision,
    label: String(data.release_label || 'backend'),
    updatedAt: data.updated_at || null,
  }
}

function cleanForceRefreshMarker() {
  const url = new URL(window.location.href)
  if (!url.searchParams.has('fv-force-refresh')) return
  url.searchParams.delete('fv-force-refresh')
  window.history.replaceState({}, '', `${url.pathname}${url.search}${url.hash}`)
}

function forceNewestShell(revision) {
  const url = new URL(window.location.href)
  url.searchParams.set('fv-force-refresh', `${revision}-${Date.now()}`)
  window.location.replace(url.toString())
}

async function refreshServiceWorker() {
  if (!('serviceWorker' in navigator)) return null

  try {
    const registration = await navigator.serviceWorker.register('/sw.js', { updateViaCache: 'none' })
    await registration.update()
    if (registration.waiting) {
      try { registration.waiting.postMessage({ type: 'SKIP_WAITING' }) } catch {}
    }
    return registration
  } catch {
    return null
  }
}

export async function prepareFameverseBeforeMount() {
  cleanForceRefreshMarker()
  setBootStatus('Checking for updates…')

  await purgeLegacyCaches()
  const registrationPromise = refreshServiceWorker()
  const releasePromise = readBackendRelease()
  const latestShellPromise = latestShellSignature().catch(() => null)

  const [registration, release, latestShell] = await Promise.all([
    registrationPromise,
    releasePromise,
    latestShellPromise,
  ])

  void registration
  const currentShell = currentShellSignature()
  const shellChanged = Boolean(currentShell && latestShell && currentShell !== latestShell)

  if (!release) {
    setBootStatus('Opening your Fameverse…')
    return true
  }

  const seenRevision = readSeenBackendRevision()
  if (release.revision <= seenRevision) {
    setBootStatus('Opening your Fameverse…')
    return true
  }

  setBootStatus('Updating Fameverse…')
  storeSeenBackendRevision(release.revision)
  await purgeLegacyCaches()

  // A backend release is the only event allowed to trigger the pre-entry update gate.
  // Reload once so the backend change and any companion shell change arrive together.
  if (shellChanged || release.revision > seenRevision) {
    await sleep(UPDATE_SPLASH_MIN_MS)
    forceNewestShell(release.revision)
    return false
  }

  setBootStatus('Opening your Fameverse…')
  return true
}

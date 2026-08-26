import { useEffect, useState } from 'react'
import { isRunningStandalone } from '../utils/pwa.js'

export function usePwaInstall(setToast) {
  const [installPrompt, setInstallPrompt] = useState(null)
  const [standalone, setStandalone] = useState(isRunningStandalone)

  useEffect(() => {
    const handler = (event) => {
      event.preventDefault()
      setInstallPrompt(event)
    }
    const displayMode = window.matchMedia?.('(display-mode: standalone)')
    const updateStandalone = () => setStandalone(isRunningStandalone())
    window.addEventListener('beforeinstallprompt', handler)
    displayMode?.addEventListener?.('change', updateStandalone)
    return () => {
      window.removeEventListener('beforeinstallprompt', handler)
      displayMode?.removeEventListener?.('change', updateStandalone)
    }
  }, [])

  const installPwa = async () => {
    if (!installPrompt) {
      setToast('Use Safari Share → Add to Home Screen on iPhone')
      return
    }
    await installPrompt.prompt()
    await installPrompt.userChoice
    setInstallPrompt(null)
  }

  return { standalone, installPwa }
}

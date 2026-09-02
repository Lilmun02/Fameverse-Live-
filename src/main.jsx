import React from 'react'
import ReactDOM from 'react-dom/client'
import './features/feedback/beta-feedback.js'
import './features/gifts/renderer/gift-engine.js'
import { registerFameversePwaUpdates } from './services/app/pwaUpdate.js'
import App from './App.jsx'
import './styles/base/global.css'
import './styles/gifts/base.css'
import './styles/live/core.css'
import './styles/live/sheets.css'
import './styles/base/foundation.css'
import './styles/base/viewport-lock.css'
import './styles/legacy/release.css'
import './styles/legacy/qa-fixes.css'
import './styles/live/polish.css'
import './styles/feedback/beta-feedback.css'
import './styles/gifts/ui.css'
import './styles/base/fam1.css'
import './styles/home/fam1.css'
import './styles/live/fam1-shell.css'
import './styles/live/fam1-chat.css'
import './styles/discover/fam1.css'
import './styles/profile/follows.css'
import './styles/base/fam1-v2.css'
import './styles/home/fam1-v2.css'
import './styles/discover/fam1-v2.css'
import './styles/live/fam1-v2.css'
import './styles/live/prelive-setup.css'
import './styles/live/end-live-summary.css'
import './styles/live/viewer-tap-test.css'
import './styles/profile/fam1-v2.css'
import './styles/profile/algorithm-diagnostics.css'
import './styles/base/pwa-update.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
)

registerFameversePwaUpdates()

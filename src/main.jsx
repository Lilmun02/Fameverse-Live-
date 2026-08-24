import React from 'react'
import ReactDOM from 'react-dom/client'
import './flip-guard.js'
import App from './App.jsx'
import './styles.css'
import './gifts.css'
import './live.css'
import './foundation.css'
import './viewport-lock.css'
import './release.css'
import './qa-fixes.css'
import './live-polish.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
)

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js').catch(() => {})
  })
}

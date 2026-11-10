import React from 'react'
import { createRoot } from 'react-dom/client'
import WebOwnerCommandCenter from '../../src/components/web/WebOwnerCommandCenter.jsx'

const section = new URLSearchParams(window.location.search).get('section') || ''
window.history.replaceState({}, '', '/owner' + (section ? '/' + section : ''))
const account = {
  session: { user: { id: '11111111-1111-4111-8111-111111111111' }, access_token: 'fixture.owner.token' },
  profile: { account_role: 'owner' },
}
createRoot(document.getElementById('root')).render(
  <React.StrictMode><WebOwnerCommandCenter account={account}/></React.StrictMode>,
)

import { useEffect, useState } from 'react'
import { supabase } from '../../services/supabase.js'

function format(value) { return Number(value).toLocaleString('en-US') }

export default function WebWallet({ userId, accountRole }) {
  const [wallet, setWallet] = useState(null)
  const [error, setError] = useState('')
  const isOwner = accountRole === 'owner'

  useEffect(() => {
    if (!userId) { setWallet(null); return }
    let active = true
    setWallet(null)
    setError('')
    supabase.rpc('get_my_coin_funding_breakdown').then(({ data, error: rpcError }) => {
      if (!active) return
      if (rpcError || !Array.isArray(data) || !data[0]) {
        setError('Wallet balances are temporarily unavailable.')
        return
      }
      setWallet(data[0])
    }).catch(() => { if (active) setError('Wallet balances are temporarily unavailable.') })
    return () => { active = false }
  }, [userId])

  if (!userId) return null
  return <section className="fv-wallet-panel" aria-label="Your Fameverse wallet">
    <div><span className="fv-web-eyebrow">YOUR WALLET</span><h2>Balances</h2></div>
    {error && <p role="status">{error}</p>}
    {!wallet && !error && <p role="status">Loading your wallet…</p>}
    {wallet && <div className="fv-wallet-grid">
      <article><span>Fame Coins</span><strong>{format(wallet.cash_backed_coins)}</strong><small>Purchased coins</small></article>
      <article><span>Fame Rubies</span><strong>—</strong><small>Earned balance · awaiting verified Ruby conversion</small></article>
      {isOwner && <article><span>Test Coins</span><strong aria-label="Not verified">—</strong><small>Owner-only balance pending dedicated ledger verification</small></article>}
    </div>}
  </section>
}

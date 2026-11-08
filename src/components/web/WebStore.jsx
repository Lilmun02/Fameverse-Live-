import { useEffect, useState } from 'react'
import AuthScreen from '../auth/AuthScreen.jsx'
import { useAccount } from '../../hooks/useAccount.js'
import { supabase } from '../../services/supabase.js'
import '../../styles/web/store.css'
import '../../styles/web/platform.css'
import WebHeader from './WebHeader.jsx'
import WebHero from './WebHero.jsx'
import { WebBlackFridayBanner, WebBlackFridayPreview } from './WebBlackFriday.jsx'
import WebCommunity from './WebCommunity.jsx'
import WebProfilePage from './WebProfilePage.jsx'
import WebSettingsPage from './WebSettingsPage.jsx'
import WebSupportMessenger from './WebSupportMessenger.jsx'

const FALLBACK_PACKS = [
  { id: 'stripe-100', coins: 100, label: '100 Fame Coins' },
  { id: 'stripe-1000', coins: 1000, label: '1,000 Fame Coins' },
  { id: 'stripe-5000', coins: 5000, label: '5,000 Fame Coins' },
]

function formatPrice(cents, currency = 'USD') {
  if (!Number.isInteger(Number(cents))) return null
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: String(currency || 'USD').toUpperCase(),
  }).format(Number(cents) / 100)
}

function passwordRecovery(account) {
  const canUpdatePassword = account.recoveryAuthorized && Boolean(account.session?.user)

  return (
    <main className="fv-web-recovery">
      <WebHeader account={account} onSignIn={() => window.location.assign('/')} />
      <a className="fv-web-back" href="/">← Back to Fameverse</a>
      <section className="fv-web-auth-card">
        <span className="fv-web-eyebrow">ACCOUNT SECURITY</span>
        <h1>{canUpdatePassword ? 'Set a new password' : 'Reset your password'}</h1>
        <p>{canUpdatePassword ? 'Choose a new password for your Fameverse account.' : 'Enter your account email address to request a password reset link.'}</p>
        {canUpdatePassword ? (
          <form className="auth-form" onSubmit={account.completePasswordReset}>
            <label>
              New password
              <input
                type="password"
                autoComplete="new-password"
                minLength={8}
                required
                value={account.recoveryPassword}
                onChange={(event) => account.setRecoveryPassword(event.target.value)}
              />
            </label>
            {account.authMessage && <div className="auth-message" role="status">{account.authMessage}</div>}
            <button className="auth-primary" type="submit">Update password</button>
          </form>
        ) : (
          <form className="auth-form" onSubmit={(event) => { event.preventDefault(); account.requestPasswordReset() }}>
            <label>
              Email address
              <input
                type="email"
                autoComplete="email"
                required
                value={account.authForm.email}
                onChange={(event) => account.setAuthForm((current) => ({ ...current, email: event.target.value }))}
              />
            </label>
            {account.authMessage && <div className="auth-message" role="status">{account.authMessage}</div>}
            <button className="auth-primary" type="submit" disabled={account.resetRequestBusy}>
              {account.resetRequestBusy ? 'Sending…' : 'Email me a reset link'}
            </button>
          </form>
        )}
      </section>
    </main>
  )
}

export default function WebStore() {
  const [toast, setToast] = useState('')
  const [authOpen, setAuthOpen] = useState(false)
  const [checkoutBusy, setCheckoutBusy] = useState('')
  const [stripeConfig, setStripeConfig] = useState(null)
  const [configBusy, setConfigBusy] = useState(false)
  const [configMessage, setConfigMessage] = useState('')
  const [query, setQuery] = useState(() => new URLSearchParams(window.location.search).get('q') || '')
  const account = useAccount({ setToast })
  const signedIn = Boolean(account.session?.user?.id)
  const isPreviewHost = window.location.hostname !== 'fameverse.app'
  const legacyProfileId = new URLSearchParams(window.location.search).get('profile')
  const pathProfileId = window.location.pathname.startsWith('/profile/')
    ? window.location.pathname.slice('/profile/'.length).split('/')[0] : null
  const profileId = pathProfileId || legacyProfileId
  const settingsRequested = window.location.pathname === '/settings'
  const settingsOpen = settingsRequested && signedIn
  const isDiscoverPage = window.location.pathname === '/discover'
  const isCoinsPage = window.location.pathname === '/coins'
  const isHomePage = !settingsRequested && !profileId && !isDiscoverPage && !isCoinsPage

  useEffect(() => {
    document.documentElement.classList.add('fv-web-mode')
    return () => document.documentElement.classList.remove('fv-web-mode')
  }, [])

  // Legacy section bookmarks now redirect to their dedicated pages.
  useEffect(() => {
    if (legacyProfileId && !pathProfileId) {
      window.location.replace(`/profile/${encodeURIComponent(legacyProfileId)}`)
      return
    }
    const fragment = window.location.hash
    if (fragment === '#discover-creators') {
      window.location.replace('/discover')
    } else if (fragment === '#coin-packs') {
      if (window.location.pathname === '/coins') {
        window.history.replaceState(null, '', '/coins')
        window.scrollTo(0, 0)
      } else {
        window.location.replace('/coins')
      }
    }
  }, [legacyProfileId, pathProfileId])

  useEffect(() => {
    if (!signedIn) {
      setStripeConfig(null)
      setConfigMessage('')
      return undefined
    }

    let active = true
    setConfigBusy(true)
    setConfigMessage('')
    supabase.functions.invoke('stripe-checkout-session', {
      body: { action: 'config' },
    }).then(({ data, error }) => {
      if (!active) return
      if (error || !data || data.provider !== 'stripe' || !Array.isArray(data.packs)) {
        setStripeConfig(null)
        setConfigMessage('We could not load coin packages right now. Please refresh and try again.')
        return
      }
      setStripeConfig(data)
      if (!data.checkout_enabled) {
        setConfigMessage('Online checkout is temporarily unavailable. Please try again later.')
      }
    }).catch(() => {
      if (!active) return
      setStripeConfig(null)
      setConfigMessage('We could not connect to the coin store. Please refresh and try again.')
    }).finally(() => {
      if (active) setConfigBusy(false)
    })

    return () => { active = false }
  }, [signedIn])

  const startCheckout = async (pack) => {
    if (!signedIn) {
      setAuthOpen(true)
      return
    }
    if (!stripeConfig?.checkout_enabled) {
      setConfigMessage('Online checkout is temporarily unavailable. Please try again later.')
      return
    }
    if (stripeConfig.environment === 'live' && isPreviewHost) {
      setConfigMessage('Live payments are disabled on preview links. Use the official Fameverse website for live purchases.')
      return
    }

    setCheckoutBusy(pack.id)
    setConfigMessage('')
    try {
      const { data, error } = await supabase.functions.invoke('stripe-checkout-session', {
        body: { action: 'create', pack_id: pack.id, origin_context: 'web' },
      })
      if (error || !data?.checkout_url) {
        setConfigMessage('Stripe could not start checkout for this package. No purchase was completed. Please try another package or come back shortly.')
        return
      }

      const checkoutUrl = new URL(data.checkout_url)
      if (checkoutUrl.protocol !== 'https:' || checkoutUrl.hostname !== 'checkout.stripe.com') {
        setConfigMessage('Checkout returned an unexpected destination. For your security, we stopped the redirect.')
        return
      }
      window.location.assign(checkoutUrl.toString())
    } catch {
      setConfigMessage('We could not start checkout. No purchase was completed. Please try again.')
    } finally {
      setCheckoutBusy('')
    }
  }

  if (!account.authReady) {
    return <main className="fv-web-shell"><WebHeader account={account} onSignIn={() => setAuthOpen(true)} /><div className="fv-web-loading">Opening Fameverse…</div></main>
  }

  if (window.location.pathname === '/reset-password') {
    return passwordRecovery(account)
  }

  if ((authOpen || settingsRequested) && !signedIn) {
    return (
      <main className="fv-web-shell">
        <WebHeader account={account} onSignIn={() => setAuthOpen(true)} />
        <button className="fv-web-back" type="button" onClick={() => { if (settingsRequested) window.location.assign('/'); else setAuthOpen(false) }}>← Back to Fameverse</button>
        <AuthScreen
          authMode={account.authMode}
          setAuthMode={account.setAuthMode}
          authForm={account.authForm}
          setAuthForm={account.setAuthForm}
          authMessage={account.authMessage}
          setAuthMessage={account.setAuthMessage}
          submitAuth={account.submitAuth}
          requestPasswordReset={account.requestPasswordReset}
          resetRequestBusy={account.resetRequestBusy}
        />
      </main>
    )
  }

  return (
    <main className="fv-web-shell">
      <WebHeader account={account} onSignIn={() => setAuthOpen(true)} query={query} onQueryChange={isDiscoverPage ? setQuery : undefined} />
      {isHomePage && <WebBlackFridayBanner />}
      <div className="fv-platform-layout">
        <div className="fv-platform-content">
          {settingsOpen ? (
            <WebSettingsPage account={account} />
          ) : profileId ? (
            <WebProfilePage profileId={profileId} ownUserId={account.session?.user?.id} onBack={() => window.location.assign('/discover')} />
          ) : isDiscoverPage ? (
            <WebCommunity userId={signedIn ? account.session.user.id : null} query={query} onSignIn={() => setAuthOpen(true)} />
          ) : isCoinsPage ? (
            <>
      <section className="fv-web-store-section" id="coin-packs">
        <div className="fv-web-section-heading">
          <div>
            <span className="fv-web-eyebrow">CHOOSE YOUR COINS</span>
            <h2>Fame Coins</h2>
            <p>Secure checkout powered by Stripe.</p>
          </div>
          {signedIn && stripeConfig?.environment && (
            <span className={stripeConfig.environment === 'live' ? 'fv-web-mode fv-web-mode-live' : 'fv-web-mode'}>
              {stripeConfig.environment === 'live' ? 'LIVE CHECKOUT' : 'TEST CHECKOUT'}
            </span>
          )}
        </div>

        {!signedIn && (
          <div className="fv-web-signin-note">
            <span>🔒</span>
            <div><strong>Sign in before checkout</strong><p>Your purchases are attached securely to your Fameverse account.</p></div>
            <button type="button" onClick={() => setAuthOpen(true)}>Sign in</button>
          </div>
        )}

        {configBusy && <div className="fv-web-inline-message">Loading available coin packages…</div>}
        {configMessage && <div className="fv-web-inline-message fv-web-inline-error" role="status">{configMessage}</div>}

        <div className="fv-web-pack-grid">
          {(stripeConfig?.packs?.length ? stripeConfig.packs : FALLBACK_PACKS).map((pack, index) => {
            const price = signedIn ? formatPrice(pack.price_cents, pack.currency) : null
            const disabled = signedIn && (!stripeConfig?.checkout_enabled || configBusy || Boolean(checkoutBusy))
            return (
              <article className={index === 1 ? 'fv-web-pack fv-web-pack-featured' : 'fv-web-pack'} key={pack.id}>
                {index === 1 && <span className="fv-web-popular">POPULAR</span>}
                <div className="fv-web-coin-art" aria-hidden="true">✦</div>
                <h3>{Number(pack.coins).toLocaleString('en-US')}</h3>
                <p className="fv-web-pack-label">Fame Coins</p>
                <div className="fv-web-pack-price">{price || (signedIn ? 'Price unavailable' : 'Sign in to view price')}</div>
                <button
                  type="button"
                  className="fv-web-buy-button"
                  disabled={disabled || (signedIn && !price)}
                  onClick={() => startCheckout(pack)}
                >
                  {checkoutBusy === pack.id ? 'Opening Stripe…' : signedIn ? 'Buy with Stripe' : 'Sign in to buy'}
                </button>
                <small>One-time purchase · Secure hosted checkout</small>
              </article>
            )
          })}
        </div>

        <div className="fv-web-security-note">
          <span>♢</span>
          <p>Payments are processed by Stripe. Fame Coins are credited to your account after Fameverse verifies the payment. Never share your password or payment details in chat.</p>
        </div>
      </section>
            </>
          ) : (
            <>
              <WebHero />
              <WebBlackFridayPreview
                salePacks={stripeConfig?.packs ?? []}
                signedIn={signedIn}
                isPreviewHost={isPreviewHost}
                checkoutEnabled={Boolean(stripeConfig?.checkout_enabled)}
                checkoutBusy={checkoutBusy}
                configBusy={configBusy}
                onCheckout={startCheckout}
                onSignIn={() => setAuthOpen(true)}
              />
              {configBusy && <p className="fv-web-inline-message" role="status">Loading available Black Friday offers…</p>}
              {configMessage && <p className="fv-web-inline-message fv-web-inline-error" role="status">{configMessage}</p>}
            </>
          )}
          {!settingsOpen && !profileId && (
            <footer className="fv-web-footer">
              <a className="fv-web-brand" href="/"><span className="fv-web-mark">F</span><span>FAMEVERSE <b>LIVE</b></span></a>
              <div><a href="/reset-password">Password reset</a><span>Use the message icon for support.</span></div>
              <small>© {new Date().getFullYear()} Fameverse Live</small>
            </footer>
          )}
        </div>
      </div>
      <WebSupportMessenger userId={account.session?.user?.id || null} onSignIn={() => setAuthOpen(true)} />
      {toast && <div className="fv-web-toast" role="status">{toast}</div>}
    </main>
  )
}

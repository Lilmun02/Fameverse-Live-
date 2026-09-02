function stopLiveTap(event) {
  event.stopPropagation()
}

export default function CohostInvitePrompt({ invite, hostName, onAccept, onDecline }) {
  if (!invite) return null

  return (
    <div className="live-sheet-backdrop fv-cohost-invite-backdrop" onPointerDown={stopLiveTap}>
      <section
        className="live-sheet fv-cohost-invite-prompt"
        role="dialog"
        aria-modal="true"
        aria-label="Co-host invitation"
        onPointerDown={stopLiveTap}
      >
        <div className="sheet-handle" aria-hidden="true" />
        <div className="fv-cohost-invite-mark" aria-hidden="true">◫</div>
        <strong>{hostName || 'The host'} invited you to co-host</strong>
        <p>Your camera and microphone will only turn on after you accept.</p>
        <div className="fv-cohost-invite-actions">
          <button type="button" onClick={onDecline}>Decline</button>
          <button type="button" className="is-accept" onClick={onAccept}>Accept</button>
        </div>
      </section>
    </div>
  )
}

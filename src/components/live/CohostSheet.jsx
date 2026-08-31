export default function CohostSheet({ open, onClose, shareRoom }) {
  if (!open) return null

  return (
    <div className="live-sheet-backdrop" onClick={onClose}>
      <div className="live-sheet" onClick={(event) => event.stopPropagation()}>
        <div className="sheet-handle" />
        <div className="sheet-heading">
          <div><span>CO-HOST</span><strong>No requests yet</strong></div>
        </div>
        <p>Realtime co-host requests and remote video are still being connected. No fake users are shown.</p>
        <button className="sheet-primary-action" onClick={shareRoom}>Share live link</button>
      </div>
    </div>
  )
}

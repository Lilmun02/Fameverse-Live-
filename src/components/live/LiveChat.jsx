import { useEffect, useRef } from 'react'

function initialFor(user) {
  return String(user || 'F').trim().charAt(0).toUpperCase() || 'F'
}

function stopLiveTap(event) {
  event.stopPropagation()
}

export default function LiveChat({
  liveMessages,
  commentText,
  setCommentText,
  submitComment,
  onGiftClick = null,
}) {
  const chatScrollRef = useRef(null)

  useEffect(() => {
    const chatNode = chatScrollRef.current
    if (!chatNode) return
    chatNode.scrollTop = chatNode.scrollHeight
  }, [liveMessages])

  const preventKeyboardSubmit = (event) => {
    if (event.key === 'Enter') event.preventDefault()
  }

  return (
    <>
      {liveMessages.length > 0 && (
        <div ref={chatScrollRef} className="fam-chat-stack fv-live-chat-feed" aria-label="Live comments">
          {liveMessages.map((item) => (
            <div className={`fam-chat-line ${item.kind === 'gift' ? 'is-gift' : ''}`} key={item.id}>
              <span className="fam-chat-avatar" aria-hidden="true">{initialFor(item.user)}</span>
              <div className="fam-chat-copy">
                <div className="fam-chat-identity">
                  <strong>{item.user}</strong>
                  {item.badge && (
                    <span className="fam-gifter-badge">
                      <span aria-hidden="true">{item.badge.icon}</span> {item.badge.label}
                    </span>
                  )}
                </div>
                <span className="fam-chat-message">{item.text}</span>
              </div>
            </div>
          ))}
        </div>
      )}

      <form
        className="fam-comment-composer fv-live-composer"
        onSubmit={submitComment}
        onPointerDown={stopLiveTap}
      >
        <div className="fv-live-comment-entry">
          <input
            value={commentText}
            onChange={(event) => setCommentText(event.target.value)}
            onKeyDown={preventKeyboardSubmit}
            enterKeyHint="done"
            maxLength={160}
            placeholder="Say something…"
            aria-label="Add comment"
          />
        </div>
        {onGiftClick && (
          <button
            type="button"
            className="fv-live-gift-button"
            aria-label="Open gifts"
            onPointerDown={stopLiveTap}
            onClick={onGiftClick}
          >
            🎁
          </button>
        )}
        <button
          className="fv-live-send-button"
          type="submit"
          aria-label="Send comment"
          disabled={!commentText.trim()}
          onPointerDown={stopLiveTap}
        >
          ↑
        </button>
      </form>
    </>
  )
}

function timestamp(value) {
  const date = new Date(value)
  return value && Number.isFinite(date.getTime()) ? date.toLocaleString() : 'Unavailable'
}

function Link({ section, filter, id, children, onNavigate }) {
  if (!id) return null
  return <a href={'/owner/' + section + '?' + filter + '=' + encodeURIComponent(id)}
    onClick={event => onNavigate(event, section)}>{children}</a>
}

export default function OwnerCaseRecord({ item, section, onNavigate, onChoose }) {
  const related = Array.isArray(item.case) ? item.case[0] : item.case
  if (section === 'moderation') return <article className="fv-oc-record">
    <div className="fv-oc-record-copy">
      <strong>{item.summary}</strong><span>{item.case_type} · {item.status}</span>
      <span>Case ID: {item.id}</span>
      <span>Opened: {timestamp(item.created_at)} · Updated: {timestamp(item.updated_at)}</span>
      {item.subject_user_id && <a href={'/profile/'+encodeURIComponent(item.subject_user_id)}>Subject profile · {item.subject_user_id}</a>}
      <Link section="audit" filter="caseId" id={item.id} onNavigate={onNavigate}>Audit for this case</Link>
      {item.source_feedback_id && <Link section="support" filter="caseId" id={item.id} onNavigate={onNavigate}>Related support intake</Link>}
      <span>This staged store supplies case summaries, not sanction execution, evidence attachments or appeal decisions.</span>
    </div>
  </article>
  if (section === 'support') return <article className="fv-oc-record">
    <div className="fv-oc-record-copy">
      <strong>Support intake · {item.category || 'Uncategorized'}</strong>
      <p className="fv-oc-case-message">{item.message || 'No message supplied'}</p>
      <span>Intake ID: {item.id}</span>
      <span>Received: {timestamp(item.created_at)}</span>
      {item.user_id && <a href={'/profile/' + encodeURIComponent(item.user_id)}>Member profile · {item.user_id}</a>}
      {related ? <>
        <strong>Case {related.id}</strong><span>{related.case_type} · {related.status}</span>
        <p>{related.summary}</p><span>Updated: {timestamp(related.updated_at)}</span>
        <Link section="audit" filter="caseId" id={related.id} onNavigate={onNavigate}>Audit for this case</Link>
      </> : <span>No linked case. Case creation requires the approved isolated backend.</span>}
      <span>Assignment, notes, attachments and responses are not available in this staged read contract.</span>
    </div>
    {related && <button type="button" onClick={() => onChoose('review_support', related.id)}>Review support case</button>}
  </article>

  return <article className="fv-oc-record"><div className="fv-oc-record-copy">
    <strong>{item.operation} · {item.outcome}</strong>
    <span>Event ID: {item.id}</span><span>Section: {item.section}</span>
    <span>Actor: {item.actor_user_id}</span>
    <span>Target: {item.target_type || 'Unspecified'} · {item.target_id || 'None'}</span>
    <p className="fv-oc-case-message">{item.reason}</p>
    <span>Recorded: {timestamp(item.created_at)}</span>
    {item.case_id && <>
      <span>Case ID: {item.case_id}</span>
      <Link section="support" filter="caseId" id={item.case_id} onNavigate={onNavigate}>Related support intake</Link>
    </>}
    {item.target_id && <Link section="audit" filter="targetId" id={item.target_id} onNavigate={onNavigate}>Audit for this target</Link>}
  </div></article>
}

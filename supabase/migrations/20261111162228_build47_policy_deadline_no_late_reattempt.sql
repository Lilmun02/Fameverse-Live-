-- Build 47: prevent circumventing support after the 10-day deadline
-- by declining first and then accepting on the expired account.
create or replace function public.fv_policy_decision_timestamp()
returns trigger language plpgsql set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    new.notice_started_at := now();
  else
    new.notice_started_at := old.notice_started_at;
    if old.decision in ('accepted', 'declined')
       and new.decision = 'unsigned' then
      raise exception 'Policy decision cannot be reset by the app';
    end if;
    if new.decision = 'accepted'
       and old.decision <> 'accepted'
       and now() >= old.notice_started_at + interval '10 days' then
      raise exception 'Policy deadline passed: contact Fameverse support Monday-Friday';
    end if;
  end if;
  if new.decision = 'unsigned' then
    new.decided_at := null;
  else
    new.decided_at := now();
  end if;
  return new;
end;
$$;

revoke all on function public.fv_policy_decision_timestamp()
  from public, anon, authenticated;

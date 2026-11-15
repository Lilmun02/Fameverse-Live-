-- REVIEW ONLY: NOT A MIGRATION / DO NOT RUN ON PRODUCTION.
-- Generate the official versioned migration with the approved Supabase CLI.
-- Requires isolated Postgres/RLS and authenticated client integration tests.
-- Keep existing accepted records unchanged; NULL means NOT RECORDED.
-- Never infer or backfill checkbox acknowledgement from accepted decisions.

alter table public.policy_acceptances
  add column if not exists checkbox_acknowledged boolean,
  add column if not exists checkbox_acknowledged_at timestamptz;

comment on column public.policy_acceptances.checkbox_acknowledged is
  'User-submitted native policy checkbox assertion; NULL = not recorded.';
comment on column public.policy_acceptances.checkbox_acknowledged_at is
  'Server-generated timestamp for affirmative checkbox acknowledgment; NULL if not recorded.';

create or replace function public.fv_policy_checkbox_timestamp()
returns trigger language plpgsql set search_path = '' as $function$
begin
  if new.decision = 'accepted' and new.checkbox_acknowledged is true then
    if tg_op = 'INSERT' then
      new.checkbox_acknowledged_at := now();
    elsif old.checkbox_acknowledged is distinct from true
       or old.decision is distinct from 'accepted' then
      new.checkbox_acknowledged_at := now();
    else
      new.checkbox_acknowledged_at := old.checkbox_acknowledged_at;
    end if;
  elsif new.decision <> 'accepted' then
    -- A decline is never consent. Old accepted records remain unchanged
    -- unless an authenticated user explicitly changes their decision.
    new.checkbox_acknowledged := null;
    new.checkbox_acknowledged_at := null;
  else
    -- Legacy accepted rows with no checkbox evidence stay NULL.
    new.checkbox_acknowledged := null;
    new.checkbox_acknowledged_at := null;
  end if;
  return new;
end;
$function$;

revoke all on function public.fv_policy_checkbox_timestamp() from public, anon, authenticated;

drop trigger if exists fv_policy_checkbox_timestamp_before_write on public.policy_acceptances;
create trigger fv_policy_checkbox_timestamp_before_write
before insert or update on public.policy_acceptances
for each row execute function public.fv_policy_checkbox_timestamp();

-- Preserve all existing RLS owner rules and original 7+3-day
-- notice/deadline trigger; do not backfill historical consent evidence.

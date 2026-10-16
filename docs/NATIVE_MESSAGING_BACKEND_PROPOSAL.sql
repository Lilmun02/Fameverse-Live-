-- FAMEVERSE NATIVE INBOX / DIRECT MESSAGES — DESIGN REVIEW ONLY.
-- NOT AN APPLIED MIGRATION. DO NOT EXECUTE AGAINST PRODUCTION.
-- Approvals required: founder, database/RLS review, staged two-account QA,
-- content safety / abuse mitigation, and signed internal iPhone acceptance.
-- Client mobile keys MUST NEVER own INSERT permission on server notifications.

create table public.user_inbox_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 160),
  body text not null default '' check (char_length(body) <= 2000),
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index user_inbox_items_by_recipient
  on public.user_inbox_items(user_id, created_at desc);
alter table public.user_inbox_items enable row level security;
revoke all on public.user_inbox_items from anon, authenticated;
grant select on public.user_inbox_items to authenticated;
grant update (read_at) on public.user_inbox_items to authenticated;
create policy inbox_select_self on public.user_inbox_items
  for select to authenticated using (user_id = (select auth.uid()));
create policy inbox_mark_read_self on public.user_inbox_items
  for update to authenticated using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create table public.direct_conversations (
  id uuid primary key default gen_random_uuid(),
  user_low uuid not null references public.profiles(id) on delete cascade,
  user_high uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint direct_conversations_sorted check (user_low < user_high),
  unique (user_low, user_high)
);
create index direct_conversations_low_recent
  on public.direct_conversations(user_low, updated_at desc);
create index direct_conversations_high_recent
  on public.direct_conversations(user_high, updated_at desc);
alter table public.direct_conversations enable row level security;
revoke all on public.direct_conversations from anon, authenticated;
grant select on public.direct_conversations to authenticated;
create policy conversations_members_read on public.direct_conversations
  for select to authenticated
  using (
    user_low = (select auth.uid()) or user_high = (select auth.uid())
  );

-- Use a trusted server RPC to create a unique unordered pair. Clients cannot
-- create a conversation for two other people or forge membership.
create or replace function public.start_direct_conversation(
  p_other_user_id uuid
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_low uuid;
  v_high uuid;
  v_id uuid;
begin
  if v_me is null or p_other_user_id is null
    or v_me = p_other_user_id then
    raise exception 'Invalid conversation participants';
  end if;
  if not exists (
    select 1 from public.profiles where id = p_other_user_id
  ) then
    raise exception 'Recipient is not available';
  end if;
  v_low := least(v_me, p_other_user_id);
  v_high := greatest(v_me, p_other_user_id);
  insert into public.direct_conversations(user_low, user_high)
  values (v_low, v_high)
  on conflict (user_low, user_high) do nothing
  returning id into v_id;
  if v_id is null then
    select id into v_id from public.direct_conversations
      where user_low = v_low and user_high = v_high;
  end if;
  return v_id;
end;
$$;
revoke all on function public.start_direct_conversation(uuid) from public;
grant execute on function public.start_direct_conversation(uuid)
  to authenticated;

create table public.direct_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.direct_conversations(id)
    on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(btrim(body)) between 1 and 2000),
  created_at timestamptz not null default now(),
  read_at timestamptz
);
create index direct_messages_by_conversation
  on public.direct_messages(conversation_id, created_at desc);
alter table public.direct_messages enable row level security;
revoke all on public.direct_messages from anon, authenticated;
grant select on public.direct_messages to authenticated;
grant insert (conversation_id, sender_id, body)
  on public.direct_messages to authenticated;
grant update (read_at) on public.direct_messages to authenticated;

-- All message operations require existing conversation membership.
create policy direct_messages_members_read on public.direct_messages
  for select to authenticated using (
    exists (
      select 1 from public.direct_conversations c
      where c.id = conversation_id
        and ((select auth.uid()) = c.user_low
          or (select auth.uid()) = c.user_high)
    )
  );
create policy direct_messages_sender_insert on public.direct_messages
  for insert to authenticated with check (
    sender_id = (select auth.uid())
    and exists (
      select 1 from public.direct_conversations c
      where c.id = conversation_id
        and ((select auth.uid()) = c.user_low
          or (select auth.uid()) = c.user_high)
    )
  );
create policy direct_messages_recipient_read_receipt
  on public.direct_messages
  for update to authenticated
  using (
    sender_id <> (select auth.uid())
    and exists (
      select 1 from public.direct_conversations c
      where c.id = conversation_id
        and ((select auth.uid()) = c.user_low
          or (select auth.uid()) = c.user_high)
    )
  )
  with check (
    sender_id <> (select auth.uid())
    and exists (
      select 1 from public.direct_conversations c
      where c.id = conversation_id
        and ((select auth.uid()) = c.user_low
          or (select auth.uid()) = c.user_high)
    )
  );

-- Server-owned timestamp maintenance; clients cannot directly edit rooms.
create or replace function public.touch_direct_conversation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.direct_conversations
    set updated_at = now() where id = new.conversation_id;
  return new;
end;
$$;
revoke all on function public.touch_direct_conversation() from public;
create trigger update_conversation_after_message
  after insert on public.direct_messages
  for each row execute function public.touch_direct_conversation();

-- Never grant direct INSERT on user_inbox_items to authenticated. Server-side
-- notification delivery, moderation, blocking, report/abuse and send limits
-- require an independent approved implementation before public availability.
-- Validate with two users A/B and a third user C in STAGING:
--   A can start A/B, send A/B, read A/B; B can reply/mark A's messages read.
--   C cannot select A/B rooms or messages or insert into A/B.
--   A cannot change B's read status or another user's notification.
--   Anonymous users cannot read/write any of the three tables.
--   Creator discovery excludes self and respects account privacy rules.

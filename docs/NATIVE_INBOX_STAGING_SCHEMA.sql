-- Fameverse Native Inbox: STAGING CANDIDATE ONLY; review before migration.
-- Not authorized for production deployment. No mobile service-role key.
-- Schema intentionally separates private Activity notices from direct chat.
-- No automatic notifications, push permission, payout/coins, or owner controls.

begin;

create table public.user_inbox_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 160),
  body text not null default '' check (char_length(body) <= 2000),
  created_at timestamptz not null default now(),
  read_at timestamptz
);
create index user_inbox_items_recipient_recent
  on public.user_inbox_items (user_id, created_at desc);
alter table public.user_inbox_items enable row level security;
revoke all on public.user_inbox_items from anon, authenticated;
grant select on public.user_inbox_items to authenticated;
grant update (read_at) on public.user_inbox_items to authenticated;
create policy inbox_owner_select on public.user_inbox_items
  for select to authenticated using (user_id = (select auth.uid()));
create policy inbox_owner_mark_read on public.user_inbox_items
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
-- Authenticated clients cannot forge Activity notices; trusted server only.

create table public.direct_user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index direct_blocks_by_blocked on public.direct_user_blocks (blocked_id);
alter table public.direct_user_blocks enable row level security;
revoke all on public.direct_user_blocks from anon, authenticated;
grant select, insert, delete on public.direct_user_blocks to authenticated;
create policy blocks_owner_select on public.direct_user_blocks
  for select to authenticated using (blocker_id = (select auth.uid()));
create policy blocks_owner_insert on public.direct_user_blocks
  for insert to authenticated with check (blocker_id = (select auth.uid()));
create policy blocks_owner_delete on public.direct_user_blocks
  for delete to authenticated using (blocker_id = (select auth.uid()));

create table public.direct_conversations (
  id uuid primary key default gen_random_uuid(),
  user_low uuid not null references public.profiles(id) on delete cascade,
  user_high uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (user_low < user_high),
  unique (user_low, user_high)
);
create index direct_conversations_low_recent on public.direct_conversations
  (user_low, updated_at desc);
create index direct_conversations_high_recent on public.direct_conversations
  (user_high, updated_at desc);
alter table public.direct_conversations enable row level security;
revoke all on public.direct_conversations from anon, authenticated;
grant select on public.direct_conversations to authenticated;
create policy conversations_member_select on public.direct_conversations
  for select to authenticated
  using (user_low = (select auth.uid()) or user_high = (select auth.uid()));

-- Controlled conversation create: no client INSERT on conversation membership.
create function public.start_direct_conversation(p_other_user_id uuid)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_low uuid;
  v_high uuid;
  v_id uuid;
begin
  if v_me is null or p_other_user_id is null or p_other_user_id = v_me then
    raise exception 'Invalid participants';
  end if;
  if not exists (select 1 from public.profiles where id = p_other_user_id) then
    raise exception 'Recipient unavailable';
  end if;
  if exists (
    select 1 from public.direct_user_blocks
    where (blocker_id = v_me and blocked_id = p_other_user_id)
       or (blocker_id = p_other_user_id and blocked_id = v_me)
  ) then
    raise exception 'Conversation unavailable';
  end if;
  v_low := least(v_me, p_other_user_id);
  v_high := greatest(v_me, p_other_user_id);
  select id into v_id from public.direct_conversations
    where user_low = v_low and user_high = v_high;
  if v_id is not null then return v_id; end if;

  -- Serialize new-conversation creation per authenticated user.
  perform pg_advisory_xact_lock(hashtextextended(v_me::text, 182));
  if (
    select count(*) from public.direct_conversations
      where (user_low = v_me or user_high = v_me)
        and created_at > now() - interval '1 hour'
  ) >= 20 then
    raise exception 'Too many new conversations; try again later';
  end if;
  insert into public.direct_conversations (user_low, user_high)
    values (v_low, v_high)
    on conflict (user_low, user_high) do nothing
    returning id into v_id;
  if v_id is null then
    select id into v_id from public.direct_conversations
      where user_low = v_low and user_high = v_high;
  end if;
  return v_id;
end $$;
revoke all on function public.start_direct_conversation(uuid) from public, anon;
grant execute on function public.start_direct_conversation(uuid) to authenticated;

create table public.direct_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null
    references public.direct_conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(btrim(body)) between 1 and 2000),
  created_at timestamptz not null default now(),
  read_at timestamptz
);
create index direct_messages_in_conversation on public.direct_messages
  (conversation_id, created_at desc);
create index direct_messages_by_sender_recent on public.direct_messages
  (sender_id, created_at desc);
alter table public.direct_messages enable row level security;
revoke all on public.direct_messages from anon, authenticated;
grant select on public.direct_messages to authenticated;
grant insert (conversation_id, sender_id, body)
  on public.direct_messages to authenticated;
grant update (read_at) on public.direct_messages to authenticated;
create policy direct_messages_member_select on public.direct_messages
  for select to authenticated
  using (
    exists (select 1 from public.direct_conversations c
      where c.id = conversation_id
        and ((select auth.uid()) = c.user_low
          or (select auth.uid()) = c.user_high))
  );
create policy direct_messages_sender_insert on public.direct_messages
  for insert to authenticated
  with check (
    sender_id = (select auth.uid()) and
    exists (select 1 from public.direct_conversations c
      where c.id = conversation_id
        and ((select auth.uid()) = c.user_low
          or (select auth.uid()) = c.user_high))
  );
create policy direct_messages_recipient_mark_read on public.direct_messages
  for update to authenticated
  using (sender_id <> (select auth.uid()) and
    exists (select 1 from public.direct_conversations c
      where c.id = conversation_id
        and ((select auth.uid()) = c.user_low
          or (select auth.uid()) = c.user_high)))
  with check (sender_id <> (select auth.uid()) and
    exists (select 1 from public.direct_conversations c
      where c.id = conversation_id
        and ((select auth.uid()) = c.user_low
          or (select auth.uid()) = c.user_high)));

-- Server-enforced anti-spam and reciprocal block checks. Do NOT rely on
-- client-side cooldowns. The sender lock makes concurrent sends count.
create function public.check_direct_message_send()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_other uuid;
begin
  if v_me is null or new.sender_id <> v_me then
    raise exception 'Sender authentication failed';
  end if;
  select case when user_low = v_me then user_high else user_low end
    into v_other from public.direct_conversations
    where id = new.conversation_id and (user_low = v_me or user_high = v_me);
  if v_other is null then raise exception 'Conversation unavailable'; end if;
  if exists (
    select 1 from public.direct_user_blocks
      where (blocker_id = v_me and blocked_id = v_other)
         or (blocker_id = v_other and blocked_id = v_me)
  ) then raise exception 'Conversation unavailable'; end if;

  perform pg_advisory_xact_lock(hashtextextended(v_me::text, 183));
  if (select count(*) from public.direct_messages
      where sender_id = v_me and created_at > now() - interval '1 minute') >= 12
     or (select count(*) from public.direct_messages
      where sender_id = v_me and created_at > now() - interval '1 hour') >= 200
  then
    raise exception 'Message rate limit reached';
  end if;
  return new;
end $$;
revoke all on function public.check_direct_message_send() from public, anon, authenticated;
create trigger enforce_direct_message_send
  before insert on public.direct_messages
  for each row execute function public.check_direct_message_send();

create function public.direct_message_read_timestamp()
returns trigger language plpgsql security invoker set search_path = ''
as $$
begin
  if old.read_at is not null and new.read_at is distinct from old.read_at then
    raise exception 'Read receipts cannot be reset';
  end if;
  if new.read_at is null then raise exception 'Read time is required'; end if;
  new.read_at := coalesce(old.read_at, now());
  return new;
end $$;
revoke all on function public.direct_message_read_timestamp() from public, anon, authenticated;
create trigger normalize_direct_message_read_timestamp
  before update on public.direct_messages
  for each row execute function public.direct_message_read_timestamp();

create function public.touch_direct_conversation()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  update public.direct_conversations set updated_at = now()
    where id = new.conversation_id;
  return new;
end $$;
revoke all on function public.touch_direct_conversation() from public, anon, authenticated;
create trigger touch_conversation_after_message
  after insert on public.direct_messages
  for each row execute function public.touch_direct_conversation();

-- User reports are stored privately for later web-only moderation intake.
create table public.direct_user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_user_id uuid not null references public.profiles(id) on delete cascade,
  message_id uuid references public.direct_messages(id) on delete set null,
  reason text not null check (char_length(btrim(reason)) between 5 and 1000),
  created_at timestamptz not null default now(),
  check (reporter_id <> reported_user_id)
);
create index direct_reports_by_reporter on public.direct_user_reports
  (reporter_id, created_at desc);
alter table public.direct_user_reports enable row level security;
revoke all on public.direct_user_reports from anon, authenticated;
grant select on public.direct_user_reports to authenticated;
grant insert (reporter_id, reported_user_id, message_id, reason)
  on public.direct_user_reports to authenticated;
create policy reports_owner_read on public.direct_user_reports
  for select to authenticated using (reporter_id = (select auth.uid()));
create policy reports_owner_create on public.direct_user_reports
  for insert to authenticated with check (reporter_id = (select auth.uid()));

commit;

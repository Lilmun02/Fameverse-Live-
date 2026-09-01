drop policy if exists "authenticated users can read active live rooms or own history" on public.live_rooms;
drop policy if exists "hosts can create own live room" on public.live_rooms;
drop policy if exists "hosts can update own live room" on public.live_rooms;

create policy "authenticated users can read active live rooms or own history"
on public.live_rooms
for select
to authenticated
using (status = 'live' or (select auth.uid()) = host_user_id);

create policy "hosts can create own live room"
on public.live_rooms
for insert
to authenticated
with check (
  (select auth.uid()) = host_user_id
  and status = 'live'
  and ended_at is null
);

create policy "hosts can update own live room"
on public.live_rooms
for update
to authenticated
using ((select auth.uid()) = host_user_id)
with check ((select auth.uid()) = host_user_id);

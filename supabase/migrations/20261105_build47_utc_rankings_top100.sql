-- Build 47 UTC leaderboard correction: isolated ranking read API only.
-- Legacy '24h' and '7d' clients now mean UTC calendar day / Sunday-start week.
-- Preserve existing app meanings: Supporters = legitimate cash-backed gifts; Pulse = eligible Fametaps.
-- Creators = eligible host Fametaps; follower count is secondary. Owner approval is required to change category meanings.
-- No wallet, payout, ledger, gift issuance, or tap issuance mutations.
create or replace function public.get_fameverse_rankings_v2(
  p_kind text,
  p_window text default '24h',
  p_limit integer default 100
)
returns table(
  rank_position integer,
  user_id uuid,
  username text,
  display_name text,
  avatar_url text,
  score bigint,
  secondary bigint
)
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_kind text := lower(trim(coalesce(p_kind, '')));
  v_window text := lower(trim(coalesce(p_window, '24h')));
  v_limit integer := greatest(1, least(coalesce(p_limit, 100), 100));
  v_since timestamptz;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  v_since := case v_window
    when '24h' then date_trunc('day', now() at time zone 'UTC') at time zone 'UTC'
    when 'daily' then date_trunc('day', now() at time zone 'UTC') at time zone 'UTC'
    when '7d' then (date_trunc('week', (now() at time zone 'UTC') + interval '1 day') - interval '1 day') at time zone 'UTC'
    when 'weekly' then (date_trunc('week', (now() at time zone 'UTC') + interval '1 day') - interval '1 day') at time zone 'UTC'
    else null
  end;

  if v_since is null then
    raise exception 'unsupported ranking window';
  end if;

  if v_kind = 'supporters' then
    return query
    with totals as (
      select
        g.sender_user_id as ranked_user_id,
        coalesce(sum(f.cash_backed_coins), 0)::bigint as ranked_score,
        coalesce(sum(g.quantity), 0)::bigint as ranked_secondary
      from public.gift_events g
      join public.gift_funding_breakdowns f on f.gift_event_id = g.id
      where g.created_at >= v_since
        and g.sender_user_id is not null
        and g.recipient_user_id is not null
        and g.sender_user_id <> g.recipient_user_id
        and f.cash_backed_coins > 0
      group by g.sender_user_id
    ), ranked as (
      select
        row_number() over (
          order by t.ranked_score desc, t.ranked_secondary desc, t.ranked_user_id
        )::integer as pos,
        t.*
      from totals t
      where t.ranked_score > 0
    )
    select
      r.pos,
      r.ranked_user_id,
      p.username,
      coalesce(
        nullif(trim(p.display_name), ''),
        nullif(trim(p.username), ''),
        'Fameverse User'
      ),
      p.avatar_url,
      r.ranked_score,
      r.ranked_secondary
    from ranked r
    join public.profiles p on p.id = r.ranked_user_id
    order by r.pos
    limit v_limit;
    return;
  end if;

  if v_kind = 'pulse' then
    return query
    with totals as (
      select
        b.actor_user_id as ranked_user_id,
        coalesce(sum(b.eligible_tap_count), 0)::bigint as ranked_score,
        coalesce(sum(b.raw_tap_count), 0)::bigint as ranked_secondary
      from public.live_tap_batches b
      where b.created_at >= v_since
      group by b.actor_user_id
    ), ranked as (
      select
        row_number() over (
          order by t.ranked_score desc, t.ranked_secondary desc, t.ranked_user_id
        )::integer as pos,
        t.*
      from totals t
      where t.ranked_score > 0
    )
    select
      r.pos,
      r.ranked_user_id,
      p.username,
      coalesce(
        nullif(trim(p.display_name), ''),
        nullif(trim(p.username), ''),
        'Fameverse User'
      ),
      p.avatar_url,
      r.ranked_score,
      r.ranked_secondary
    from ranked r
    join public.profiles p on p.id = r.ranked_user_id
    order by r.pos
    limit v_limit;
    return;
  end if;

  if v_kind = 'creators' then
    return query
    with totals as (
      select
        lr.host_user_id as ranked_user_id,
        coalesce(sum(b.eligible_tap_count), 0)::bigint as ranked_score
      from public.live_rooms lr
      join public.live_tap_batches b on b.room_id = lr.id
      where b.created_at >= v_since
        and lr.host_user_id is not null
      group by lr.host_user_id
    ), followers as (
      select f.following_id as ranked_user_id, count(*)::bigint as follower_count
      from public.follows f
      group by f.following_id
    ), ranked as (
      select row_number() over (
        order by t.ranked_score desc, t.ranked_user_id
      )::integer as pos, t.*
      from totals t
      where t.ranked_score > 0
    )
    select
      r.pos, r.ranked_user_id, p.username,
      coalesce(nullif(trim(p.display_name), ''), nullif(trim(p.username), ''), 'Fameverse Creator'),
      p.avatar_url, r.ranked_score, coalesce(f.follower_count, 0)::bigint
    from ranked r
    join public.profiles p on p.id = r.ranked_user_id
    left join followers f on f.ranked_user_id = r.ranked_user_id
    order by r.pos limit v_limit;
    return;
  end if;

  raise exception 'unsupported ranking kind';
end;
$function$;

revoke all on function public.get_fameverse_rankings_v2(text, text, integer) from public;
grant execute on function public.get_fameverse_rankings_v2(text, text, integer) to authenticated;
grant execute on function public.get_fameverse_rankings_v2(text, text, integer) to service_role;

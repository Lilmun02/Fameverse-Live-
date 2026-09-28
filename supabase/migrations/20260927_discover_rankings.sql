begin;

create or replace function public.get_fameverse_rankings(
  p_kind text,
  p_limit integer default 20
)
returns table (
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
as $$
declare
  v_kind text := lower(trim(coalesce(p_kind, '')));
  v_limit integer := greatest(1, least(coalesce(p_limit, 20), 100));
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  if v_kind = 'tappers' then
    return query
    with totals as (
      select
        b.actor_user_id as ranked_user_id,
        coalesce(sum(b.eligible_tap_count), 0)::bigint as ranked_score,
        coalesce(sum(b.raw_tap_count), 0)::bigint as ranked_secondary
      from public.live_tap_batches b
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
      coalesce(nullif(trim(p.display_name), ''), nullif(trim(p.username), ''), 'Fameverse User'),
      p.avatar_url,
      r.ranked_score,
      r.ranked_secondary
    from ranked r
    join public.profiles p on p.id = r.ranked_user_id
    order by r.pos
    limit v_limit;
    return;
  end if;

  if v_kind = 'gifters' then
    return query
    with ranked as (
      select
        row_number() over (
          order by g.total_coins_sent desc, g.gift_count desc, g.user_id
        )::integer as pos,
        g.user_id as ranked_user_id,
        g.total_coins_sent::bigint as ranked_score,
        g.gift_count::bigint as ranked_secondary
      from public.gifter_stats g
      where g.total_coins_sent > 0
    )
    select
      r.pos,
      r.ranked_user_id,
      p.username,
      coalesce(nullif(trim(p.display_name), ''), nullif(trim(p.username), ''), 'Fameverse User'),
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
    with taps as (
      select
        lr.host_user_id as ranked_user_id,
        coalesce(sum(b.eligible_tap_count), 0)::bigint as ranked_score
      from public.live_rooms lr
      left join public.live_tap_batches b on b.room_id = lr.id
      group by lr.host_user_id
    ), followers as (
      select
        f.following_id as ranked_user_id,
        count(*)::bigint as follower_count
      from public.follows f
      group by f.following_id
    ), combined as (
      select
        p.id as ranked_user_id,
        coalesce(t.ranked_score, 0)::bigint as ranked_score,
        coalesce(f.follower_count, 0)::bigint as ranked_secondary
      from public.profiles p
      left join taps t on t.ranked_user_id = p.id
      left join followers f on f.ranked_user_id = p.id
      where coalesce(t.ranked_score, 0) > 0 or coalesce(f.follower_count, 0) > 0
    ), ranked as (
      select
        row_number() over (
          order by c.ranked_score desc, c.ranked_secondary desc, c.ranked_user_id
        )::integer as pos,
        c.*
      from combined c
    )
    select
      r.pos,
      r.ranked_user_id,
      p.username,
      coalesce(nullif(trim(p.display_name), ''), nullif(trim(p.username), ''), 'Fameverse Creator'),
      p.avatar_url,
      r.ranked_score,
      r.ranked_secondary
    from ranked r
    join public.profiles p on p.id = r.ranked_user_id
    order by r.pos
    limit v_limit;
    return;
  end if;

  raise exception 'unsupported ranking kind';
end;
$$;

revoke all on function public.get_fameverse_rankings(text, integer) from public;
grant execute on function public.get_fameverse_rankings(text, integer) to authenticated;

comment on function public.get_fameverse_rankings(text, integer) is
  'Discover leaderboard RPC. tappers = eligible FameTaps sent; gifters = Fame Coins sent; creators = eligible FameTaps received with followers as tie-breaker.';

commit;

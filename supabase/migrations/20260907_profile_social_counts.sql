create or replace function public.get_profile_social_counts(p_user_id uuid)
returns table (
  follower_count bigint,
  following_count bigint,
  friend_count bigint
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    (
      select count(*)
      from public.follows f
      where f.following_id = p_user_id
    )::bigint as follower_count,
    (
      select count(*)
      from public.follows f
      where f.follower_id = p_user_id
    )::bigint as following_count,
    (
      select count(*)
      from public.follows outgoing
      where outgoing.follower_id = p_user_id
        and exists (
          select 1
          from public.follows incoming
          where incoming.follower_id = outgoing.following_id
            and incoming.following_id = p_user_id
        )
    )::bigint as friend_count;
$$;

revoke all on function public.get_profile_social_counts(uuid) from public;
revoke all on function public.get_profile_social_counts(uuid) from anon;
grant execute on function public.get_profile_social_counts(uuid) to authenticated;

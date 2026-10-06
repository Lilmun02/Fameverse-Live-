begin;

update public.fameverse_gift_catalog
set video_url = 'https://d2ol7oe51mr4n9.cloudfront.net/user_3IL6AXXAqcrsLZJmbjvrquIP0Bd/ee94db8e-08fe-4028-a641-47e8b0dc3b89.mp4',
    cinematic = true,
    cost_coins = 5000,
    active = true,
    updated_at = now()
where id = 'abyssal-leviathan';

commit;

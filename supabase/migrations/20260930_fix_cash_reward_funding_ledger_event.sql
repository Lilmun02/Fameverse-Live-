alter table public.beta_coin_ledger
  drop constraint if exists beta_coin_ledger_event_type_check;

alter table public.beta_coin_ledger
  add constraint beta_coin_ledger_event_type_check
  check (event_type = any (array[
    'seed'::text,
    'refill'::text,
    'gift_send'::text,
    'purchase'::text,
    'refund'::text,
    'cash_reward_funding'::text
  ]));

-- Guest list for the Collingwood Cave Cocktail invite.
-- Run once in the Supabase SQL editor. Then change the passphrase on the last line.

create table if not exists public.rsvps (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  name        text not null check (char_length(name) between 1 and 60),
  dietary     text check (char_length(dietary) <= 300),
  track       text check (char_length(track) <= 120),
  status      text not null default 'yes' check (status in ('yes','waitlist','no'))
);

create table if not exists public.settings (
  id              int primary key default 1 check (id = 1),
  seats           int not null default 99,  -- real cap before the waiting list; the label always claims 13
  base_taken      int not null default 1,   -- yeses you already have outside the site; set to 0 once they are in the table
  organiser_pass  text not null
);
insert into public.settings (id, seats, base_taken, organiser_pass)
values (1, 99, 1, 'change-me') on conflict (id) do nothing;

-- Row level security: the public key may only INSERT an RSVP. Nobody can read, edit or delete through the API.
alter table public.rsvps    enable row level security;
alter table public.settings enable row level security;
drop policy if exists "anyone can rsvp" on public.rsvps;
create policy "anyone can rsvp" on public.rsvps for insert to anon, authenticated with check (true);

-- Once the seats are gone, new RSVPs land on the waiting list automatically.
create or replace function public.rsvp_capacity() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'yes' and (select base_taken + (select count(*) from rsvps where status = 'yes') from settings where id = 1) >= (select seats from settings where id = 1) then
    new.status := 'waitlist';
  end if;
  return new;
end $$;
drop trigger if exists rsvp_capacity on public.rsvps;
create trigger rsvp_capacity before insert on public.rsvps for each row execute function public.rsvp_capacity();

-- Public counter: how many seats are taken. Returns no names.
create or replace function public.seat_count() returns json
language sql security definer set search_path = public as $$
  select json_build_object('seats', s.seats, 'taken', s.base_taken + (select count(*) from rsvps where status = 'yes'))
  from settings s where s.id = 1;
$$;

-- Organiser list: returns rows only when the passphrase matches.
create or replace function public.guest_list(pass text) returns setof public.rsvps
language sql security definer set search_path = public as $$
  select r.* from rsvps r
  where exists (select 1 from settings where id = 1 and organiser_pass = pass)
  order by r.created_at;
$$;

revoke all on function public.seat_count()      from public;
revoke all on function public.guest_list(text)  from public;
grant execute on function public.seat_count()     to anon, authenticated;
grant execute on function public.guest_list(text) to anon, authenticated;

-- Set your passphrase (used at yoursite/#guests):
update public.settings set organiser_pass = 'change-me' where id = 1;

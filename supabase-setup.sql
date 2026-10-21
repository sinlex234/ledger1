-- Crema accounts + cloud sync — run this once in Supabase: SQL Editor → New query → paste → Run.
-- Safe to re-run.

-- 1. Usernames ---------------------------------------------------------------
create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  username   text unique check (username ~ '^[a-z0-9_]{3,20}$'),
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
drop policy if exists "profiles: read own"   on public.profiles;
drop policy if exists "profiles: update own" on public.profiles;
create policy "profiles: read own"   on public.profiles for select using (auth.uid() = id);
create policy "profiles: update own" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

-- Create a profile automatically for every new account (email or Google).
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare u text := lower(nullif(trim(new.raw_user_meta_data->>'username'), ''));
begin
  if u is not null and (u !~ '^[a-z0-9_]{3,20}$' or exists (select 1 from public.profiles where username = u)) then
    u := null;
  end if;
  insert into public.profiles (id, username) values (new.id, u) on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Used by the sign-up form to check a username before creating the account.
create or replace function public.username_available(uname text)
returns boolean language sql stable security definer set search_path = public as $$
  select not exists (select 1 from public.profiles where username = lower(trim(uname)));
$$;

-- Used by "sign in with username": turns a username into the account's email.
create or replace function public.email_for_username(uname text)
returns text language sql stable security definer set search_path = public as $$
  select u.email from auth.users u join public.profiles p on p.id = u.id
  where p.username = lower(trim(uname));
$$;

revoke all on function public.username_available(text) from public;
revoke all on function public.email_for_username(text) from public;
grant execute on function public.username_available(text) to anon, authenticated;
grant execute on function public.email_for_username(text) to anon, authenticated;

-- 2. Journal data (one row per user per section: trades, journal, playbook…) --
create table if not exists public.crema_data (
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  key        text not null,
  value      jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, key)
);
alter table public.crema_data enable row level security;
drop policy if exists "crema_data: own rows" on public.crema_data;
create policy "crema_data: own rows" on public.crema_data
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

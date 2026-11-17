-- Sinau: daftar akun yang sudah dikenal (nama + role) berdasarkan email.
-- Saat akun dengan email ini dibuat (aplikasi atau Dashboard → Add user), profilnya otomatis memakai nama & role di sini.
drop table if exists private.admin_emails;
create table private.known_accounts (
  email text primary key check (email = lower(email)),
  name  text not null,
  role  text not null check (role in ('user','admin'))
);
revoke all on private.known_accounts from public, anon, authenticated;

insert into private.known_accounts (email, name, role) values
  ('abdillahkais1@gmail.com',      'Kais',   'admin'),
  ('zidney.masariellah@gmail.com', 'Zidney', 'admin'),
  ('mubaro22097856@gmail.com',     'Nouval', 'user');

create or replace function private.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_name text; v_year smallint; v_known record;
begin
  select * into v_known from private.known_accounts k where k.email = lower(new.email);
  v_name := coalesce(v_known.name, nullif(trim(new.raw_user_meta_data->>'name'), ''));
  if v_name is null or char_length(v_name) < 3 then v_name := split_part(new.email, '@', 1); end if;
  if char_length(v_name) < 3 then v_name := rpad(v_name, 3, '_'); end if;
  begin v_year := (new.raw_user_meta_data->>'angkatan')::smallint; exception when others then v_year := null; end;
  if v_year is not null and (v_year < 2015 or v_year > 2100) then v_year := null; end if;
  insert into public.profiles (id, name, email, angkatan, role)
  values (new.id, left(v_name, 40), new.email, v_year, coalesce(v_known.role, 'user'));
  return new;
end $$;

-- Akun yang sudah terlanjur ada ikut disesuaikan.
update public.profiles p set name = k.name, role = k.role
from private.known_accounts k where lower(p.email) = k.email and (p.name <> k.name or p.role <> k.role);

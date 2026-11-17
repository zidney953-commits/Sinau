-- Sinau: daftar email admin. Akun dengan email ini otomatis menjadi admin saat dibuat
-- (lewat aplikasi atau Dashboard → Authentication → Add user). Kata sandi diatur sendiri oleh pemilik akun.
create table if not exists private.admin_emails (
  email text primary key check (email = lower(email)),
  name  text not null
);
revoke all on private.admin_emails from public, anon, authenticated;

insert into private.admin_emails (email, name) values
  ('kais@sinau.id',   'Kais'),
  ('farrel@sinau.id', 'Farrel')
on conflict (email) do update set name = excluded.name;

create or replace function private.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_name text; v_year smallint; v_admin record;
begin
  select * into v_admin from private.admin_emails a where a.email = lower(new.email);
  v_name := nullif(trim(new.raw_user_meta_data->>'name'), '');
  if v_name is null then v_name := v_admin.name; end if;
  if v_name is null or char_length(v_name) < 3 then v_name := split_part(new.email, '@', 1); end if;
  if char_length(v_name) < 3 then v_name := rpad(v_name, 3, '_'); end if;
  begin v_year := (new.raw_user_meta_data->>'angkatan')::smallint; exception when others then v_year := null; end;
  if v_year is not null and (v_year < 2015 or v_year > 2100) then v_year := null; end if;
  insert into public.profiles (id, name, email, angkatan, role)
  values (new.id, left(v_name, 40), new.email, v_year, case when v_admin.email is not null then 'admin' else 'user' end);
  return new;
end $$;

-- Proteksi role/aktif/email hanya berlaku untuk permintaan dari aplikasi (role authenticated/anon),
-- bukan untuk SQL Editor/migrasi, supaya pemilik project tetap bisa mengatur admin.
create or replace function private.protect_profile()
returns trigger language plpgsql security invoker set search_path = '' as $$
begin
  if current_user in ('authenticated', 'anon') and not private.is_admin() then
    new.role := old.role; new.active := old.active; new.email := old.email;
  end if;
  return new;
end $$;

-- Jika akunnya sudah ada lebih dulu, langsung jadikan admin.
update public.profiles p set role = 'admin'
from private.admin_emails a where lower(p.email) = a.email and p.role <> 'admin';

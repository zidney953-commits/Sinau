-- Sinau: angkatan diisi otomatis dengan tahun saat mendaftar (zona waktu WIB), tidak lagi diisi pengguna.
create or replace function private.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_name text; v_known record;
begin
  select * into v_known from private.known_accounts k where k.email = lower(new.email);
  v_name := coalesce(v_known.name, nullif(trim(new.raw_user_meta_data->>'name'), ''));
  if v_name is null or char_length(v_name) < 3 then v_name := split_part(new.email, '@', 1); end if;
  if char_length(v_name) < 3 then v_name := rpad(v_name, 3, '_'); end if;
  insert into public.profiles (id, name, email, angkatan, role)
  values (new.id, left(v_name, 40), new.email,
          extract(year from coalesce(new.created_at, now()) at time zone 'Asia/Jakarta')::smallint,
          coalesce(v_known.role, 'user'));
  return new;
end $$;

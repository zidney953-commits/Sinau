-- Sinau: kolom "Display name" di Authentication → Users diambil dari raw_user_meta_data->>'name'.
-- Samakan dengan nama di public.profiles, sekarang dan setiap kali nama berubah.

create or replace function private.sync_display_name()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  update auth.users
     set raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object('name', new.name)
   where id = new.id
     and coalesce(raw_user_meta_data->>'name', '') is distinct from new.name;
  return new;
end $$;

drop trigger if exists profiles_sync_display_name on public.profiles;
create trigger profiles_sync_display_name
  after insert or update of name on public.profiles
  for each row execute function private.sync_display_name();

-- Isi untuk akun yang sudah ada (mis. yang dibuat lewat Dashboard → Add user).
update auth.users u
   set raw_user_meta_data = coalesce(u.raw_user_meta_data, '{}'::jsonb) || jsonb_build_object('name', p.name)
  from public.profiles p
 where p.id = u.id
   and coalesce(u.raw_user_meta_data->>'name', '') is distinct from p.name;

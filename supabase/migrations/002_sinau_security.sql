-- Sinau: keamanan (RLS), trigger, leaderboard, dan storage avatars

-- ============ Helper (schema private, tidak terekspos ke REST API) ============
create schema if not exists private;
grant usage on schema private to authenticated;

create or replace function private.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles p
                 where p.id = (select auth.uid()) and p.role = 'admin' and p.active);
$$;
revoke all on function private.is_admin() from public, anon;
grant execute on function private.is_admin() to authenticated;

-- Profil dibuat otomatis saat akun mendaftar. role selalu 'user' (tidak bisa diisi dari aplikasi).
create or replace function private.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_name text; v_year smallint;
begin
  v_name := nullif(trim(new.raw_user_meta_data->>'name'), '');
  if v_name is null or char_length(v_name) < 3 then v_name := split_part(new.email, '@', 1); end if;
  if char_length(v_name) < 3 then v_name := rpad(v_name, 3, '_'); end if;
  begin v_year := (new.raw_user_meta_data->>'angkatan')::smallint; exception when others then v_year := null; end;
  if v_year is not null and (v_year < 2015 or v_year > 2100) then v_year := null; end if;
  insert into public.profiles (id, name, email, angkatan) values (new.id, left(v_name, 40), new.email, v_year);
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function private.handle_new_user();

create or replace function private.sync_user_email()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  update public.profiles set email = new.email where id = new.id;
  return new;
end $$;
create trigger on_auth_user_email_changed after update of email on auth.users
  for each row when (old.email is distinct from new.email) execute function private.sync_user_email();

-- Pengguna biasa tidak bisa mengubah role, status aktif, atau email-nya sendiri lewat tabel profiles.
create or replace function private.protect_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if not private.is_admin() then
    new.role := old.role; new.active := old.active; new.email := old.email;
  end if;
  return new;
end $$;
create trigger profiles_protect before update on public.profiles
  for each row execute function private.protect_profile();

-- XP dihitung server dari lessons.xp, bukan dikirim aplikasi.
create or replace function private.set_progress_xp()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  new.xp_earned := case when new.passed then coalesce((select l.xp from public.lessons l where l.id = new.lesson_id), 0) else 0 end;
  if new.passed and new.completed_at is null then new.completed_at := now(); end if;
  new.updated_at := now();
  return new;
end $$;
create trigger lesson_progress_xp before insert or update on public.lesson_progress
  for each row execute function private.set_progress_xp();

create or replace function private.touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at := now(); return new; end $$;
create trigger lessons_touch before update on public.lessons
  for each row execute function private.touch_updated_at();

-- ============ RLS ============
alter table public.profiles        enable row level security;
alter table public.languages       enable row level security;
alter table public.units           enable row level security;
alter table public.lessons         enable row level security;
alter table public.questions       enable row level security;
alter table public.lesson_progress enable row level security;
alter table public.reminders       enable row level security;
alter table public.submissions     enable row level security;
alter table public.posts           enable row level security;
alter table public.post_reads      enable row level security;
alter table public.feedback        enable row level security;

-- profiles: semua yang login bisa melihat (untuk peringkat); ubah milik sendiri, admin ubah semua.
create policy "profiles: baca" on public.profiles for select to authenticated using (true);
create policy "profiles: ubah" on public.profiles for update to authenticated
  using (id = (select auth.uid()) or (select private.is_admin()))
  with check (id = (select auth.uid()) or (select private.is_admin()));
create policy "profiles: hapus (admin)" on public.profiles for delete to authenticated using ((select private.is_admin()));

-- languages & units: dibaca semua yang login, dikelola admin.
create policy "languages: baca" on public.languages for select to authenticated using (true);
create policy "languages: tambah (admin)" on public.languages for insert to authenticated with check ((select private.is_admin()));
create policy "languages: ubah (admin)" on public.languages for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "languages: hapus (admin)" on public.languages for delete to authenticated using ((select private.is_admin()));

create policy "units: baca" on public.units for select to authenticated using (true);
create policy "units: tambah (admin)" on public.units for insert to authenticated with check ((select private.is_admin()));
create policy "units: ubah (admin)" on public.units for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "units: hapus (admin)" on public.units for delete to authenticated using ((select private.is_admin()));

-- lessons & questions: pengguna hanya melihat yang terbit; admin melihat semua termasuk draf.
create policy "lessons: baca" on public.lessons for select to authenticated using (published or (select private.is_admin()));
create policy "lessons: tambah (admin)" on public.lessons for insert to authenticated with check ((select private.is_admin()));
create policy "lessons: ubah (admin)" on public.lessons for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "lessons: hapus (admin)" on public.lessons for delete to authenticated using ((select private.is_admin()));

create policy "questions: baca" on public.questions for select to authenticated using (
  (select private.is_admin()) or exists (select 1 from public.lessons l where l.id = lesson_id and l.published));
create policy "questions: tambah (admin)" on public.questions for insert to authenticated with check ((select private.is_admin()));
create policy "questions: ubah (admin)" on public.questions for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "questions: hapus (admin)" on public.questions for delete to authenticated using ((select private.is_admin()));

-- lesson_progress: dibaca semua yang login (peringkat & dasbor), ditulis hanya oleh pemiliknya.
create policy "progress: baca" on public.lesson_progress for select to authenticated using (true);
create policy "progress: tambah" on public.lesson_progress for insert to authenticated with check (user_id = (select auth.uid()));
create policy "progress: ubah" on public.lesson_progress for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- reminders & posts: dibaca semua yang login, dikelola admin.
create policy "reminders: baca" on public.reminders for select to authenticated using (true);
create policy "reminders: tambah (admin)" on public.reminders for insert to authenticated with check ((select private.is_admin()));
create policy "reminders: ubah (admin)" on public.reminders for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "reminders: hapus (admin)" on public.reminders for delete to authenticated using ((select private.is_admin()));

create policy "posts: baca" on public.posts for select to authenticated using (true);
create policy "posts: tambah (admin)" on public.posts for insert to authenticated with check ((select private.is_admin()));
create policy "posts: ubah (admin)" on public.posts for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "posts: hapus (admin)" on public.posts for delete to authenticated using ((select private.is_admin()));

-- post_reads: tanda "sudah dibaca" milik sendiri.
create policy "post_reads: baca" on public.post_reads for select to authenticated using (user_id = (select auth.uid()));
create policy "post_reads: tambah" on public.post_reads for insert to authenticated with check (user_id = (select auth.uid()));
create policy "post_reads: hapus" on public.post_reads for delete to authenticated using (user_id = (select auth.uid()));

-- submissions: kirim milik sendiri (ontime / pending); admin menerima atau menolak.
create policy "submissions: baca" on public.submissions for select to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));
create policy "submissions: kirim" on public.submissions for insert to authenticated
  with check (user_id = (select auth.uid()) and status in ('ontime','pending') and decided_at is null and decided_by is null);
create policy "submissions: putuskan (admin)" on public.submissions for update to authenticated
  using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "submissions: hapus (admin)" on public.submissions for delete to authenticated using ((select private.is_admin()));

-- feedback: kirim & lihat milik sendiri; admin melihat semua dan mengubah status.
create policy "feedback: baca" on public.feedback for select to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));
create policy "feedback: kirim" on public.feedback for insert to authenticated
  with check (user_id = (select auth.uid()) and status = 'baru');
create policy "feedback: ubah status (admin)" on public.feedback for update to authenticated
  using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "feedback: hapus (admin)" on public.feedback for delete to authenticated using ((select private.is_admin()));

-- ============ Peringkat (mengikuti RLS pemanggil) ============
create view public.leaderboard with (security_invoker = true) as
  select p.id as user_id, p.name, p.angkatan, p.avatar_url, p.streak, u.language_id,
         coalesce(sum(lp.xp_earned), 0)::int as xp,
         count(*) filter (where lp.passed)::int as lessons_done
  from public.profiles p
  join public.lesson_progress lp on lp.user_id = p.id
  join public.lessons l on l.id = lp.lesson_id
  join public.units u on u.id = l.unit_id
  where p.role = 'user' and p.active
  group by p.id, u.language_id;
grant select on public.leaderboard to authenticated;
revoke select on public.leaderboard from anon;

-- ============ Storage: foto profil ============
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

-- File disimpan di avatars/<user_id>/... ; hanya pemilik (bukan admin) yang bisa mengunggah/mengganti/menghapus.
create policy "avatars: lihat milik sendiri" on storage.objects for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatars: unggah" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text and not (select private.is_admin()));
create policy "avatars: ganti" on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text and not (select private.is_admin()))
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatars: hapus" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- Sinau: Yusuf (user) terdaftar di daftar akun yang dikenal.
insert into private.known_accounts (email, name, role) values ('zidney953@gmail.com', 'Yusuf', 'user')
on conflict (email) do update set name = excluded.name, role = excluded.role;

-- Jika akunnya sudah terlanjur dibuat, sesuaikan nama & angkatannya.
update public.profiles set name = 'Yusuf', angkatan = 2026 where lower(email) = 'zidney953@gmail.com';

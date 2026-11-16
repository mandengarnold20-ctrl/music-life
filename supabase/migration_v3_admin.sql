-- Music Life — v3 : stockage des musiques et clips pour la page d'administration
-- Dossier public « media » (MP3, MP4) : lecture pour tous, envoi réservé aux administrateurs.

insert into storage.buckets (id, name, public)
values ('media', 'media', true)
on conflict (id) do update set public = true;

drop policy if exists "media lecture publique" on storage.objects;
create policy "media lecture publique" on storage.objects
  for select to anon, authenticated using (bucket_id = 'media');

drop policy if exists "media admin écrit" on storage.objects;
create policy "media admin écrit" on storage.objects
  for all to authenticated
  using (bucket_id = 'media' and public.is_admin())
  with check (bucket_id = 'media' and public.is_admin());

select id, public from storage.buckets where id in ('images', 'media');

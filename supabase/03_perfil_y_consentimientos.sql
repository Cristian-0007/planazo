-- ============================================================
-- Planazo: perfil, consentimientos y ciudades con coordenadas
-- (RF-PU-01, RF-PU-03 y RF-PU-04).
-- Ejecutar UNA sola vez en el SQL Editor, después de 01 y 02.
-- Es seguro repetirlo: usa "if not exists" y "create or replace".
-- ============================================================

-- Datos nuevos del perfil
alter table public.perfiles
  add column if not exists telefono text
    check (telefono is null or telefono ~ '^\+?[0-9]{7,15}$'),
  add column if not exists notificaciones_activas boolean not null default true,
  add column if not exists personalizacion_activa boolean not null default true;

-- La app solo puede cambiar estas columnas (acepta_terminos y acepto_en
-- siguen siendo de solo lectura para el cliente).
grant update (telefono, notificaciones_activas, personalizacion_activa)
  on public.perfiles to authenticated;

-- Coordenadas de cada ciudad, para sugerir la más cercana con el GPS
alter table public.ciudades
  add column if not exists latitud  numeric(9,6),
  add column if not exists longitud numeric(9,6);

update public.ciudades
   set latitud = 4.711000, longitud = -74.072100
 where nombre = 'Bogotá' and latitud is null;

-- El aviso de cancelación o sin cupos ahora respeta la preferencia
-- "notificaciones_activas" de cada persona.
create or replace function public.notificar_cambio_estado()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.estado_manual is distinct from old.estado_manual
     and new.estado_manual is not null then
    insert into public.notificaciones (perfil_id, evento_id, tipo, mensaje)
    select
      f.perfil_id,
      new.id,
      case new.estado_manual when 'cancelado' then 'cancelacion' else 'sin_cupos' end,
      case new.estado_manual
        when 'cancelado' then 'El organizador canceló "' || new.nombre || '".'
        else 'Se agotaron los cupos de "' || new.nombre || '".'
      end
    from public.favoritos f
    join public.perfiles p on p.id = f.perfil_id
    where f.evento_id = new.id
      and p.notificaciones_activas
    on conflict (perfil_id, evento_id, tipo) do nothing;
  end if;
  return new;
end;
$$;

revoke execute on function public.notificar_cambio_estado() from public, anon, authenticated;

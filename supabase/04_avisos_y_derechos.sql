-- ============================================================
-- Planazo: bandeja de avisos con "inicio próximo" y solicitudes de
-- derechos del titular de los datos (RF-EU-07 y RF-CGD-01).
-- Ejecutar UNA sola vez en el SQL Editor, después de 01, 02 y 03.
-- Es seguro repetirlo: usa "if not exists", "drop ... if exists" y
-- "create or replace".
-- ============================================================

-- ------------------------------------------------------------
-- 1. Nuevo tipo de aviso: el evento guardado empieza pronto
-- ------------------------------------------------------------
alter table public.notificaciones
  drop constraint if exists notificaciones_tipo_check;

alter table public.notificaciones
  add constraint notificaciones_tipo_check
  check (tipo in ('cancelacion', 'sin_cupos', 'inicio_proximo'));

-- La app llama a esta función al abrirse. Crea un aviso por cada favorito
-- del usuario que empieza en las próximas 24 horas, si la persona tiene los
-- avisos activados. El índice único (perfil, evento, tipo) evita duplicados,
-- así que se puede llamar todas las veces que haga falta.
-- Devuelve cuántos avisos nuevos creó.
create or replace function public.sincronizar_avisos_inicio()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_perfil uuid := (select auth.uid());
  v_nuevos integer := 0;
begin
  if v_perfil is null then
    return 0;
  end if;

  insert into public.notificaciones (perfil_id, evento_id, tipo, mensaje)
  select
    f.perfil_id,
    e.id,
    'inicio_proximo',
    'Empieza pronto: "' || e.nombre || '" ('
      || to_char(e.inicia_en at time zone 'America/Bogota', 'DD/MM "a las" HH24:MI')
      || ').'
  from public.favoritos f
  join public.eventos e on e.id = f.evento_id
  join public.perfiles p on p.id = f.perfil_id
  where f.perfil_id = v_perfil
    and p.notificaciones_activas
    and e.estado_manual is distinct from 'cancelado'
    and e.inicia_en > now()
    and e.inicia_en <= now() + interval '24 hours'
  on conflict (perfil_id, evento_id, tipo) do nothing;

  get diagnostics v_nuevos = row_count;
  return v_nuevos;
end;
$$;

revoke execute on function public.sincronizar_avisos_inicio() from public, anon;
grant  execute on function public.sincronizar_avisos_inicio() to authenticated;

-- ------------------------------------------------------------
-- 2. Solicitudes de derechos del titular (Ley 1581 de 2012)
--    Consulta: 10 días hábiles. Reclamos (actualizar, corregir o
--    suprimir): 15 días hábiles. No se descuentan festivos.
-- ------------------------------------------------------------
create or replace function public.sumar_dias_habiles(desde timestamptz, dias integer)
returns timestamptz
language plpgsql
stable
set search_path = ''
as $$
declare
  f timestamptz := desde;
  n integer := 0;
begin
  while n < dias loop
    f := f + interval '1 day';
    if extract(isodow from (f at time zone 'America/Bogota')) < 6 then
      n := n + 1;
    end if;
  end loop;
  return f;
end;
$$;

create table if not exists public.solicitudes_datos (
  id                  uuid primary key default gen_random_uuid(),
  perfil_id           uuid not null references public.perfiles (id) on delete cascade,
  tipo                text not null
                      check (tipo in ('acceso', 'actualizacion', 'correccion', 'eliminacion')),
  detalle             text not null
                      check (char_length(btrim(detalle)) between 10 and 1000),
  estado              text not null default 'recibida'
                      check (estado in ('recibida', 'en_proceso', 'resuelta', 'rechazada')),
  respuesta           text,
  creada_en           timestamptz not null default now(),
  responder_antes_de  timestamptz,
  resuelta_en         timestamptz
);

create index if not exists solicitudes_datos_perfil_idx
  on public.solicitudes_datos (perfil_id, creada_en desc);

-- Pone la fecha límite de respuesta y evita que una persona acumule
-- solicitudes abiertas (máximo 5 a la vez).
create or replace function public.preparar_solicitud_datos()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_abiertas integer;
begin
  select count(*) into v_abiertas
  from public.solicitudes_datos s
  where s.perfil_id = new.perfil_id
    and s.estado in ('recibida', 'en_proceso');

  if v_abiertas >= 5 then
    raise exception 'Ya tienes 5 solicitudes abiertas. Espera a que se resuelvan.'
      using errcode = 'P0001';
  end if;

  new.responder_antes_de := public.sumar_dias_habiles(
    now(),
    case new.tipo when 'acceso' then 10 else 15 end
  );
  return new;
end;
$$;

drop trigger if exists solicitudes_datos_preparar on public.solicitudes_datos;
create trigger solicitudes_datos_preparar
  before insert on public.solicitudes_datos
  for each row execute function public.preparar_solicitud_datos();

alter table public.solicitudes_datos enable row level security;

drop policy if exists solicitudes_datos_select on public.solicitudes_datos;
create policy solicitudes_datos_select on public.solicitudes_datos
  for select to authenticated using (perfil_id = (select auth.uid()));

drop policy if exists solicitudes_datos_insert on public.solicitudes_datos;
create policy solicitudes_datos_insert on public.solicitudes_datos
  for insert to authenticated with check (perfil_id = (select auth.uid()));

-- La app solo puede leer y crear. Responder o cambiar el estado lo hace el
-- equipo desde el panel de Supabase (con el rol de servicio).
revoke all on public.solicitudes_datos from anon, authenticated;
grant select on public.solicitudes_datos to authenticated;
grant insert (perfil_id, tipo, detalle) on public.solicitudes_datos to authenticated;

revoke execute on function public.preparar_solicitud_datos() from public, anon, authenticated;

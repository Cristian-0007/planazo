-- ============================================================
-- Planazo: esquema simplificado para actividad de aula (Bogotá)
-- Supabase / PostgreSQL. Ejecutar completo en el SQL Editor, una sola vez.
-- ============================================================

-- ------------------------------------------------------------
-- Utilidad: fecha de actualización automática
-- ------------------------------------------------------------
create or replace function public.set_actualizado_en()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.actualizado_en = now();
  return new;
end;
$$;

-- ------------------------------------------------------------
-- Catálogos
-- ------------------------------------------------------------
create table public.ciudades (
  id      uuid primary key default gen_random_uuid(),
  nombre  text not null unique,
  activa  boolean not null default true
);

create table public.categorias (
  id      smallint generated always as identity primary key,
  slug    text not null unique,
  nombre  text not null unique
);

insert into public.ciudades (nombre) values ('Bogotá');

insert into public.categorias (slug, nombre) values
  ('musica',           'Música'),
  ('cine',             'Cine'),
  ('gastronomia',      'Gastronomía'),
  ('deportes',         'Deportes'),
  ('arte',             'Arte'),
  ('cultura',          'Cultura'),
  ('entretenimiento',  'Entretenimiento'),
  ('actividad-fisica', 'Actividad física');

-- ------------------------------------------------------------
-- Perfil (el correo y la contraseña viven en auth.users)
-- ------------------------------------------------------------
create table public.perfiles (
  id                   uuid primary key references auth.users (id) on delete cascade,
  nombre               text not null,
  ciudad_id            uuid references public.ciudades (id),
  acepta_terminos      boolean not null default false,
  acepto_en            timestamptz,
  onboarding_completo  boolean not null default false,
  creado_en            timestamptz not null default now(),
  actualizado_en       timestamptz not null default now()
);

create trigger perfiles_actualizado_en
  before update on public.perfiles
  for each row execute function public.set_actualizado_en();

create table public.perfil_categorias (
  perfil_id     uuid not null references public.perfiles (id) on delete cascade,
  categoria_id  smallint not null references public.categorias (id),
  primary key (perfil_id, categoria_id)
);

-- Crea el perfil al registrarse. Si el registro envía los metadatos
-- nombre y acepta_terminos = 'true', los guarda.
create or replace function public.crear_perfil_al_registrarse()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  acepto boolean := coalesce((new.raw_user_meta_data ->> 'acepta_terminos') = 'true', false);
begin
  insert into public.perfiles (id, nombre, acepta_terminos, acepto_en)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'nombre', ''),
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      split_part(new.email, '@', 1)
    ),
    acepto,
    case when acepto then now() end
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.crear_perfil_al_registrarse();

-- ------------------------------------------------------------
-- Lugares y eventos
-- ------------------------------------------------------------
create table public.lugares (
  id         uuid primary key default gen_random_uuid(),
  nombre     text not null,
  direccion  text,
  localidad  text,
  ciudad_id  uuid not null references public.ciudades (id),
  latitud    numeric(9,6),
  longitud   numeric(9,6)
);

create table public.eventos (
  id              uuid primary key default gen_random_uuid(),
  nombre          text not null,
  descripcion     text,
  imagen_url      text,
  categoria_id    smallint not null references public.categorias (id),
  lugar_id        uuid not null references public.lugares (id),
  inicia_en       timestamptz not null,
  termina_en      timestamptz,
  precio          numeric(12,0) check (precio >= 0),   -- 0 = gratis, null = no informado
  edad_minima     smallint check (edad_minima >= 0),
  estado_manual   text check (estado_manual in ('cancelado', 'sin_cupos')),
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now(),
  check (termina_en is null or termina_en >= inicia_en)
);

create index eventos_inicia_idx    on public.eventos (inicia_en);
create index eventos_categoria_idx on public.eventos (categoria_id);

create trigger eventos_actualizado_en
  before update on public.eventos
  for each row execute function public.set_actualizado_en();

-- Estado vigente: solo "cancelado" y "sin_cupos" se guardan; el resto
-- se calcula por fechas. Sin hora de fin se asumen 4 horas.
create view public.eventos_con_estado
with (security_invoker = true) as
select
  e.*,
  case
    when e.estado_manual = 'cancelado'                                    then 'cancelado'
    when now() > coalesce(e.termina_en, e.inicia_en + interval '4 hours') then 'finalizado'
    when e.estado_manual = 'sin_cupos'                                    then 'sin_cupos'
    when now() >= e.inicia_en                                             then 'en_curso'
    else 'proximo'
  end as estado
from public.eventos e;

-- ------------------------------------------------------------
-- Favoritos y notificaciones dentro de la app
-- ------------------------------------------------------------
create table public.favoritos (
  perfil_id    uuid not null references public.perfiles (id) on delete cascade,
  evento_id    uuid not null references public.eventos (id) on delete cascade,
  guardado_en  timestamptz not null default now(),
  primary key (perfil_id, evento_id)
);

create table public.notificaciones (
  id         uuid primary key default gen_random_uuid(),
  perfil_id  uuid not null references public.perfiles (id) on delete cascade,
  evento_id  uuid not null references public.eventos (id) on delete cascade,
  tipo       text not null check (tipo in ('cancelacion', 'sin_cupos')),
  mensaje    text not null,
  creada_en  timestamptz not null default now(),
  leida      boolean not null default false,
  unique (perfil_id, evento_id, tipo)
);

create index notificaciones_perfil_idx on public.notificaciones (perfil_id, creada_en desc);

-- Cuando un evento pasa a cancelado o sin cupos, avisa a quienes lo guardaron.
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
    where f.evento_id = new.id
    on conflict (perfil_id, evento_id, tipo) do nothing;
  end if;
  return new;
end;
$$;

create trigger eventos_notificar_estado
  after update of estado_manual on public.eventos
  for each row execute function public.notificar_cambio_estado();

-- ============================================================
-- Seguridad a nivel de fila (RLS)
-- ============================================================
alter table public.ciudades           enable row level security;
alter table public.categorias         enable row level security;
alter table public.perfiles           enable row level security;
alter table public.perfil_categorias  enable row level security;
alter table public.lugares            enable row level security;
alter table public.eventos            enable row level security;
alter table public.favoritos          enable row level security;
alter table public.notificaciones     enable row level security;

-- Catálogo: lectura para cuentas autenticadas
create policy ciudades_lectura   on public.ciudades   for select to authenticated using (activa);
create policy categorias_lectura on public.categorias for select to authenticated using (true);
create policy lugares_lectura    on public.lugares    for select to authenticated using (true);
create policy eventos_lectura    on public.eventos    for select to authenticated using (true);

-- Perfil: cada persona ve y edita solo el suyo, y solo ciertas columnas
create policy perfiles_select on public.perfiles
  for select to authenticated using (id = (select auth.uid()));
create policy perfiles_update on public.perfiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

revoke update on public.perfiles from authenticated, anon;
grant update (nombre, ciudad_id, onboarding_completo) on public.perfiles to authenticated;

create policy perfil_categorias_all on public.perfil_categorias
  for all to authenticated
  using (perfil_id = (select auth.uid()))
  with check (perfil_id = (select auth.uid()));

create policy favoritos_select on public.favoritos
  for select to authenticated using (perfil_id = (select auth.uid()));
create policy favoritos_insert on public.favoritos
  for insert to authenticated with check (perfil_id = (select auth.uid()));
create policy favoritos_delete on public.favoritos
  for delete to authenticated using (perfil_id = (select auth.uid()));

create policy notificaciones_select on public.notificaciones
  for select to authenticated using (perfil_id = (select auth.uid()));
create policy notificaciones_update on public.notificaciones
  for update to authenticated
  using (perfil_id = (select auth.uid()))
  with check (perfil_id = (select auth.uid()));

revoke update on public.notificaciones from authenticated, anon;
grant update (leida) on public.notificaciones to authenticated;

-- Las vistas heredan los permisos de quien consulta
revoke all on public.eventos_con_estado from anon;
grant select on public.eventos_con_estado to authenticated;

-- ============================================================
-- Índices adicionales y endurecimiento (recomendados por los
-- avisos de seguridad y rendimiento de Supabase)
-- ============================================================
create index if not exists eventos_lugar_idx             on public.eventos (lugar_id);
create index if not exists lugares_ciudad_idx            on public.lugares (ciudad_id);
create index if not exists favoritos_evento_idx          on public.favoritos (evento_id);
create index if not exists notificaciones_evento_idx     on public.notificaciones (evento_id);
create index if not exists perfil_categorias_categoria_idx on public.perfil_categorias (categoria_id);
create index if not exists perfiles_ciudad_idx           on public.perfiles (ciudad_id);

-- Las funciones de los triggers no deben poder llamarse desde la API pública.
revoke execute on function public.crear_perfil_al_registrarse() from public, anon, authenticated;
revoke execute on function public.notificar_cambio_estado()     from public, anon, authenticated;

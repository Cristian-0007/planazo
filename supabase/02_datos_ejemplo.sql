-- ============================================================
-- Planazo: datos de ejemplo (Bogotá)
-- Ejecutar UNA sola vez, después de 01_esquema.sql.
-- Los eventos son inventados y sus fechas son relativas a hoy,
-- así que siempre hay próximos, uno en curso y algunos finalizados.
-- ============================================================

insert into public.lugares (nombre, direccion, localidad, ciudad_id, latitud, longitud)
select v.nombre, v.direccion, v.localidad, c.id, v.lat, v.lng
from public.ciudades c
cross join (values
  ('Parque Simón Bolívar',        'Calle 63 con carrera 68',       'Teusaquillo', 4.658500, -74.093900),
  ('Cinemateca de Bogotá',        'Carrera 3 # 19-10',             'Santa Fe',    4.604700, -74.068300),
  ('Estadio El Campín',           'Carrera 30 con calle 57',       'Teusaquillo', 4.645900, -74.077500),
  ('Parque de la 93',             'Calle 93A con carrera 13',      'Chapinero',   4.676400, -74.048500),
  ('Plaza de Bolívar',            'Carrera 7 con calle 11',        'La Candelaria', 4.598100, -74.076000),
  ('Parque de Usaquén',           'Carrera 6A con calle 119B',     'Usaquén',     4.695700, -74.030600),
  ('Museo del Oro',               'Carrera 6 # 15-88',             'Santa Fe',    4.601700, -74.072000),
  ('Corferias',                   'Carrera 37 # 24-67',            'Teusaquillo', 4.628800, -74.095000),
  ('Biblioteca Virgilio Barco',   'Avenida Calle 63 # 59A-06',     'Teusaquillo', 4.656400, -74.084100),
  ('Parque Nacional',             'Carrera 7 con calle 36',        'Santa Fe',    4.624000, -74.065000),
  ('Plaza del Chorro de Quevedo', 'Carrera 2 con calle 13',        'La Candelaria', 4.596000, -74.069000),
  ('Parque El Virrey',            'Carrera 15 con calle 88',       'Chapinero',   4.670000, -74.054500)
) as v(nombre, direccion, localidad, lat, lng)
where c.nombre = 'Bogotá';

with b as (
  select (date_trunc('day', now() at time zone 'America/Bogota') at time zone 'America/Bogota') as d
)
insert into public.eventos
  (nombre, descripcion, categoria_id, lugar_id, inicia_en, termina_en, precio, edad_minima, estado_manual)
select
  v.nombre, v.descripcion, cat.id, l.id,
  b.d + v.dia * interval '1 day' + v.hora::float8 * interval '1 hour',
  b.d + v.dia * interval '1 day' + (v.hora + v.dur)::float8 * interval '1 hour',
  v.precio, v.edad, v.estado::text
from b
cross join (values
  ('Noche de salsa en vivo', 'Tres agrupaciones recorren la salsa dura de los años setenta, con pausa de descarga entre sets.', 'musica', 'Parque de la 93', 1, 20, 5, 45000, 18, null),
  ('Jazz al aire libre', 'Tarde de jazz con cuartetos locales en el parque. Lleva tu manta o tu silla.', 'musica', 'Parque El Virrey', 2, 16, 3, 0, null, null),
  ('Salsa al parque', 'Festival abierto con orquestas invitadas y zona de baile.', 'musica', 'Parque Simón Bolívar', -5, 14, 6, 0, null, null),
  ('Ciclo de cine japonés clásico', 'Proyección en pantalla grande de una obra clásica, con charla corta antes de la función.', 'cine', 'Cinemateca de Bogotá', 1, 19, 2.5, 18000, 12, null),
  ('Muestra de cortometrajes colombianos', 'Selección de seis cortos de realizadores jóvenes y conversatorio con los directores.', 'cine', 'Cinemateca de Bogotá', 4, 18.5, 2, 12000, null, null),
  ('Estreno de documental sobre los cerros', 'Función única del documental y foro con el equipo de producción.', 'cine', 'Cinemateca de Bogotá', -3, 19, 2, 10000, null, null),
  ('Ruta de tamales por La Candelaria', 'Recorrido a pie con cuatro paradas para probar tamales de distintas regiones.', 'gastronomia', 'Plaza del Chorro de Quevedo', 2, 10, 3, 30000, null, null),
  ('Feria del café de origen', 'Catas guiadas, tostadores invitados y venta directa de productores.', 'gastronomia', 'Corferias', 9, 10, 8, 22000, null, null),
  ('Festival de arepas de huevo', 'Concurso y degustación de arepas de huevo con cocineros de la costa.', 'gastronomia', 'Plaza de Bolívar', 8, 11, 6, 30000, null, 'cancelado'),
  ('Clásico capitalino', 'Partido de liga entre los dos equipos de la ciudad.', 'deportes', 'Estadio El Campín', 3, 16, 2, 60000, null, 'sin_cupos'),
  ('Torneo de microfútbol comunitario', 'Torneo por equipos de barrio, inscripciones abiertas en el lugar.', 'deportes', 'Parque Nacional', 5, 8, 7, 0, null, null),
  ('Visita guiada: orfebrería precolombina', 'Recorrido de una hora y media por las salas principales con guía especializado.', 'arte', 'Museo del Oro', 2, 14, 1.5, 5000, null, null),
  ('Taller de grabado en linóleo', 'Taller práctico para principiantes, materiales incluidos. Cupos limitados.', 'arte', 'Biblioteca Virgilio Barco', 6, 15, 3, 20000, null, null),
  ('Mercado de las Pulgas', 'Antigüedades, ropa de segunda mano, artesanías y comida callejera.', 'cultura', 'Parque de Usaquén', 3, 10, 7, 0, null, null),
  ('Recorrido patrimonial nocturno', 'Caminata guiada por el centro histórico con historias de la ciudad.', 'cultura', 'Plaza de Bolívar', 1, 19, 2, 15000, null, null),
  ('Noche de juegos de mesa', 'Mesas abiertas de juegos de estrategia y cartas, con monitores que enseñan las reglas.', 'entretenimiento', 'Biblioteca Virgilio Barco', 4, 17, 4, 0, null, null),
  ('Rodada nocturna', 'Rodada guiada de 20 km con casco y luces obligatorios.', 'actividad-fisica', 'Parque Simón Bolívar', 5, 19, 2, 0, 14, null),
  ('Yoga al amanecer', 'Clase abierta para todos los niveles. Trae tu tapete.', 'actividad-fisica', 'Parque Nacional', 2, 6.5, 1.5, 0, null, null)
) as v(nombre, descripcion, slug, lugar, dia, hora, dur, precio, edad, estado)
join public.categorias cat on cat.slug = v.slug
join public.lugares l on l.nombre = v.lugar;

-- Un evento que está ocurriendo ahora mismo (estado "en curso")
insert into public.eventos
  (nombre, descripcion, categoria_id, lugar_id, inicia_en, termina_en, precio)
select
  'Feria del libro independiente',
  'Editoriales independientes, lanzamientos y firmas de autores durante todo el día.',
  cat.id, l.id, now() - interval '1 hour', now() + interval '4 hours', 0
from public.categorias cat, public.lugares l
where cat.slug = 'cultura' and l.nombre = 'Biblioteca Virgilio Barco';

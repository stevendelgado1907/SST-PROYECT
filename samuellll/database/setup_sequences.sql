-- Secuencias requeridas por fn_insertar_epp
-- Ejecutar en PostgreSQL si la API reporta error de secuencias

CREATE SEQUENCE IF NOT EXISTS seq_epp;
CREATE SEQUENCE IF NOT EXISTS seq_inventario;

-- Sincronizar con IDs existentes (evitar duplicados)
SELECT setval('seq_epp', GREATEST(COALESCE((SELECT MAX(id_epp) FROM tab_epp), 0) + 1, 1));
SELECT setval('seq_inventario', GREATEST(COALESCE((SELECT MAX(id_inventario) FROM inventario_epp), 0) + 1, 1));

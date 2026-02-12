-- CRUD para tab_ips
-- Archivo: database/functions/tab_ips/crud_tab_ips.sql

-- Función para Insertar IPS
CREATE OR REPLACE FUNCTION fn_tab_ips_insert(
    p_id_ips INTEGER,
    p_nom_ips VARCHAR(100),
    p_direccion_ips VARCHAR(200),
    p_tel_ips VARCHAR(15),
    p_correo_ips VARCHAR(100) DEFAULT NULL
)
RETURNS TABLE (id_ips INTEGER, nom_ips VARCHAR) AS $$
BEGIN
    -- Validaciones de Nulidad
    IF p_id_ips IS NULL THEN RAISE EXCEPTION 'El ID de la IPS es obligatorio'; END IF;
    IF p_nom_ips IS NULL OR TRIM(p_nom_ips) = '' THEN RAISE EXCEPTION 'El nombre de la IPS es obligatorio'; END IF;
    IF p_direccion_ips IS NULL OR TRIM(p_direccion_ips) = '' THEN RAISE EXCEPTION 'La dirección de la IPS es obligatoria'; END IF;
    IF p_tel_ips IS NULL OR TRIM(p_tel_ips) = '' THEN RAISE EXCEPTION 'El teléfono de la IPS es obligatorio'; END IF;

    -- Inserción
    RETURN QUERY
    INSERT INTO tab_ips (id_ips, nom_ips, direccion_ips, tel_ips, correo_ips)
    VALUES (p_id_ips, TRIM(p_nom_ips), TRIM(p_direccion_ips), TRIM(p_tel_ips), LOWER(TRIM(p_correo_ips)))
    RETURNING tab_ips.id_ips, tab_ips.nom_ips;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe una IPS con ese ID o Nombre.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar IPS: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Actualizar IPS
CREATE OR REPLACE FUNCTION fn_tab_ips_update(
    p_id_ips INTEGER,
    p_nom_ips VARCHAR(100),
    p_direccion_ips VARCHAR(200),
    p_tel_ips VARCHAR(15),
    p_correo_ips VARCHAR(100)
)
RETURNS TABLE (id_ips INTEGER, nom_ips VARCHAR) AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_ips WHERE tab_ips.id_ips = p_id_ips) THEN
        RAISE EXCEPTION 'La IPS con ID % no existe', p_id_ips;
    END IF;

    -- Actualización
    RETURN QUERY
    UPDATE tab_ips
    SET nom_ips = TRIM(p_nom_ips),
        direccion_ips = TRIM(p_direccion_ips),
        tel_ips = TRIM(p_tel_ips),
        correo_ips = LOWER(TRIM(p_correo_ips))
    WHERE tab_ips.id_ips = p_id_ips
    RETURNING tab_ips.id_ips, tab_ips.nom_ips;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe otra IPS con ese nombre.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar IPS: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar IPS
CREATE OR REPLACE FUNCTION fn_tab_ips_delete(
    p_id_ips INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_ips WHERE id_ips = p_id_ips) THEN
        RAISE EXCEPTION 'La IPS con ID % no existe', p_id_ips;
    END IF;

    -- Dependencias
    IF EXISTS (SELECT 1 FROM tab_trabajadores_arl_ips WHERE id_ips = p_id_ips) THEN
        RAISE EXCEPTION 'No se puede eliminar la IPS porque tiene trabajadores afiliados asociados';
    END IF;

    DELETE FROM tab_ips WHERE id_ips = p_id_ips;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

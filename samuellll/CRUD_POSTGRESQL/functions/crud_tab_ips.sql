-- CRUD para tab_ips
-- Archivo: CRUD_POSTGRESQL/functions/crud_tab_ips.sql

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
    -- Validaciones
    IF p_id_ips IS NULL THEN RAISE EXCEPTION 'El ID de la IPS es obligatorio'; END IF;
    IF p_nom_ips IS NULL OR TRIM(p_nom_ips) = '' THEN RAISE EXCEPTION 'El nombre de la IPS es obligatorio'; END IF;

    IF p_correo_ips IS NOT NULL AND TRIM(p_correo_ips) != '' AND p_correo_ips !~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
        RAISE EXCEPTION 'El formato del correo es inválido';
    END IF;

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
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM tab_ips WHERE id_ips = p_id_ips) THEN
        RAISE EXCEPTION 'La IPS con ID % no existe', p_id_ips;
    END IF;

    IF p_correo_ips IS NOT NULL AND TRIM(p_correo_ips) != '' AND p_correo_ips !~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
        RAISE EXCEPTION 'El formato del correo es inválido';
    END IF;

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
CREATE OR REPLACE FUNCTION fn_tab_ips_delete(p_id_ips INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_ips WHERE id_ips = p_id_ips) THEN
        RAISE EXCEPTION 'La IPS con ID % no existe', p_id_ips;
    END IF;

    DELETE FROM tab_ips WHERE id_ips = p_id_ips;
    RETURN TRUE;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'No se puede eliminar la IPS porque tiene trabajadores afiliados asociados';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar IPS: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Listar IPS
CREATE OR REPLACE FUNCTION fn_tab_ips_select(p_id_ips INTEGER DEFAULT NULL)
RETURNS TABLE (
    id_ips INTEGER,
    nom_ips VARCHAR(100),
    direccion_ips VARCHAR(200),
    tel_ips VARCHAR(15),
    correo_ips VARCHAR(100)
) AS $$
BEGIN
    IF p_id_ips IS NULL THEN
        RETURN QUERY 
        SELECT i.id_ips, i.nom_ips, i.direccion_ips, i.tel_ips, i.correo_ips 
        FROM tab_ips i;
    ELSE
        RETURN QUERY 
        SELECT i.id_ips, i.nom_ips, i.direccion_ips, i.tel_ips, i.correo_ips 
        FROM tab_ips i 
        WHERE i.id_ips = p_id_ips;
    END IF;
END;
$$ LANGUAGE plpgsql;

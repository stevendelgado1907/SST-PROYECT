-- CRUD para tab_eps
-- Archivo: CRUD_POSTGRESQL/functions/crud_tab_eps.sql

-- Función para Insertar EPS
CREATE OR REPLACE FUNCTION fn_tab_eps_insert(
    p_id_eps INTEGER,
    p_nom_eps VARCHAR(100),
    p_direccion_eps VARCHAR(200),
    p_tel_eps VARCHAR(15),
    p_correo_eps VARCHAR(100) DEFAULT NULL
)
RETURNS TABLE (id_eps INTEGER, nom_eps VARCHAR) AS $$
BEGIN
    -- Validaciones de Nulidad
    IF p_id_eps IS NULL THEN RAISE EXCEPTION 'El ID de la EPS es obligatorio'; END IF;
    IF p_nom_eps IS NULL OR TRIM(p_nom_eps) = '' THEN RAISE EXCEPTION 'El nombre de la EPS es obligatorio'; END IF;

    -- Validaciones de Formato y Longitud
    IF p_correo_eps IS NOT NULL AND TRIM(p_correo_eps) != '' AND p_correo_eps !~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
        RAISE EXCEPTION 'El formato del correo es inválido';
    END IF;

    RETURN QUERY
    INSERT INTO tab_eps (id_eps, nom_eps, direccion_eps, tel_eps, correo_eps)
    VALUES (p_id_eps, TRIM(p_nom_eps), TRIM(p_direccion_eps), TRIM(p_tel_eps), LOWER(TRIM(p_correo_eps)))
    RETURNING tab_eps.id_eps, tab_eps.nom_eps;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe una EPS con ese ID o Nombre.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar EPS: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Actualizar EPS
CREATE OR REPLACE FUNCTION fn_tab_eps_update(
    p_id_eps INTEGER,
    p_nom_eps VARCHAR(100),
    p_direccion_eps VARCHAR(200),
    p_tel_eps VARCHAR(15),
    p_correo_eps VARCHAR(100)
)
RETURNS TABLE (id_eps INTEGER, nom_eps VARCHAR) AS $$
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM tab_eps WHERE id_eps = p_id_eps) THEN
        RAISE EXCEPTION 'La EPS con ID % no existe', p_id_eps;
    END IF;

    IF p_correo_eps IS NOT NULL AND TRIM(p_correo_eps) != '' AND p_correo_eps !~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
        RAISE EXCEPTION 'El formato del correo es inválido';
    END IF;

    RETURN QUERY
    UPDATE tab_eps
    SET nom_eps = TRIM(p_nom_eps),
        direccion_eps = TRIM(p_direccion_eps),
        tel_eps = TRIM(p_tel_eps),
        correo_eps = LOWER(TRIM(p_correo_eps))
    WHERE tab_eps.id_eps = p_id_eps
    RETURNING tab_eps.id_eps, tab_eps.nom_eps;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe otra EPS con ese nombre.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar EPS: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar EPS
CREATE OR REPLACE FUNCTION fn_tab_eps_delete(p_id_eps INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_eps WHERE id_eps = p_id_eps) THEN
        RAISE EXCEPTION 'La EPS con ID % no existe', p_id_eps;
    END IF;

    DELETE FROM tab_eps WHERE id_eps = p_id_eps;
    RETURN TRUE;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'No se puede eliminar la EPS porque tiene trabajadores afiliados asociados';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar EPS: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Listar EPS
CREATE OR REPLACE FUNCTION fn_tab_eps_select(p_id_eps INTEGER DEFAULT NULL)
RETURNS TABLE (
    id_eps INTEGER,
    nom_eps VARCHAR(100),
    direccion_eps VARCHAR(200),
    tel_eps VARCHAR(15),
    correo_eps VARCHAR(100)
) AS $$
BEGIN
    IF p_id_eps IS NULL THEN
        RETURN QUERY 
        SELECT e.id_eps, e.nom_eps, e.direccion_eps, e.tel_eps, e.correo_eps 
        FROM tab_eps e;
    ELSE
        RETURN QUERY 
        SELECT e.id_eps, e.nom_eps, e.direccion_eps, e.tel_eps, e.correo_eps 
        FROM tab_eps e 
        WHERE e.id_eps = p_id_eps;
    END IF;
END;
$$ LANGUAGE plpgsql;

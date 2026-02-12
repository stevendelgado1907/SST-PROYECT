-- CRUD para tab_eps
-- Archivo: database/functions/tab_eps/crud_tab_eps.sql

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
    IF p_direccion_eps IS NULL OR TRIM(p_direccion_eps) = '' THEN RAISE EXCEPTION 'La dirección de la EPS es obligatoria'; END IF;
    IF p_tel_eps IS NULL OR TRIM(p_tel_eps) = '' THEN RAISE EXCEPTION 'El teléfono de la EPS es obligatorio'; END IF;

    -- Validaciones de Longitud
    IF LENGTH(p_nom_eps) > 100 THEN RAISE EXCEPTION 'El nombre excede los 100 caracteres'; END IF;
    IF LENGTH(p_direccion_eps) > 200 THEN RAISE EXCEPTION 'La dirección excede los 200 caracteres'; END IF;
    IF LENGTH(p_tel_eps) > 15 THEN RAISE EXCEPTION 'El teléfono excede los 15 caracteres'; END IF;
    
    -- Inserción
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
    IF NOT EXISTS (SELECT 1 FROM tab_eps WHERE tab_eps.id_eps = p_id_eps) THEN
        RAISE EXCEPTION 'La EPS con ID % no existe', p_id_eps;
    END IF;

    -- Actualización
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
CREATE OR REPLACE FUNCTION fn_tab_eps_delete(
    p_id_eps INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_eps WHERE id_eps = p_id_eps) THEN
        RAISE EXCEPTION 'La EPS con ID % no existe', p_id_eps;
    END IF;

    -- Dependencias
    IF EXISTS (SELECT 1 FROM tab_trabajadores_arl_eps WHERE id_eps = p_id_eps) THEN
        RAISE EXCEPTION 'No se puede eliminar la EPS porque tiene trabajadores afiliados asociados';
    END IF;

    DELETE FROM tab_eps WHERE id_eps = p_id_eps;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

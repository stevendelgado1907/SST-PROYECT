-- CRUD para tab_supervisores
-- Archivo: CRUD_POSTGRESQL/functions/crud_tab_supervisores.sql

-- Función para Insertar Supervisor
CREATE OR REPLACE FUNCTION fn_tab_supervisores_insert(
    p_id_supervisor INTEGER,
    p_nom_supervisor VARCHAR(100),
    p_ape_supervisor VARCHAR(100),
    p_correo_supervisor VARCHAR(100),
    p_tel_supervisor VARCHAR(15),
    p_fecha_ingreso_supervisor DATE,
    p_certificacion_supervisor VARCHAR(100)
)
RETURNS TABLE (id_supervisor INTEGER, nom_supervisor VARCHAR) AS $$
BEGIN
    -- Validaciones
    IF p_id_supervisor IS NULL THEN RAISE EXCEPTION 'El ID del supervisor es obligatorio'; END IF;
    IF p_nom_supervisor IS NULL OR TRIM(p_nom_supervisor) = '' THEN RAISE EXCEPTION 'El nombre es obligatorio'; END IF;

    IF p_correo_supervisor IS NOT NULL AND TRIM(p_correo_supervisor) != '' AND p_correo_supervisor !~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
        RAISE EXCEPTION 'El formato del correo es inválido';
    END IF;

    RETURN QUERY
    INSERT INTO tab_supervisores (id_supervisor, nom_supervisor, ape_supervisor, correo_supervisor, tel_supervisor, fecha_ingreso_supervisor, certificacion_supervisor)
    VALUES (p_id_supervisor, TRIM(p_nom_supervisor), TRIM(p_ape_supervisor), LOWER(TRIM(p_correo_supervisor)), TRIM(p_tel_supervisor), p_fecha_ingreso_supervisor, TRIM(p_certificacion_supervisor))
    RETURNING tab_supervisores.id_supervisor, tab_supervisores.nom_supervisor;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe un supervisor con ese ID o Correo.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar supervisor: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Actualizar Supervisor
CREATE OR REPLACE FUNCTION fn_tab_supervisores_update(
    p_id_supervisor INTEGER,
    p_nom_supervisor VARCHAR(100),
    p_ape_supervisor VARCHAR(100),
    p_correo_supervisor VARCHAR(100),
    p_tel_supervisor VARCHAR(15),
    p_fecha_retiro_supervisor DATE,
    p_certificacion_supervisor VARCHAR(100)
)
RETURNS TABLE (id_supervisor INTEGER, nom_supervisor VARCHAR) AS $$
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM tab_supervisores WHERE id_supervisor = p_id_supervisor) THEN
        RAISE EXCEPTION 'El supervisor con ID % no existe', p_id_supervisor;
    END IF;

    IF p_correo_supervisor IS NOT NULL AND TRIM(p_correo_supervisor) != '' AND p_correo_supervisor !~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
        RAISE EXCEPTION 'El formato del correo es inválido';
    END IF;

    RETURN QUERY
    UPDATE tab_supervisores
    SET nom_supervisor = TRIM(p_nom_supervisor),
        ape_supervisor = TRIM(p_ape_supervisor),
        correo_supervisor = LOWER(TRIM(p_correo_supervisor)),
        tel_supervisor = TRIM(p_tel_supervisor),
        fecha_retiro_supervisor = p_fecha_retiro_supervisor,
        certificacion_supervisor = TRIM(p_certificacion_supervisor)
    WHERE tab_supervisores.id_supervisor = p_id_supervisor
    RETURNING tab_supervisores.id_supervisor, tab_supervisores.nom_supervisor;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe otro supervisor con ese correo.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar supervisor: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar Supervisor
CREATE OR REPLACE FUNCTION fn_tab_supervisores_delete(p_id_supervisor INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_supervisores WHERE id_supervisor = p_id_supervisor) THEN
        RAISE EXCEPTION 'El supervisor con ID % no existe', p_id_supervisor;
    END IF;

    DELETE FROM tab_supervisores WHERE id_supervisor = p_id_supervisor;
    RETURN TRUE;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'No se puede eliminar el supervisor porque tiene registros asociados';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar supervisor: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Listar Supervisores
CREATE OR REPLACE FUNCTION fn_tab_supervisores_select(p_id_supervisor INTEGER DEFAULT NULL)
RETURNS TABLE (
    id_supervisor INTEGER,
    nom_supervisor VARCHAR(100),
    ape_supervisor VARCHAR(100),
    correo_supervisor VARCHAR(100),
    tel_supervisor VARCHAR(15),
    fecha_ingreso_supervisor DATE,
    fecha_retiro_supervisor DATE,
    certificacion_supervisor VARCHAR(100)
) AS $$
BEGIN
    IF p_id_supervisor IS NULL THEN
        RETURN QUERY 
        SELECT s.id_supervisor, s.nom_supervisor, s.ape_supervisor, s.correo_supervisor, s.tel_supervisor, s.fecha_ingreso_supervisor, s.fecha_retiro_supervisor, s.certificacion_supervisor 
        FROM tab_supervisores s;
    ELSE
        RETURN QUERY 
        SELECT s.id_supervisor, s.nom_supervisor, s.ape_supervisor, s.correo_supervisor, s.tel_supervisor, s.fecha_ingreso_supervisor, s.fecha_retiro_supervisor, s.certificacion_supervisor 
        FROM tab_supervisores s 
        WHERE s.id_supervisor = p_id_supervisor;
    END IF;
END;
$$ LANGUAGE plpgsql;

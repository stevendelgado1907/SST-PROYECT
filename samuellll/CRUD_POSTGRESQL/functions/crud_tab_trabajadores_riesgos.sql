-- CRUD para tab_trabajadores_riesgos
-- Archivo: CRUD_POSTGRESQL/functions/crud_tab_trabajadores_riesgos.sql

-- Función para Insertar Riesgo a Trabajador
CREATE OR REPLACE FUNCTION fn_tab_trab_riesgos_insert(
    p_id_trabajador_riesgo INTEGER,
    p_id_trabajador VARCHAR(20),
    p_id_riesgo INTEGER,
    p_fecha_asignacion DATE,
    p_observaciones TEXT DEFAULT NULL
)
RETURNS TABLE (id_rel INTEGER) AS $$
BEGIN
    -- Validaciones
    IF p_id_trabajador_riesgo IS NULL THEN RAISE EXCEPTION 'El ID de la relación es obligatorio'; END IF;
    IF p_id_trabajador IS NULL THEN RAISE EXCEPTION 'El documento del trabajador es obligatorio'; END IF;
    IF p_id_riesgo IS NULL THEN RAISE EXCEPTION 'El ID del riesgo es obligatorio'; END IF;

    -- Verificación de dependencias
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores WHERE id_trabajador = p_id_trabajador) THEN RAISE EXCEPTION 'El trabajador no existe'; END IF;
    IF NOT EXISTS (SELECT 1 FROM tab_riesgos WHERE id_riesgo = p_id_riesgo) THEN RAISE EXCEPTION 'El riesgo no existe'; END IF;

    RETURN QUERY
    INSERT INTO tab_trabajadores_riesgos (id_trabajador_riesgo, id_trabajador, id_riesgo, fecha_asignacion, observaciones)
    VALUES (p_id_trabajador_riesgo, p_id_trabajador, p_id_riesgo, p_fecha_asignacion, TRIM(p_observaciones))
    RETURNING tab_trabajadores_riesgos.id_trabajador_riesgo;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe esta asignación de riesgo para el trabajador.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al asignar riesgo: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Actualizar Riesgo a Trabajador (Retiro)
CREATE OR REPLACE FUNCTION fn_tab_trab_riesgos_update(
    p_id_trabajador_riesgo INTEGER,
    p_fecha_retiro DATE,
    p_observaciones TEXT
)
RETURNS TABLE (id_rel INTEGER) AS $$
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores_riesgos WHERE id_trabajador_riesgo = p_id_trabajador_riesgo) THEN
        RAISE EXCEPTION 'La relación con ID % no existe', p_id_trabajador_riesgo;
    END IF;

    RETURN QUERY
    UPDATE tab_trabajadores_riesgos
    SET fecha_retiro = p_fecha_retiro,
        observaciones = TRIM(p_observaciones)
    WHERE id_trabajador_riesgo = p_id_trabajador_riesgo
    RETURNING tab_trabajadores_riesgos.id_trabajador_riesgo;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar asignación de riesgo: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar Relación
CREATE OR REPLACE FUNCTION fn_tab_trab_riesgos_delete(p_id INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores_riesgos WHERE id_trabajador_riesgo = p_id) THEN
        RAISE EXCEPTION 'La relación con ID % no existe', p_id;
    END IF;

    DELETE FROM tab_trabajadores_riesgos WHERE id_trabajador_riesgo = p_id;
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar relación de riesgo: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Listar Riesgos por Trabajador
CREATE OR REPLACE FUNCTION fn_tab_trab_riesgos_select(p_id_trabajador VARCHAR(20) DEFAULT NULL)
RETURNS TABLE (
    id_trabajador_riesgo INTEGER,
    id_trabajador VARCHAR(20),
    nom_trabajador VARCHAR(100),
    ape_trabajador VARCHAR(100),
    id_riesgo INTEGER,
    nom_riesgo VARCHAR(100),
    fecha_asignacion DATE,
    fecha_retiro DATE,
    observaciones TEXT
) AS $$
BEGIN
    IF p_id_trabajador IS NULL THEN
        RETURN QUERY 
        SELECT r.id_trabajador_riesgo, r.id_trabajador, t.nom_trabajador, t.ape_trabajador, r.id_riesgo, ri.nom_riesgo, r.fecha_asignacion, r.fecha_retiro, r.observaciones 
        FROM tab_trabajadores_riesgos r
        JOIN tab_trabajadores t ON r.id_trabajador = t.id_trabajador
        JOIN tab_riesgos ri ON r.id_riesgo = ri.id_riesgo;
    ELSE
        RETURN QUERY 
        SELECT r.id_trabajador_riesgo, r.id_trabajador, t.nom_trabajador, t.ape_trabajador, r.id_riesgo, ri.nom_riesgo, r.fecha_asignacion, r.fecha_retiro, r.observaciones 
        FROM tab_trabajadores_riesgos r 
        JOIN tab_trabajadores t ON r.id_trabajador = t.id_trabajador
        JOIN tab_riesgos ri ON r.id_riesgo = ri.id_riesgo
        WHERE r.id_trabajador = p_id_trabajador;
    END IF;
END;
$$ LANGUAGE plpgsql;

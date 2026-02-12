-- CRUD para tab_trabajadores_epp
-- Archivo: CRUD_POSTGRESQL/functions/crud_tab_trabajadores_epp.sql

-- Función para Asignar EPP a Trabajador
CREATE OR REPLACE FUNCTION fn_tab_trab_epp_insert(
    p_id_trabajador_epp INTEGER,
    p_id_trabajador VARCHAR(20),
    p_id_epp INTEGER,
    p_fecha_asignacion DATE,
    p_observaciones TEXT DEFAULT NULL
)
RETURNS TABLE (id_rel INTEGER) AS $$
BEGIN
    -- Validaciones
    IF p_id_trabajador_epp IS NULL THEN RAISE EXCEPTION 'El ID de la asignación es obligatorio'; END IF;
    IF p_id_trabajador IS NULL THEN RAISE EXCEPTION 'El documento del trabajador es obligatorio'; END IF;
    IF p_id_epp IS NULL THEN RAISE EXCEPTION 'El ID del EPP es obligatorio'; END IF;

    -- Verificación de dependencias y Stock
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores WHERE id_trabajador = p_id_trabajador) THEN RAISE EXCEPTION 'El trabajador no existe'; END IF;
    IF NOT EXISTS (SELECT 1 FROM tab_epp WHERE id_epp = p_id_epp) THEN RAISE EXCEPTION 'El EPP no existe'; END IF;
    
    -- Validar stock si es una asignación nueva
    IF (SELECT stock_actual FROM inventario_epp WHERE id_epp = p_id_epp) <= 0 THEN
        RAISE EXCEPTION 'No hay stock disponible para este EPP';
    END IF;

    RETURN QUERY
    INSERT INTO tab_trabajadores_epp (id_trabajador_epp, id_trabajador, id_epp, fecha_asignacion, observaciones)
    VALUES (p_id_trabajador_epp, p_id_trabajador, p_id_epp, p_fecha_asignacion, TRIM(p_observaciones))
    RETURNING tab_trabajadores_epp.id_trabajador_epp;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe esta asignación de EPP para el trabajador.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al asignar EPP: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Devolución/Cambio de Estado de EPP
CREATE OR REPLACE FUNCTION fn_tab_trab_epp_update(
    p_id_trabajador_epp INTEGER,
    p_fecha_devolucion DATE,
    p_estado_epp VARCHAR(50),
    p_observaciones TEXT
)
RETURNS TABLE (id_rel INTEGER) AS $$
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores_epp WHERE id_trabajador_epp = p_id_trabajador_epp) THEN
        RAISE EXCEPTION 'La asignación con ID % no existe', p_id_trabajador_epp;
    END IF;

    RETURN QUERY
    UPDATE tab_trabajadores_epp
    SET fecha_devolucion = p_fecha_devolucion,
        estado_epp = TRIM(p_estado_epp),
        observaciones = TRIM(p_observaciones)
    WHERE id_trabajador_epp = p_id_trabajador_epp
    RETURNING tab_trabajadores_epp.id_trabajador_epp;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar asignación de EPP: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar Registro de Asignación
CREATE OR REPLACE FUNCTION fn_tab_trab_epp_delete(p_id INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores_epp WHERE id_trabajador_epp = p_id) THEN
        RAISE EXCEPTION 'La asignación con ID % no existe', p_id;
    END IF;

    DELETE FROM tab_trabajadores_epp WHERE id_trabajador_epp = p_id;
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar asignación de EPP: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Listar EPP por Trabajador
CREATE OR REPLACE FUNCTION fn_tab_trab_epp_select(p_id_trabajador VARCHAR DEFAULT NULL)
RETURNS TABLE (
    id_trabajador_epp INTEGER,
    id_trabajador VARCHAR,
    id_epp INTEGER,
    fecha_asignacion DATE,
    fecha_devolucion DATE,
    fecha_retiro DATE,
    estado_epp VARCHAR,
    observaciones TEXT
) AS $$
BEGIN
    IF p_id_trabajador IS NULL THEN
        RETURN QUERY 
        SELECT r.id_trabajador_epp, r.id_trabajador, r.id_epp, r.fecha_asignacion, r.fecha_devolucion, r.fecha_retiro, r.estado_epp, r.observaciones 
        FROM tab_trabajadores_epp r;
    ELSE
        RETURN QUERY 
        SELECT r.id_trabajador_epp, r.id_trabajador, r.id_epp, r.fecha_asignacion, r.fecha_devolucion, r.fecha_retiro, r.estado_epp, r.observaciones 
        FROM tab_trabajadores_epp r 
        WHERE r.id_trabajador = p_id_trabajador;
    END IF;
END;
$$ LANGUAGE plpgsql;

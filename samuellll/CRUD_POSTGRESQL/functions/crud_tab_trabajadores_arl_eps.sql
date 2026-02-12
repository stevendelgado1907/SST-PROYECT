-- CRUD para tab_trabajadores_arl_eps
-- Archivo: CRUD_POSTGRESQL/functions/crud_tab_trabajadores_arl_eps.sql

-- Función para Insertar Afiliación ARL-EPS
CREATE OR REPLACE FUNCTION fn_tab_trab_arl_eps_insert(
    p_id_trabajador_arl_eps INTEGER,
    p_id_trabajador VARCHAR(20),
    p_id_arl INTEGER,
    p_id_eps INTEGER,
    p_fecha_afiliacion DATE
)
RETURNS TABLE (id_rel INTEGER) AS $$
BEGIN
    -- Validaciones
    IF p_id_trabajador_arl_eps IS NULL THEN RAISE EXCEPTION 'El ID de la relación es obligatorio'; END IF;
    IF p_id_trabajador IS NULL THEN RAISE EXCEPTION 'El documento del trabajador es obligatorio'; END IF;
    IF p_id_arl IS NULL THEN RAISE EXCEPTION 'El ID de la ARL es obligatorio'; END IF;
    IF p_id_eps IS NULL THEN RAISE EXCEPTION 'El ID de la EPS es obligatorio'; END IF;

    -- Verificación de dependencias
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores WHERE id_trabajador = p_id_trabajador) THEN RAISE EXCEPTION 'El trabajador no existe'; END IF;
    IF NOT EXISTS (SELECT 1 FROM tab_arl WHERE id_arl = p_id_arl) THEN RAISE EXCEPTION 'La ARL no existe'; END IF;
    IF NOT EXISTS (SELECT 1 FROM tab_eps WHERE id_eps = p_id_eps) THEN RAISE EXCEPTION 'La EPS no existe'; END IF;

    RETURN QUERY
    INSERT INTO tab_trabajadores_arl_eps (id_trabajador_arl_eps, id_trabajador, id_arl, id_eps, fecha_afiliacion)
    VALUES (p_id_trabajador_arl_eps, p_id_trabajador, p_id_arl, p_id_eps, p_fecha_afiliacion)
    RETURNING tab_trabajadores_arl_eps.id_trabajador_arl_eps;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe esta afiliación para el trabajador.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar afiliación ARL-EPS: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Actualizar Afiliación (Retiro)
CREATE OR REPLACE FUNCTION fn_tab_trab_arl_eps_update(
    p_id_trabajador_arl_eps INTEGER,
    p_fecha_retiro DATE
)
RETURNS TABLE (id_rel INTEGER) AS $$
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores_arl_eps WHERE id_trabajador_arl_eps = p_id_trabajador_arl_eps) THEN
        RAISE EXCEPTION 'La afiliación con ID % no existe', p_id_trabajador_arl_eps;
    END IF;

    RETURN QUERY
    UPDATE tab_trabajadores_arl_eps
    SET fecha_retiro = p_fecha_retiro
    WHERE id_trabajador_arl_eps = p_id_trabajador_arl_eps
    RETURNING tab_trabajadores_arl_eps.id_trabajador_arl_eps;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar afiliación ARL-EPS: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar Afiliación
CREATE OR REPLACE FUNCTION fn_tab_trab_arl_eps_delete(p_id INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores_arl_eps WHERE id_trabajador_arl_eps = p_id) THEN
        RAISE EXCEPTION 'La afiliación con ID % no existe', p_id;
    END IF;

    DELETE FROM tab_trabajadores_arl_eps WHERE id_trabajador_arl_eps = p_id;
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar afiliación ARL-EPS: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Listar Afiliaciones
CREATE OR REPLACE FUNCTION fn_tab_trab_arl_eps_select(p_id INTEGER DEFAULT NULL)
RETURNS TABLE (
    id_trabajador_arl_eps INTEGER,
    id_trabajador VARCHAR(20),
    nom_trabajador VARCHAR(100),
    ape_trabajador VARCHAR(100),
    id_arl INTEGER,
    nom_arl VARCHAR(100),
    id_eps INTEGER,
    nom_eps VARCHAR(100),
    fecha_afiliacion DATE,
    fecha_retiro DATE
) AS $$
BEGIN
    IF p_id IS NULL THEN
        RETURN QUERY 
        SELECT r.id_trabajador_arl_eps, r.id_trabajador, t.nom_trabajador, t.ape_trabajador, r.id_arl, a.nom_arl, r.id_eps, e.nom_eps, r.fecha_afiliacion, r.fecha_retiro 
        FROM tab_trabajadores_arl_eps r
        JOIN tab_trabajadores t ON r.id_trabajador = t.id_trabajador
        JOIN tab_arl a ON r.id_arl = a.id_arl
        JOIN tab_eps e ON r.id_eps = e.id_eps;
    ELSE
        RETURN QUERY 
        SELECT r.id_trabajador_arl_eps, r.id_trabajador, t.nom_trabajador, t.ape_trabajador, r.id_arl, a.nom_arl, r.id_eps, e.nom_eps, r.fecha_afiliacion, r.fecha_retiro 
        FROM tab_trabajadores_arl_eps r 
        JOIN tab_trabajadores t ON r.id_trabajador = t.id_trabajador
        JOIN tab_arl a ON r.id_arl = a.id_arl
        JOIN tab_eps e ON r.id_eps = e.id_eps
        WHERE r.id_trabajador_arl_eps = p_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

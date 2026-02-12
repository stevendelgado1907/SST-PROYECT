-- CRUD para tab_trabajadores_arl_ips
-- Archivo: CRUD_POSTGRESQL/functions/crud_tab_trabajadores_arl_ips.sql

-- Función para Insertar Afiliación ARL-IPS
CREATE OR REPLACE FUNCTION fn_tab_trab_arl_ips_insert(
    p_id_trabajador_arl_ips INTEGER,
    p_id_trabajador VARCHAR(20),
    p_id_arl INTEGER,
    p_id_ips INTEGER,
    p_fecha_afiliacion DATE
)
RETURNS TABLE (id_rel INTEGER) AS $$
BEGIN
    -- Validaciones
    IF p_id_trabajador_arl_ips IS NULL THEN RAISE EXCEPTION 'El ID de la relación es obligatorio'; END IF;
    IF p_id_trabajador IS NULL THEN RAISE EXCEPTION 'El documento del trabajador es obligatorio'; END IF;
    IF p_id_arl IS NULL THEN RAISE EXCEPTION 'El ID de la ARL es obligatorio'; END IF;
    IF p_id_ips IS NULL THEN RAISE EXCEPTION 'El ID de la IPS es obligatorio'; END IF;

    -- Verificación de dependencias
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores WHERE id_trabajador = p_id_trabajador) THEN RAISE EXCEPTION 'El trabajador no existe'; END IF;
    IF NOT EXISTS (SELECT 1 FROM tab_arl WHERE id_arl = p_id_arl) THEN RAISE EXCEPTION 'La ARL no existe'; END IF;
    IF NOT EXISTS (SELECT 1 FROM tab_ips WHERE id_ips = p_id_ips) THEN RAISE EXCEPTION 'La IPS no existe'; END IF;

    RETURN QUERY
    INSERT INTO tab_trabajadores_arl_ips (id_trabajador_arl_ips, id_trabajador, id_arl, id_ips, fecha_afiliacion)
    VALUES (p_id_trabajador_arl_ips, p_id_trabajador, p_id_arl, p_id_ips, p_fecha_afiliacion)
    RETURNING tab_trabajadores_arl_ips.id_trabajador_arl_ips;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe esta afiliación para el trabajador.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar afiliación ARL-IPS: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Actualizar Afiliación (Retiro)
CREATE OR REPLACE FUNCTION fn_tab_trab_arl_ips_update(
    p_id_trabajador_arl_ips INTEGER,
    p_fecha_retiro DATE
)
RETURNS TABLE (id_rel INTEGER) AS $$
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores_arl_ips WHERE id_trabajador_arl_ips = p_id_trabajador_arl_ips) THEN
        RAISE EXCEPTION 'La afiliación con ID % no existe', p_id_trabajador_arl_ips;
    END IF;

    RETURN QUERY
    UPDATE tab_trabajadores_arl_ips
    SET fecha_retiro = p_fecha_retiro
    WHERE id_trabajador_arl_ips = p_id_trabajador_arl_ips
    RETURNING tab_trabajadores_arl_ips.id_trabajador_arl_ips;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar afiliación ARL-IPS: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar Afiliación
CREATE OR REPLACE FUNCTION fn_tab_trab_arl_ips_delete(p_id INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores_arl_ips WHERE id_trabajador_arl_ips = p_id) THEN
        RAISE EXCEPTION 'La afiliación con ID % no existe', p_id;
    END IF;

    DELETE FROM tab_trabajadores_arl_ips WHERE id_trabajador_arl_ips = p_id;
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar afiliación ARL-IPS: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Listar Afiliaciones
CREATE OR REPLACE FUNCTION fn_tab_trab_arl_ips_select(p_id INTEGER DEFAULT NULL)
RETURNS TABLE (
    id_trabajador_arl_ips INTEGER,
    id_trabajador VARCHAR(20),
    nom_trabajador VARCHAR(100),
    ape_trabajador VARCHAR(100),
    id_arl INTEGER,
    nom_arl VARCHAR(100),
    id_ips INTEGER,
    nom_ips VARCHAR(100),
    fecha_afiliacion DATE,
    fecha_retiro DATE
) AS $$
BEGIN
    IF p_id IS NULL THEN
        RETURN QUERY 
        SELECT r.id_trabajador_arl_ips, r.id_trabajador, t.nom_trabajador, t.ape_trabajador, r.id_arl, a.nom_arl, r.id_ips, i.nom_ips, r.fecha_afiliacion, r.fecha_retiro 
        FROM tab_trabajadores_arl_ips r
        JOIN tab_trabajadores t ON r.id_trabajador = t.id_trabajador
        JOIN tab_arl a ON r.id_arl = a.id_arl
        JOIN tab_ips i ON r.id_ips = i.id_ips;
    ELSE
        RETURN QUERY 
        SELECT r.id_trabajador_arl_ips, r.id_trabajador, t.nom_trabajador, t.ape_trabajador, r.id_arl, a.nom_arl, r.id_ips, i.nom_ips, r.fecha_afiliacion, r.fecha_retiro 
        FROM tab_trabajadores_arl_ips r 
        JOIN tab_trabajadores t ON r.id_trabajador = t.id_trabajador
        JOIN tab_arl a ON r.id_arl = a.id_arl
        JOIN tab_ips i ON r.id_ips = i.id_ips
        WHERE r.id_trabajador_arl_ips = p_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

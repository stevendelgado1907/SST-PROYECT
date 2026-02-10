-- Función para insertar relación trabajador-arl-ips

CREATE OR REPLACE FUNCTION fn_insertar_trabajador_arl_ips(
    p_id_trabajador_arl_ips INTEGER,
    p_id_trabajador INTEGER,
    p_id_arl INTEGER,
    p_id_ips INTEGER,
    p_fecha_afiliacion DATE,
    p_fecha_retiro DATE DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_id_insertado INTEGER;
BEGIN
    -- Validar que el trabajador exista
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores WHERE id_trabajador = p_id_trabajador) THEN
        RAISE EXCEPTION 'El trabajador con ID % no existe', p_id_trabajador;
    END IF;
    
    -- Validar que la ARL exista
    IF NOT EXISTS (SELECT 1 FROM tab_arl WHERE id_arl = p_id_arl) THEN
        RAISE EXCEPTION 'La ARL con ID % no existe', p_id_arl;
    END IF;
    
    -- Validar que la IPS exista
    IF NOT EXISTS (SELECT 1 FROM tab_ips WHERE id_ips = p_id_ips) THEN
        RAISE EXCEPTION 'La IPS con ID % no existe', p_id_ips;
    END IF;
    
    INSERT INTO tab_trabajadores_arl_ips (
        id_trabajador_arl_ips, 
        id_trabajador, 
        id_arl, 
        id_ips, 
        fecha_afiliacion, 
        fecha_retiro
    )
    VALUES (
        p_id_trabajador_arl_ips,
        p_id_trabajador,
        p_id_arl,
        p_id_ips,
        p_fecha_afiliacion,
        p_fecha_retiro
    )
    RETURNING id_trabajador_arl_ips INTO v_id_insertado;
    
    RETURN v_id_insertado;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar relación trabajador-arl-ips: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
-- Función para insertar relación trabajador-epp

CREATE OR REPLACE FUNCTION fn_insertar_trabajador_epp(
    p_id_trabajador_epp INTEGER,
    p_id_trabajador INTEGER,
    p_id_epp INTEGER,
    p_fecha_asignacion DATE,
    p_fecha_retiro DATE DEFAULT NULL,
    p_estado_epp VARCHAR(50) DEFAULT 'Activo'
) RETURNS INTEGER AS $$
DECLARE
    v_id_insertado INTEGER;
BEGIN
    -- Validar que el trabajador exista
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores WHERE id_trabajador = p_id_trabajador) THEN
        RAISE EXCEPTION 'El trabajador con ID % no existe', p_id_trabajador;
    END IF;
    
    -- Validar que el EPP exista
    IF NOT EXISTS (SELECT 1 FROM tab_epp WHERE id_epp = p_id_epp) THEN
        RAISE EXCEPTION 'El EPP con ID % no existe', p_id_epp;
    END IF;
    
    INSERT INTO tab_trabajadores_epp (
        id_trabajador_epp, 
        id_trabajador, 
        id_epp, 
        fecha_asignacion, 
        fecha_retiro, 
        estado_epp
    )
    VALUES (
        p_id_trabajador_epp,
        p_id_trabajador,
        p_id_epp,
        p_fecha_asignacion,
        p_fecha_retiro,
        p_estado_epp
    )
    RETURNING id_trabajador_epp INTO v_id_insertado;
    
    RETURN v_id_insertado;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar relación trabajador-epp: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
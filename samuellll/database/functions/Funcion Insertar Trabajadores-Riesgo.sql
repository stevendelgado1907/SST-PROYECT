-- Función para insertar relación trabajador-riesgos

CREATE OR REPLACE FUNCTION fn_insertar_trabajador_riesgo(
    p_id_trabajador_riesgo INTEGER,
    p_id_trabajador INTEGER,
    p_id_riesgo INTEGER,
    p_fecha_asignacion DATE,
    p_fecha_retiro DATE DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_id_insertado INTEGER;
BEGIN
    -- Validar que el trabajador exista
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores WHERE id_trabajador = p_id_trabajador) THEN
        RAISE EXCEPTION 'El trabajador con ID % no existe', p_id_trabajador;
    END IF;
    
    -- Validar que el riesgo exista
    IF NOT EXISTS (SELECT 1 FROM tab_riesgos WHERE id_riesgo = p_id_riesgo) THEN
        RAISE EXCEPTION 'El riesgo con ID % no existe', p_id_riesgo;
    END IF;
    
    INSERT INTO tab_trabajadores_riesgos (
        id_trabajador_riesgo, 
        id_trabajador, 
        id_riesgo, 
        fecha_asignacion, 
        fecha_retiro
    )
    VALUES (
        p_id_trabajador_riesgo,
        p_id_trabajador,
        p_id_riesgo,
        p_fecha_asignacion,
        p_fecha_retiro
    )
    RETURNING id_trabajador_riesgo INTO v_id_insertado;
    
    RETURN v_id_insertado;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar relación trabajador-riesgo: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
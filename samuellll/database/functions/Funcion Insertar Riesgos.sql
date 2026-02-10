CREATE OR REPLACE FUNCTION fn_insertar_riesgo(
    p_nom_riesgo VARCHAR(100),
    p_tipo_riesgo VARCHAR(100),
    p_descripcion_riesgo TEXT,
    p_nivel_de_riesgo VARCHAR(50),
    p_probabilidad_riesgo VARCHAR(50),
    p_severidad_riesgo VARCHAR(50),
    p_medidas_control VARCHAR(255)
) RETURNS INTEGER AS $$
DECLARE
    v_id_insertado INTEGER;
BEGIN
    -- Validaciones
    IF p_nom_riesgo IS NULL OR TRIM(p_nom_riesgo) = '' THEN
        RAISE EXCEPTION 'El nombre del riesgo es obligatorio';
    END IF;
    
    IF LENGTH(p_nom_riesgo) > 100 THEN
        RAISE EXCEPTION 'El nombre del riesgo no puede exceder 100 caracteres';
    END IF;
    
    IF p_tipo_riesgo IS NULL OR TRIM(p_tipo_riesgo) = '' THEN
        RAISE EXCEPTION 'El tipo de riesgo es obligatorio';
    END IF;
    
    IF LENGTH(p_tipo_riesgo) > 100 THEN
        RAISE EXCEPTION 'El tipo de riesgo no puede exceder 100 caracteres';
    END IF;
    
    IF p_descripcion_riesgo IS NULL OR TRIM(p_descripcion_riesgo) = '' THEN
        RAISE EXCEPTION 'La descripción del riesgo es obligatoria';
    END IF;
    
    IF p_nivel_de_riesgo IS NULL OR TRIM(p_nivel_de_riesgo) = '' THEN
        RAISE EXCEPTION 'El nivel de riesgo es obligatorio';
    END IF;
    
    IF LENGTH(p_nivel_de_riesgo) > 50 THEN
        RAISE EXCEPTION 'El nivel de riesgo no puede exceder 50 caracteres';
    END IF;
    
    IF p_probabilidad_riesgo IS NULL OR TRIM(p_probabilidad_riesgo) = '' THEN
        RAISE EXCEPTION 'La probabilidad del riesgo es obligatoria';
    END IF;
    
    IF LENGTH(p_probabilidad_riesgo) > 50 THEN
        RAISE EXCEPTION 'La probabilidad no puede exceder 50 caracteres';
    END IF;
    
    IF p_severidad_riesgo IS NULL OR TRIM(p_severidad_riesgo) = '' THEN
        RAISE EXCEPTION 'La severidad del riesgo es obligatoria';
    END IF;
    
    IF LENGTH(p_severidad_riesgo) > 50 THEN
        RAISE EXCEPTION 'La severidad no puede exceder 50 caracteres';
    END IF;
    
    IF p_medidas_control IS NULL OR TRIM(p_medidas_control) = '' THEN
        RAISE EXCEPTION 'Las medidas de control son obligatorias';
    END IF;
    
    IF LENGTH(p_medidas_control) > 255 THEN
        RAISE EXCEPTION 'Las medidas de control no pueden exceder 255 caracteres';
    END IF;
    
    -- Inserción
    INSERT INTO tab_riesgos (
        id_riesgo, 
        nom_riesgo, 
        tipo_riesgo, 
        descripcion_riesgo, 
        nivel_de_riesgo, 
        probabilidad_riesgo, 
        severidad_riesgo, 
        medidas_control
    )
    VALUES (
        NEXTVAL('seq_riesgos'),
        UPPER(TRIM(p_nom_riesgo)),
        UPPER(TRIM(p_tipo_riesgo)),
        TRIM(p_descripcion_riesgo),
        UPPER(TRIM(p_nivel_de_riesgo)),
        UPPER(TRIM(p_probabilidad_riesgo)),
        UPPER(TRIM(p_severidad_riesgo)),
        TRIM(p_medidas_control)
    )
    RETURNING id_riesgo INTO v_id_insertado;
    
    RETURN v_id_insertado;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe un riesgo con este nombre';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar riesgo: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
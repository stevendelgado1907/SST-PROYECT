CREATE OR REPLACE FUNCTION fn_insertar_eps(
    p_nom_eps VARCHAR(100),
    p_direccion_eps VARCHAR(200),
    p_tel_eps VARCHAR(15),
    p_correo_eps VARCHAR(100)
) RETURNS INTEGER AS $$
DECLARE
    v_id_insertado INTEGER;
    v_tel_validado DECIMAL(15);
BEGIN
    -- Validaciones
    IF p_nom_eps IS NULL OR TRIM(p_nom_eps) = '' THEN
        RAISE EXCEPTION 'El nombre de la EPS es obligatorio';
    END IF;
    
    IF LENGTH(p_nom_eps) > 100 THEN
        RAISE EXCEPTION 'El nombre de la EPS no puede exceder 100 caracteres';
    END IF;
    
    IF p_direccion_eps IS NULL OR TRIM(p_direccion_eps) = '' THEN
        RAISE EXCEPTION 'La dirección de la EPS es obligatoria';
    END IF;
    
    IF LENGTH(p_direccion_eps) > 200 THEN
        RAISE EXCEPTION 'La dirección no puede exceder 200 caracteres';
    END IF;
    
    IF p_correo_eps IS NOT NULL AND p_correo_eps != '' THEN
        IF POSITION('@' IN p_correo_eps) = 0 THEN
            RAISE EXCEPTION 'El correo de la EPS debe contener @';
        END IF;
    END IF;
    
    -- Validar teléfono
    BEGIN
        v_tel_validado := CAST(p_tel_eps AS DECIMAL(15));
    EXCEPTION
        WHEN invalid_text_representation THEN
            RAISE EXCEPTION 'El teléfono debe contener solo números';
    END;
    
    -- Inserción
    INSERT INTO tab_eps (
        id_eps, 
        nom_eps, 
        direccion_eps, 
        tel_eps, 
        correo_eps
    )
    VALUES (
        NEXTVAL('seq_eps'),
        UPPER(TRIM(p_nom_eps)),
        INITCAP(TRIM(p_direccion_eps)),
        v_tel_validado,
        LOWER(TRIM(p_correo_eps))
    )
    RETURNING id_eps INTO v_id_insertado;
    
    RETURN v_id_insertado;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe una EPS con este nombre';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar EPS: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION fn_insertar_arl(
    p_nom_arl VARCHAR(100),
    p_nit_arl VARCHAR(20),
    p_direccion_arl VARCHAR(200),
    p_tel_arl VARCHAR(15),
    p_correo_arl VARCHAR(100)
) RETURNS INTEGER AS $$
DECLARE
    v_id_insertado INTEGER;
    v_tel_validado DECIMAL(15);
BEGIN
    -- Validaciones
    IF p_nom_arl IS NULL OR TRIM(p_nom_arl) = '' THEN
        RAISE EXCEPTION 'El nombre de la ARL es obligatorio';
    END IF;
    
    IF LENGTH(p_nom_arl) > 100 THEN
        RAISE EXCEPTION 'El nombre de la ARL no puede exceder 100 caracteres';
    END IF;
    
    IF p_nit_arl IS NULL OR TRIM(p_nit_arl) = '' THEN
        RAISE EXCEPTION 'El NIT de la ARL es obligatorio';
    END IF;
    
    IF LENGTH(p_nit_arl) > 20 THEN
        RAISE EXCEPTION 'El NIT no puede exceder 20 caracteres';
    END IF;
    
    IF p_direccion_arl IS NULL OR TRIM(p_direccion_arl) = '' THEN
        RAISE EXCEPTION 'La dirección de la ARL es obligatoria';
    END IF;
    
    IF LENGTH(p_direccion_arl) > 200 THEN
        RAISE EXCEPTION 'La dirección no puede exceder 200 caracteres';
    END IF;
    
    IF p_correo_arl IS NOT NULL AND p_correo_arl != '' THEN
        IF POSITION('@' IN p_correo_arl) = 0 THEN
            RAISE EXCEPTION 'El correo de la ARL debe contener @';
        END IF;
    END IF;
    
    -- Validar teléfono
    BEGIN
        v_tel_validado := CAST(p_tel_arl AS DECIMAL(15));
    EXCEPTION
        WHEN invalid_text_representation THEN
            RAISE EXCEPTION 'El teléfono debe contener solo números';
    END;
    
    -- Inserción
    INSERT INTO tab_arl (
        id_arl, 
        nom_arl, 
        nit_arl, 
        direccion_arl, 
        tel_arl, 
        correo_arl
    )
    VALUES (
        NEXTVAL('seq_arl'),
        UPPER(TRIM(p_nom_arl)),
        REPLACE(UPPER(TRIM(p_nit_arl)), ' ', ''),
        INITCAP(TRIM(p_direccion_arl)),
        v_tel_validado,
        LOWER(TRIM(p_correo_arl))
    )
    RETURNING id_arl INTO v_id_insertado;
    
    RETURN v_id_insertado;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe una ARL con este NIT o nombre';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar ARL: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
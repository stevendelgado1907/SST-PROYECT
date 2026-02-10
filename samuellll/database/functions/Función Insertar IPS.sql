CREATE OR REPLACE FUNCTION fn_insertar_ips(
    p_nom_ips VARCHAR(100),
    p_direccion_ips VARCHAR(200),
    p_tel_ips VARCHAR(15),
    p_correo_ips VARCHAR(100)
) RETURNS INTEGER AS $$
DECLARE
    v_id_insertado INTEGER;
    v_tel_validado DECIMAL(15);
BEGIN
    -- Validaciones
    IF p_nom_ips IS NULL OR TRIM(p_nom_ips) = '' THEN
        RAISE EXCEPTION 'El nombre de la IPS es obligatorio';
    END IF;
    
    IF LENGTH(p_nom_ips) > 100 THEN
        RAISE EXCEPTION 'El nombre de la IPS no puede exceder 100 caracteres';
    END IF;
    
    IF p_direccion_ips IS NULL OR TRIM(p_direccion_ips) = '' THEN
        RAISE EXCEPTION 'La dirección de la IPS es obligatoria';
    END IF;
    
    IF LENGTH(p_direccion_ips) > 200 THEN
        RAISE EXCEPTION 'La dirección no puede exceder 200 caracteres';
    END IF;
    
    IF p_correo_ips IS NOT NULL AND p_correo_ips != '' THEN
        IF POSITION('@' IN p_correo_ips) = 0 THEN
            RAISE EXCEPTION 'El correo de la IPS debe contener @';
        END IF;
    END IF;
    
    -- Validar teléfono
    BEGIN
        v_tel_validado := CAST(p_tel_ips AS DECIMAL(15));
    EXCEPTION
        WHEN invalid_text_representation THEN
            RAISE EXCEPTION 'El teléfono debe contener solo números';
    END;
    
    -- Inserción
    INSERT INTO tab_ips (
        id_ips, 
        nom_ips, 
        direccion_ips, 
        tel_ips, 
        correo_ips
    )
    VALUES (
        NEXTVAL('seq_ips'),
        UPPER(TRIM(p_nom_ips)),
        INITCAP(TRIM(p_direccion_ips)),
        v_tel_validado,
        LOWER(TRIM(p_correo_ips))
    )
    RETURNING id_ips INTO v_id_insertado;
    
    RETURN v_id_insertado;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe una IPS con este nombre';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar IPS: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION fn_insertar_supervisor(
    p_nom_supervisor VARCHAR(100),
    p_ape_supervisor VARCHAR(100),
    p_correo_supervisor VARCHAR(100),
    p_tel_supervisor VARCHAR(15),
    p_fecha_ingreso_supervisor DATE,
    p_fecha_retiro_supervisor DATE DEFAULT NULL,
    p_certificacion_supervisor VARCHAR(100)
) RETURNS INTEGER AS $$
DECLARE
    v_id_insertado INTEGER;
    v_tel_validado DECIMAL(15);
BEGIN
    -- Validaciones
    IF p_nom_supervisor IS NULL OR TRIM(p_nom_supervisor) = '' THEN
        RAISE EXCEPTION 'El nombre del supervisor es obligatorio';
    END IF;
    
    IF LENGTH(p_nom_supervisor) > 100 THEN
        RAISE EXCEPTION 'El nombre del supervisor no puede exceder 100 caracteres';
    END IF;
    
    IF p_ape_supervisor IS NULL OR TRIM(p_ape_supervisor) = '' THEN
        RAISE EXCEPTION 'El apellido del supervisor es obligatorio';
    END IF;
    
    IF LENGTH(p_ape_supervisor) > 100 THEN
        RAISE EXCEPTION 'El apellido del supervisor no puede exceder 100 caracteres';
    END IF;
    
    IF p_correo_supervisor IS NULL OR TRIM(p_correo_supervisor) = '' THEN
        RAISE EXCEPTION 'El correo del supervisor es obligatorio';
    END IF;
    
    IF POSITION('@' IN p_correo_supervisor) = 0 THEN
        RAISE EXCEPTION 'El correo del supervisor debe contener @';
    END IF;
    
    IF LENGTH(p_correo_supervisor) > 100 THEN
        RAISE EXCEPTION 'El correo no puede exceder 100 caracteres';
    END IF;
    
    IF p_fecha_ingreso_supervisor IS NULL THEN
        RAISE EXCEPTION 'La fecha de ingreso es obligatoria';
    END IF;
    
    IF p_certificacion_supervisor IS NULL OR TRIM(p_certificacion_supervisor) = '' THEN
        RAISE EXCEPTION 'La certificación del supervisor es obligatoria';
    END IF;
    
    IF LENGTH(p_certificacion_supervisor) > 100 THEN
        RAISE EXCEPTION 'La certificación no puede exceder 100 caracteres';
    END IF;
    
    -- Validar teléfono
    BEGIN
        v_tel_validado := CAST(p_tel_supervisor AS DECIMAL(15));
    EXCEPTION
        WHEN invalid_text_representation THEN
            RAISE EXCEPTION 'El teléfono debe contener solo números';
    END;
    
    -- Validar fechas
    IF p_fecha_retiro_supervisor IS NOT NULL THEN
        IF p_fecha_retiro_supervisor < p_fecha_ingreso_supervisor THEN
            RAISE EXCEPTION 'La fecha de retiro no puede ser anterior a la fecha de ingreso';
        END IF;
    END IF;
    
    -- Inserción
    INSERT INTO tab_supervisores (
        id_supervisor, 
        nom_supervisor, 
        ape_supervisor, 
        correo_supervisor, 
        tel_supervisor, 
        fecha_ingreso_supervisor, 
        fecha_retiro_supervisor, 
        certificacion_supervisor
    )
    VALUES (
        NEXTVAL('seq_supervisores'),
        INITCAP(TRIM(p_nom_supervisor)),
        INITCAP(TRIM(p_ape_supervisor)),
        LOWER(TRIM(p_correo_supervisor)),
        v_tel_validado,
        p_fecha_ingreso_supervisor,
        p_fecha_retiro_supervisor,
        UPPER(TRIM(p_certificacion_supervisor))
    )
    RETURNING id_supervisor INTO v_id_insertado;
    
    RETURN v_id_insertado;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe un supervisor con este correo electrónico';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar supervisor: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
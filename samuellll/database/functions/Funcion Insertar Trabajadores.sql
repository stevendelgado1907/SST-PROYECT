CREATE OR REPLACE FUNCTION fn_insertar_trabajador(
    p_id_trabajador VARCHAR(20),
    p_id_cargo INTEGER,
    p_nom_trabajador VARCHAR(100),
    p_ape_trabajador VARCHAR(100),
    p_tel_trabajador VARCHAR(15),
    p_correo_trabajador VARCHAR(100),
    p_direccion_trabajador VARCHAR(200),
    p_rh_trabajador VARCHAR(5),
    p_sexo_trabajador VARCHAR(10),
    p_fecha_ingreso_trabajador DATE,
	  p_tipo_documento VARCHAR(3) DEFAULT 'CC',
    p_fecha_retiro_trabajador DATE DEFAULT NULL) RETURNS VARCHAR AS $$

DECLARE
    v_id_insertado VARCHAR(20);
    v_cargo_existe BOOLEAN;

BEGIN
    -- VALIDACIÓN DE DOCUMENTO DE IDENTIDAD
    IF p_id_trabajador IS NULL OR TRIM(p_id_trabajador) = '' THEN
        RAISE EXCEPTION 'El número de documento es obligatorio';
    END IF;
    
    -- VALIDACIÓN DE FORMATO SEGÚN TIPO DE DOCUMENTO
    IF UPPER(TRIM(p_tipo_documento)) = 'CC' THEN
        IF NOT p_id_trabajador ~ '^[0-9]+$' THEN
            RAISE EXCEPTION 'La cédula de ciudadanía debe contener solo valores numéricos';
        END IF;
        
        IF LENGTH(p_id_trabajador) < 8 OR LENGTH(p_id_trabajador) > 10 THEN
            RAISE EXCEPTION 'La cédula debe tener entre 8 y 10 dígitos';
        END IF;
    ELSIF UPPER(TRIM(p_tipo_documento)) = 'TI' THEN
        IF NOT p_id_trabajador ~ '^[0-9]+$' THEN
            RAISE EXCEPTION 'La tarjeta de identidad debe contener solo valores numéricos';
        END IF;
    END IF;
    
    -- VERIFICACIÓN DE DOCUMENTO DUPLICADO
    IF EXISTS (SELECT 1 FROM tab_trabajadores WHERE id_trabajador = p_id_trabajador) THEN
        RAISE EXCEPTION 'Ya existe un trabajador con documento %', p_id_trabajador;
    END IF;
    
    -- VALIDACIÓN DE CARGO
    IF p_id_cargo IS NULL THEN
        RAISE EXCEPTION 'El identificador del cargo es obligatorio';
    END IF;
    
    -- VERIFICACIÓN DE EXISTENCIA DEL CARGO
    SELECT EXISTS (SELECT 1 FROM tab_cargos WHERE id_cargo = p_id_cargo) INTO v_cargo_existe;
    IF NOT v_cargo_existe THEN
        RAISE EXCEPTION 'El cargo con identificador % no existe', p_id_cargo;
    END IF;
    
    -- VALIDACIÓN DE NOMBRE
    IF p_nom_trabajador IS NULL OR TRIM(p_nom_trabajador) = '' THEN
        RAISE EXCEPTION 'El nombre del trabajador es obligatorio';
    END IF;
    
    IF LENGTH(p_nom_trabajador) > 100 THEN
        RAISE EXCEPTION 'El nombre del trabajador no puede exceder 100 caracteres';
    END IF;
    
    -- VALIDACIÓN DE APELLIDO
    IF p_ape_trabajador IS NULL OR TRIM(p_ape_trabajador) = '' THEN
        RAISE EXCEPTION 'El apellido del trabajador es obligatorio';
    END IF;
    
    IF LENGTH(p_ape_trabajador) > 100 THEN
        RAISE EXCEPTION 'El apellido del trabajador no puede exceder 100 caracteres';
    END IF;
    
    -- VALIDACIÓN DE NÚMERO TELEFÓNICO
    IF p_tel_trabajador IS NULL OR TRIM(p_tel_trabajador) = '' THEN
        RAISE EXCEPTION 'El número telefónico del trabajador es obligatorio';
    END IF;
    
    IF NOT p_tel_trabajador ~ '^[0-9]+$' THEN
        RAISE EXCEPTION 'El número telefónico debe contener solo dígitos numéricos';
    END IF;
    
    IF LENGTH(p_tel_trabajador) < 7 OR LENGTH(p_tel_trabajador) > 15 THEN
        RAISE EXCEPTION 'El número telefónico debe tener entre 7 y 15 dígitos';
    END IF;
    
    -- VALIDACIÓN DE CORREO ELECTRÓNICO
    IF p_correo_trabajador IS NULL OR TRIM(p_correo_trabajador) = '' THEN
        RAISE EXCEPTION 'La dirección de correo electrónico es obligatoria';
    END IF;
    
    IF POSITION('@' IN p_correo_trabajador) = 0 THEN
        RAISE EXCEPTION 'La dirección de correo electrónico debe contener el símbolo @';
    END IF;
    
    IF LENGTH(p_correo_trabajador) > 100 THEN
        RAISE EXCEPTION 'La dirección de correo electrónico no puede exceder 100 caracteres';
    END IF;
    
    -- VALIDACIÓN DE DIRECCIÓN
    IF p_direccion_trabajador IS NULL OR TRIM(p_direccion_trabajador) = '' THEN
        RAISE EXCEPTION 'La dirección del trabajador es obligatoria';
    END IF;
    
    IF LENGTH(p_direccion_trabajador) > 200 THEN
        RAISE EXCEPTION 'La dirección no puede exceder 200 caracteres';
    END IF;
    
    -- VALIDACIÓN DE GRUPO SANGUÍNEO
    IF p_rh_trabajador IS NULL OR TRIM(p_rh_trabajador) = '' THEN
        RAISE EXCEPTION 'El grupo sanguíneo (RH) es obligatorio';
    END IF;
    
    IF LENGTH(p_rh_trabajador) > 5 THEN
        RAISE EXCEPTION 'El grupo sanguíneo no puede exceder 5 caracteres';
    END IF;
    
    -- VALIDACIÓN DE GÉNERO
    IF p_sexo_trabajador IS NULL OR TRIM(p_sexo_trabajador) = '' THEN
        RAISE EXCEPTION 'El género del trabajador es obligatorio';
    END IF;
    
    IF LENGTH(p_sexo_trabajador) > 10 THEN
        RAISE EXCEPTION 'El género no puede exceder 10 caracteres';
    END IF;
    
    -- VALIDACIÓN DE VALORES PERMITIDOS PARA GÉNERO
    IF UPPER(TRIM(p_sexo_trabajador)) NOT IN ('MASCULINO', 'FEMENINO', 'OTRO') THEN
        RAISE WARNING 'Valor de género no estándar registrado: %', p_sexo_trabajador;
    END IF;
    
    -- VALIDACIÓN DE FECHA DE INGRESO
    IF p_fecha_ingreso_trabajador IS NULL THEN
        RAISE EXCEPTION 'La fecha de ingreso es obligatoria';
    END IF;
    
    -- VALIDACIÓN DE CONSISTENCIA DE FECHAS
    IF p_fecha_retiro_trabajador IS NOT NULL THEN
        IF p_fecha_retiro_trabajador < p_fecha_ingreso_trabajador THEN
            RAISE EXCEPTION 'La fecha de retiro no puede ser anterior a la fecha de ingreso';
        END IF;
        
        IF p_fecha_retiro_trabajador > CURRENT_DATE THEN
            RAISE EXCEPTION 'La fecha de retiro no puede ser una fecha futura';
        END IF;
    END IF;
    
    -- VALIDACIÓN DE FECHA DE INGRESO FUTURA
    IF p_fecha_ingreso_trabajador > CURRENT_DATE THEN
        RAISE WARNING 'Se ha registrado una fecha de ingreso futura: %', p_fecha_ingreso_trabajador;
    END IF;
    
    -- INSERCIÓN DE REGISTRO EN LA TABLA DE TRABAJADORES
    INSERT INTO tab_trabajadores (
        id_trabajador,
        tipo_documento,
        id_cargo, 
        nom_trabajador, 
        ape_trabajador, 
        tel_trabajador, 
        correo_trabajador, 
        direccion_trabajador, 
        rh_trabajador, 
        sexo_trabajador, 
        fecha_ingreso_trabajador, 
        fecha_retiro_trabajador
    )
    VALUES (
        p_id_trabajador,
        UPPER(TRIM(p_tipo_documento)),
        p_id_cargo,
        INITCAP(TRIM(p_nom_trabajador)),
        INITCAP(TRIM(p_ape_trabajador)),
        TRIM(p_tel_trabajador),
        LOWER(TRIM(p_correo_trabajador)),
        INITCAP(TRIM(p_direccion_trabajador)),
        UPPER(TRIM(p_rh_trabajador)),
        UPPER(TRIM(p_sexo_trabajador)),
        p_fecha_ingreso_trabajador,
        p_fecha_retiro_trabajador
    )
    RETURNING id_trabajador INTO v_id_insertado;
    
    RETURN v_id_insertado;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Violación de restricción de unicidad: Ya existe un registro con estos datos';
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Violación de integridad referencial: El cargo especificado no existe';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error en la inserción del trabajador: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
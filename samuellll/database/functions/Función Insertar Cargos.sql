CREATE OR REPLACE FUNCTION fn_insertar_cargo(
    p_nom_cargo VARCHAR(100),
    p_descripcion_cargo VARCHAR(255),
    p_nivel_riesgo_cargo VARCHAR(50),
    p_salario_base TEXT,
    p_departamento VARCHAR(100)
) RETURNS INTEGER AS $$
DECLARE
    v_id_insertado INTEGER;
    v_salario_validado DECIMAL(10,2);
BEGIN
    -- Validaciones
    IF p_nom_cargo IS NULL OR TRIM(p_nom_cargo) = '' THEN
        RAISE EXCEPTION 'El nombre del cargo es obligatorio';
    END IF;
    
    IF LENGTH(p_nom_cargo) > 100 THEN
        RAISE EXCEPTION 'El nombre del cargo no puede exceder 100 caracteres';
    END IF;
    
    IF p_descripcion_cargo IS NULL OR TRIM(p_descripcion_cargo) = '' THEN
        RAISE EXCEPTION 'La descripción del cargo es obligatoria';
    END IF;
    
    IF LENGTH(p_descripcion_cargo) > 255 THEN
        RAISE EXCEPTION 'La descripción no puede exceder 255 caracteres';
    END IF;
    
    IF p_nivel_riesgo_cargo IS NULL OR TRIM(p_nivel_riesgo_cargo) = '' THEN
        RAISE EXCEPTION 'El nivel de riesgo del cargo es obligatorio';
    END IF;
    
    IF LENGTH(p_nivel_riesgo_cargo) > 50 THEN
        RAISE EXCEPTION 'El nivel de riesgo no puede exceder 50 caracteres';
    END IF;
    
    IF p_salario_base IS NULL OR TRIM(p_salario_base) = '' THEN
        RAISE EXCEPTION 'El salario base es obligatorio';
    END IF;
    
    IF p_departamento IS NULL OR TRIM(p_departamento) = '' THEN
        RAISE EXCEPTION 'El departamento es obligatorio';
    END IF;
    
    IF LENGTH(p_departamento) > 100 THEN
        RAISE EXCEPTION 'El departamento no puede exceder 100 caracteres';
    END IF;
    
    -- Validar salario
    BEGIN
        v_salario_validado := CAST(p_salario_base AS DECIMAL(10,2));
        
        IF v_salario_validado <= 0 THEN
            RAISE EXCEPTION 'El salario base debe ser mayor a 0';
        END IF;
    EXCEPTION
        WHEN invalid_text_representation THEN
            RAISE EXCEPTION 'El salario base debe ser un número válido';
    END;
    
    -- Inserción
    INSERT INTO tab_cargos (
        id_cargo, 
        nom_cargo, 
        descripcion_cargo, 
        nivel_riesgo_cargo, 
        salario_base, 
        departamento
    )
    VALUES (
        NEXTVAL('seq_cargos'),
        UPPER(TRIM(p_nom_cargo)),
        TRIM(p_descripcion_cargo),
        UPPER(TRIM(p_nivel_riesgo_cargo)),
        v_salario_validado,
        UPPER(TRIM(p_departamento))
    )
    RETURNING id_cargo INTO v_id_insertado;
    
    RETURN v_id_insertado;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe un cargo con este nombre';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar cargo: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
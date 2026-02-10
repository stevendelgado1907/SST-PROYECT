CREATE OR REPLACE FUNCTION fn_insertar_epp(
    p_id_marca INTEGER,
    p_id_categoria INTEGER,
    p_talla_epp VARCHAR(50),
    p_nom_epp VARCHAR(100),
    p_tipo_epp VARCHAR(100),
    p_referencia_epp VARCHAR(100),
    p_fabricante_epp VARCHAR(100),
    p_nro_serie_epp VARCHAR(100),
    p_descripcion_epp VARCHAR(255),
    p_fecha_fabricacion_epp DATE,
    p_fecha_vencimiento_epp DATE,
    p_fecha_compra_epp DATE,
    p_vida_util_meses INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_id_insertado INTEGER;
    v_categoria_existe BOOLEAN;
    v_fecha_valida BOOLEAN;
BEGIN
    -- Validaciones
    IF p_id_marca IS NULL THEN
        RAISE EXCEPTION 'El ID de la marca es obligatorio';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM tab_marcas WHERE id_marca = p_id_marca) THEN
        RAISE EXCEPTION 'La marca con ID % no existe', p_id_marca;
    END IF;
    
    IF p_id_categoria IS NULL THEN
        RAISE EXCEPTION 'El ID de la categoría es obligatorio';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM tab_categorias WHERE id_categoria = p_id_categoria) THEN
        RAISE EXCEPTION 'La categoría con ID % no existe', p_id_categoria;
    END IF;
    
    -- Validación de talla
    IF p_talla_epp IS NULL OR TRIM(p_talla_epp) = '' THEN
        RAISE EXCEPTION 'La talla del EPP es obligatoria';
    END IF;
    
    IF LENGTH(p_talla_epp) > 50 THEN
        RAISE EXCEPTION 'La talla no puede exceder 50 caracteres';
    END IF;
    
    -- Validación de nombre
    IF p_nom_epp IS NULL OR TRIM(p_nom_epp) = '' THEN
        RAISE EXCEPTION 'El nombre del EPP es obligatorio';
    END IF;
    
    IF LENGTH(p_nom_epp) > 100 THEN
        RAISE EXCEPTION 'El nombre del EPP no puede exceder 100 caracteres';
    END IF;
    
    -- Validación de tipo
    IF p_tipo_epp IS NULL OR TRIM(p_tipo_epp) = '' THEN
        RAISE EXCEPTION 'El tipo del EPP es obligatorio';
    END IF;
    
    IF LENGTH(p_tipo_epp) > 100 THEN
        RAISE EXCEPTION 'El tipo del EPP no puede exceder 100 caracteres';
    END IF;
    
    -- Validación de referencia
    IF p_referencia_epp IS NULL OR TRIM(p_referencia_epp) = '' THEN
        RAISE EXCEPTION 'La referencia del EPP es obligatoria';
    END IF;
    
    IF LENGTH(p_referencia_epp) > 100 THEN
        RAISE EXCEPTION 'La referencia no puede exceder 100 caracteres';
    END IF;
    
    -- Validación de fabricante
    IF p_fabricante_epp IS NULL OR TRIM(p_fabricante_epp) = '' THEN
        RAISE EXCEPTION 'El fabricante del EPP es obligatorio';
    END IF;
    
    IF LENGTH(p_fabricante_epp) > 100 THEN
        RAISE EXCEPTION 'El fabricante no puede exceder 100 caracteres';
    END IF;
    
    -- Validación de número de serie
    IF p_nro_serie_epp IS NULL OR TRIM(p_nro_serie_epp) = '' THEN
        RAISE EXCEPTION 'El número de serie del EPP es obligatorio';
    END IF;
    
    IF LENGTH(p_nro_serie_epp) > 100 THEN
        RAISE EXCEPTION 'El número de serie no puede exceder 100 caracteres';
    END IF;
    
    -- Verificar número de serie único
    IF EXISTS (SELECT 1 FROM tab_epp WHERE nro_serie_epp = UPPER(TRIM(p_nro_serie_epp))) THEN
        RAISE EXCEPTION 'Ya existe un EPP con el número de serie %', p_nro_serie_epp;
    END IF;
    
    -- Validación de descripción
    IF p_descripcion_epp IS NULL OR TRIM(p_descripcion_epp) = '' THEN
        RAISE EXCEPTION 'La descripción del EPP es obligatoria';
    END IF;
    
    IF LENGTH(p_descripcion_epp) > 255 THEN
        RAISE EXCEPTION 'La descripción no puede exceder 255 caracteres';
    END IF;
    
    -- Validación de fechas
    IF p_fecha_fabricacion_epp IS NULL THEN
        RAISE EXCEPTION 'La fecha de fabricación es obligatoria';
    END IF;
    
    IF p_fecha_vencimiento_epp IS NULL THEN
        RAISE EXCEPTION 'La fecha de vencimiento es obligatoria';
    END IF;
    
    IF p_fecha_compra_epp IS NULL THEN
        RAISE EXCEPTION 'La fecha de compra es obligatoria';
    END IF;
    
    -- Validar que fecha de fabricación no sea futura
    IF p_fecha_fabricacion_epp > CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de fabricación no puede ser una fecha futura';
    END IF;
    
    -- Validar que fecha de vencimiento sea posterior a fabricación
    IF p_fecha_vencimiento_epp <= p_fecha_fabricacion_epp THEN
        RAISE EXCEPTION 'La fecha de vencimiento debe ser posterior a la fecha de fabricación';
    END IF;
    
    -- Validar que fecha de compra no sea futura
    IF p_fecha_compra_epp > CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de compra no puede ser una fecha futura';
    END IF;
    
    -- Validar que fecha de compra sea posterior o igual a fabricación
    IF p_fecha_compra_epp < p_fecha_fabricacion_epp THEN
        RAISE WARNING 'La fecha de compra es anterior a la fecha de fabricación del EPP';
    END IF;
    
    -- Validación de vida útil
    IF p_vida_util_meses IS NULL THEN
        RAISE EXCEPTION 'La vida útil en meses es obligatoria';
    END IF;
    
    IF p_vida_util_meses <= 0 THEN
        RAISE EXCEPTION 'La vida útil debe ser mayor a 0 meses';
    END IF;
    
    IF p_vida_util_meses > 120 THEN -- 10 años máximo
        RAISE EXCEPTION 'La vida útil no puede exceder 120 meses (10 años)';
    END IF;
    
    -- Verificar coherencia entre vida útil y fechas
    IF EXTRACT(MONTH FROM AGE(p_fecha_vencimiento_epp, p_fecha_fabricacion_epp)) > p_vida_util_meses THEN
        RAISE WARNING 'La diferencia entre fechas de vencimiento y fabricación excede la vida útil declarada';
    END IF;
    
    -- Inserción
    INSERT INTO tab_epp (
        id_epp, 
        id_marca, 
        id_categoria, 
        talla_epp, 
        nom_epp, 
        tipo_epp, 
        referencia_epp, 
        fabricante_epp, 
        nro_serie_epp, 
        descripcion_epp, 
        fecha_fabricacion_epp, 
        fecha_vencimiento_epp, 
        fecha_compra_epp, 
        vida_util_meses,
        estado_epp
    )
    VALUES (
        NEXTVAL('seq_epp'),
        p_id_marca,
        p_id_categoria,
        UPPER(TRIM(p_talla_epp)),
        UPPER(TRIM(p_nom_epp)),
        UPPER(TRIM(p_tipo_epp)),
        UPPER(TRIM(p_referencia_epp)),
        INITCAP(TRIM(p_fabricante_epp)),
        UPPER(TRIM(p_nro_serie_epp)),
        TRIM(p_descripcion_epp),
        p_fecha_fabricacion_epp,
        p_fecha_vencimiento_epp,
        p_fecha_compra_epp,
        p_vida_util_meses,
        'DISPONIBLE'
    )
    RETURNING id_epp INTO v_id_insertado;
    
    -- Insertar registro inicial en inventario
    INSERT INTO inventario_epp (
        id_inventario,
        id_epp,
        stock_actual,
        stock_minimo,
        stock_maximo,
        punto_reorden
    )
    VALUES (
        NEXTVAL('seq_inventario'),
        v_id_insertado,
        1, -- Se asume que al crear un EPP, hay al menos 1 unidad
        1,
        10,
        2
    );
    
    RETURN v_id_insertado;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe un EPP con este número de serie';
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Violación de integridad referencial: La marca o categoría especificada no existe';
    WHEN check_violation THEN
        RAISE EXCEPTION 'Violación de restricción de verificación: Verifique los datos ingresados';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar EPP: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
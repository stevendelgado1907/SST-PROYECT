CREATE OR REPLACE FUNCTION fn_insertar_categoria(
    p_nom_categoria VARCHAR(100),
    p_descripcion_categoria VARCHAR(255)
) RETURNS INTEGER AS $$
DECLARE
    v_id_insertado INTEGER;
BEGIN
    -- Validaciones
    IF p_nom_categoria IS NULL OR TRIM(p_nom_categoria) = '' THEN
        RAISE EXCEPTION 'El nombre de la categoría es obligatorio';
    END IF;
    
    IF LENGTH(p_nom_categoria) > 100 THEN
        RAISE EXCEPTION 'El nombre de la categoría no puede exceder 100 caracteres';
    END IF;
    
    IF p_descripcion_categoria IS NULL OR TRIM(p_descripcion_categoria) = '' THEN
        RAISE EXCEPTION 'La descripción de la categoría es obligatoria';
    END IF;
    
    IF LENGTH(p_descripcion_categoria) > 255 THEN
        RAISE EXCEPTION 'La descripción no puede exceder 255 caracteres';
    END IF;
    
    -- Inserción
    INSERT INTO tab_categorias (
        id_cateogria, 
        nom_categoria, 
        descripcion_categoria
    )
    VALUES (
        NEXTVAL('seq_categorias'),
        UPPER(TRIM(p_nom_categoria)),
        TRIM(p_descripcion_categoria)
    )
    RETURNING id_cateogria INTO v_id_insertado;
    
    RETURN v_id_insertado;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe una categoría con este nombre';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar categoría: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
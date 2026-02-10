CREATE OR REPLACE FUNCTION fn_insertar_marca(
    p_nom_marca VARCHAR(100),
    p_proveedor_marca VARCHAR(100),
    p_contacto_proveedor VARCHAR(15)
) RETURNS INTEGER AS $$
DECLARE
    v_id_insertado INTEGER;
    v_contacto_validado DECIMAL(15);
BEGIN
    -- Validaciones
    IF p_nom_marca IS NULL OR TRIM(p_nom_marca) = '' THEN
        RAISE EXCEPTION 'El nombre de la marca es obligatorio';
    END IF;
    
    IF LENGTH(p_nom_marca) > 100 THEN
        RAISE EXCEPTION 'El nombre de la marca no puede exceder 100 caracteres';
    END IF;
    
    IF p_proveedor_marca IS NULL OR TRIM(p_proveedor_marca) = '' THEN
        RAISE EXCEPTION 'El nombre del proveedor es obligatorio';
    END IF;
    
    IF LENGTH(p_proveedor_marca) > 100 THEN
        RAISE EXCEPTION 'El nombre del proveedor no puede exceder 100 caracteres';
    END IF;
    
    -- Validar contacto
    BEGIN
        v_contacto_validado := CAST(p_contacto_proveedor AS DECIMAL(15));
    EXCEPTION
        WHEN invalid_text_representation THEN
            RAISE EXCEPTION 'El contacto debe contener solo números';
    END;
    
    -- Inserción
    INSERT INTO tab_marcas (
        id_marca, 
        nom_marca, 
        proveedor_marca, 
        contacto_proveedor
    )
    VALUES (
        NEXTVAL('seq_marcas'),
        UPPER(TRIM(p_nom_marca)),
        INITCAP(TRIM(p_proveedor_marca)),
        v_contacto_validado
    )
    RETURNING id_marca INTO v_id_insertado;
    
    RETURN v_id_insertado;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe una marca con este nombre';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar marca: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
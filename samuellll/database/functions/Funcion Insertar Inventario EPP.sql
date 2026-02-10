-- Función para insertar inventario EPP

CREATE OR REPLACE FUNCTION fn_insertar_inventario_epp(
    p_id_inventario INTEGER,
    p_id_epp INTEGER,
    p_stock_actual INTEGER,
    p_stock_minimo INTEGER,
    p_stock_maximo INTEGER,
    p_punto_reorden INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_id_insertado INTEGER;
BEGIN
    -- Validar que el EPP exista
    IF NOT EXISTS (SELECT 1 FROM tab_epp WHERE id_epp = p_id_epp) THEN
        RAISE EXCEPTION 'El EPP con ID % no existe', p_id_epp;
    END IF;
    
    INSERT INTO inventario_epp (
        id_inventario, 
        id_epp, 
        stock_actual, 
        stock_minimo, 
        stock_maximo, 
        punto_reorden
    )
    VALUES (
        p_id_inventario,
        p_id_epp,
        p_stock_actual,
        p_stock_minimo,
        p_stock_maximo,
        p_punto_reorden
    )
    RETURNING id_inventario INTO v_id_insertado;
    
    RETURN v_id_insertado;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar inventario EPP: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
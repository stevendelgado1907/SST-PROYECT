-- CRUD para tab_epp
-- Archivo: CRUD_POSTGRESQL/functions/crud_tab_epp.sql

-- Función para Insertar EPP
CREATE OR REPLACE FUNCTION fn_tab_epp_insert(
    p_id_epp INTEGER,
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
)
RETURNS TABLE (id_epp INTEGER, nom_epp VARCHAR) AS $$
BEGIN
    -- Validaciones de Nulidad
    IF p_id_epp IS NULL THEN RAISE EXCEPTION 'El ID es obligatorio'; END IF;
    IF p_nom_epp IS NULL OR TRIM(p_nom_epp) = '' THEN RAISE EXCEPTION 'El nombre del EPP es obligatorio'; END IF;
    IF p_id_marca IS NULL THEN RAISE EXCEPTION 'La marca es obligatoria'; END IF;
    IF p_id_categoria IS NULL THEN RAISE EXCEPTION 'La categoría es obligatoria'; END IF;

    -- Validaciones de Fechas
    IF p_fecha_vencimiento_epp IS NOT NULL AND p_fecha_vencimiento_epp < p_fecha_fabricacion_epp THEN
        RAISE EXCEPTION 'La fecha de vencimiento no puede ser anterior a la de fabricación';
    END IF;

    -- Verificación de dependencias (Marca y Categoría)
    IF NOT EXISTS (SELECT 1 FROM tab_marcas WHERE id_marca = p_id_marca) THEN RAISE EXCEPTION 'La marca no existe'; END IF;
    IF NOT EXISTS (SELECT 1 FROM tab_categorias WHERE id_categoria = p_id_categoria) THEN RAISE EXCEPTION 'La categoría no existe'; END IF;

    RETURN QUERY
    INSERT INTO tab_epp (id_epp, id_marca, id_categoria, talla_epp, nom_epp, tipo_epp, referencia_epp, fabricante_epp, nro_serie_epp, descripcion_epp, fecha_fabricacion_epp, fecha_vencimiento_epp, fecha_compra_epp, vida_util_meses, estado_epp)
    VALUES (p_id_epp, p_id_marca, p_id_categoria, TRIM(p_talla_epp), TRIM(p_nom_epp), TRIM(p_tipo_epp), TRIM(p_referencia_epp), TRIM(p_fabricante_epp), TRIM(p_nro_serie_epp), TRIM(p_descripcion_epp), p_fecha_fabricacion_epp, p_fecha_vencimiento_epp, p_fecha_compra_epp, p_vida_util_meses, 'NUEVO')
    RETURNING tab_epp.id_epp, tab_epp.nom_epp;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe un EPP con ese ID o Número de Serie.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar EPP: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Actualizar EPP
CREATE OR REPLACE FUNCTION fn_tab_epp_update(
    p_id_epp INTEGER,
    p_id_marca INTEGER,
    p_id_categoria INTEGER,
    p_talla_epp VARCHAR(50),
    p_nom_epp VARCHAR(100),
    p_tipo_epp VARCHAR(100),
    p_referencia_epp VARCHAR(100),
    p_fabricante_epp VARCHAR(100),
    p_nro_serie_epp VARCHAR(100),
    p_descripcion_epp VARCHAR(255),
    p_estado_epp VARCHAR(50)
)
RETURNS TABLE (id_epp INTEGER, nom_epp VARCHAR) AS $$
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM tab_epp WHERE id_epp = p_id_epp) THEN
        RAISE EXCEPTION 'El EPP con ID % no existe', p_id_epp;
    END IF;

    RETURN QUERY
    UPDATE tab_epp
    SET id_marca = p_id_marca,
        id_categoria = p_id_categoria,
        talla_epp = TRIM(p_talla_epp),
        nom_epp = TRIM(p_nom_epp),
        tipo_epp = TRIM(p_tipo_epp),
        referencia_epp = TRIM(p_referencia_epp),
        fabricante_epp = TRIM(p_fabricante_epp),
        nro_serie_epp = TRIM(p_nro_serie_epp),
        descripcion_epp = TRIM(p_descripcion_epp),
        estado_epp = TRIM(p_estado_epp)
    WHERE tab_epp.id_epp = p_id_epp
    RETURNING tab_epp.id_epp, tab_epp.nom_epp;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe otro EPP con ese número de serie.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar EPP: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar EPP
CREATE OR REPLACE FUNCTION fn_tab_epp_delete(p_id_epp INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_epp WHERE id_epp = p_id_epp) THEN
        RAISE EXCEPTION 'El EPP con ID % no existe', p_id_epp;
    END IF;

    -- Verificar dependencias en inventario o trabajadores
    IF EXISTS (SELECT 1 FROM inventario_epp WHERE id_epp = p_id_epp) THEN
        RAISE EXCEPTION 'No se puede eliminar el EPP porque tiene registros en inventario';
    END IF;

    DELETE FROM tab_epp WHERE id_epp = p_id_epp;
    RETURN TRUE;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'No se puede eliminar el EPP porque tiene asignaciones a trabajadores vinculadas';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar EPP: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Listar EPP
CREATE OR REPLACE FUNCTION fn_tab_epp_select(p_id_epp INTEGER DEFAULT NULL)
RETURNS TABLE (
    id_epp INTEGER,
    id_marca INTEGER,
    nom_marca VARCHAR(100),
    id_categoria INTEGER,
    nom_categoria VARCHAR(100),
    talla_epp VARCHAR(50),
    nom_epp VARCHAR(100),
    tipo_epp VARCHAR(100),
    referencia_epp VARCHAR(100),
    fabricante_epp VARCHAR(100),
    nro_serie_epp VARCHAR(100),
    descripcion_epp VARCHAR(255),
    fecha_fabricacion_epp DATE,
    fecha_vencimiento_epp DATE,
    fecha_compra_epp DATE,
    vida_util_meses INTEGER,
    estado_epp VARCHAR(50)
) AS $$
BEGIN
    IF p_id_epp IS NULL THEN
        RETURN QUERY 
        SELECT e.id_epp, e.id_marca, m.nom_marca, e.id_categoria, c.nom_categoria, e.talla_epp, e.nom_epp, e.tipo_epp, e.referencia_epp, e.fabricante_epp, e.nro_serie_epp, e.descripcion_epp, e.fecha_fabricacion_epp, e.fecha_vencimiento_epp, e.fecha_compra_epp, e.vida_util_meses, e.estado_epp 
        FROM tab_epp e
        JOIN tab_marcas m ON e.id_marca = m.id_marca
        JOIN tab_categorias c ON e.id_categoria = c.id_categoria;
    ELSE
        RETURN QUERY 
        SELECT e.id_epp, e.id_marca, m.nom_marca, e.id_categoria, c.nom_categoria, e.talla_epp, e.nom_epp, e.tipo_epp, e.referencia_epp, e.fabricante_epp, e.nro_serie_epp, e.descripcion_epp, e.fecha_fabricacion_epp, e.fecha_vencimiento_epp, e.fecha_compra_epp, e.vida_util_meses, e.estado_epp 
        FROM tab_epp e 
        JOIN tab_marcas m ON e.id_marca = m.id_marca
        JOIN tab_categorias c ON e.id_categoria = c.id_categoria
        WHERE e.id_epp = p_id_epp;
    END IF;
END;
$$ LANGUAGE plpgsql;

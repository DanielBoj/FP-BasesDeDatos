-- PLANTILLA DE ENTREGA DE LA PARTE PRÁCTICA DE LAS ACTIVIDADES
-- --------------------------------------------------------------
-- Actividad: FP.046_PRODUCTO3
--
-- Grupo: Cnv0922_Grupo03: Nínive
-- 
-- Integrantes: 
-- 1. Katiane Coutinho Rosa
-- 2. Miki Alvarez Vidal
-- 3. Daniel Zafra del Pino
-- 4. Daniel Boj Cobos
--
-- Database: ICX0_P3_3
-- --------------------------------------------------------------

USE ICX0_P3_3;

-- Pasos previos

-- Vistas para facilitar la legibilidad del código

CREATE OR REPLACE VIEW v_socios_corporativos AS
	SELECT id_socio
    FROM corporativo;
    

CREATE OR REPLACE VIEW v_socios_principales AS
	SELECT idsocio
    FROM principal;
    
CREATE OR REPLACE VIEW v_socios_beneficiarios AS
	SELECT id_socio
    FROM beneficiario;
    
CREATE OR REPLACE VIEW v_tipo_socio AS 
	SELECT s.id_socio, CASE
		WHEN s.id_socio = c.id_socio THEN 'Corporativo'
		WHEN s.id_socio = p.idsocio THEN 'Principal'
		WHEN s.id_socio = b.id_socio THEN 'Beneficiario'
		END AS 'Tipo de Socio'
	FROM socio s
		LEFT JOIN corporativo c
			ON (c.id_socio = s.id_socio)
		LEFT JOIN principal p
			ON (p.idsocio = s.id_socio)
		LEFT JOIN beneficiario b
			ON (b.id_socio = s.id_socio);

-- Generamos variedad en los planes de los socios beneficiarios
UPDATE socio
	SET id_plan = 2
    WHERE id_socio = 106;

UPDATE socio
	SET id_plan = 3
    WHERE id_socio = 107;	
-- Funciones condicionales

--
-- Ejercicio 1. Mostrar aquellos socios que cumplen años en el mes en curso.
--

SELECT id_socio as 'ID Socio', CONCAT_WS(' ', nombre, apellido1) AS 'Nombre', email AS 'Email', fecha_nacimiento AS 'Fecha de Nacimiento', IF(MONTH(fecha_nacimiento) = MONTH(CURDATE()), 'Sí', 'No') AS 'Cumpleaños'
	FROM socio
    ORDER BY fecha_nacimiento;

--
-- Ejercicio 2.  Contar cuántos socios mujeres y hombres cumplen años en el mes, agrupados por tipo de socio.
--

SELECT IF(s.id_socio IN (SELECT * FROM v_socios_corporativos), 'Corporativo', 'No Corporativo') AS 'Tipo de Socio', COUNT(IF(MONTH(fecha_nacimiento) = MONTH(CURDATE()) AND sexo = 'H', id_socio, NULL)) AS 'Cumpleañeros Masculinos', COUNT(IF(MONTH(fecha_nacimiento) = MONTH(CURDATE()) AND sexo = 'M', id_socio, NULL)) AS 'Cumpleañeros Femeninos'
	FROM socio s
    GROUP BY `Tipo de Socio`;

--
-- Ejercicio 3. Contar cuántos socios no corporativos están registrados, agrupados por plan y cruzados por tipo de socio.
--

SELECT s.id_plan As 'ID Plan', p.plan  AS 'Nombre Plan', COUNT(CASE WHEN s.id_socio IN(SELECT* FROM v_socios_principales) THEN s.id_socio END) AS 'Núm de Socios Principales', 
	COUNT(CASE WHEN s.id_socio IN (SELECT * FROM v_socios_beneficiarios) THEN s.id_socio END) AS 'Núm. de Socios Beneficiarios'
	FROM socio s
    INNER JOIN plan p 
		ON (p.id_plan = s.id_plan)
	GROUP BY s.id_plan;
    
--
-- Ejercicio 4. Inventar una consulta que haga uso de una de las siguientes funciones: COALESCE, IFNULL, NULLIF. 
--
desc actividad;
desc extra;
show tables;
select * from horario;
select * from instalacion;

SELECT COALESCE(a.actividad, 'Libre') AS 'Actividad Programada',  
    IFNULL(i.id_instalacion, 'Disponible') AS 'Número de instalación',
    i.denominacion 'Nombre Instalación',
    IFNULL(h.fecha, 'No rogramada') AS 'Fecha',
    IFNULL(h.hora, 'No programada') AS 'Hora'
FROM instalacion i 
LEFT JOIN horario h
ON (h.id_instalacion = i.id_instalacion) 
LEFT JOIN actividad a 
ON (a.id_actividad = h.id_actividad)
ORDER BY i.id_instalacion, `Fecha`, `Hora`
; 
-- Funciones UDF

--
-- Ejercicio 5. Crear una función UDF llamada Edad que permita calcular la edad de los socios (esta función deberá retornar un número entero). Probar la función en una consulta contra la tabla de socios. La consulta deberá mostrar el idSocio, Nombre, Apellido, Fecha Actual, Fecha de Nacimiento y Edad.
--

DELIMITER |

CREATE FUNCTION edad(fecha_nacimiento DATE)
	RETURNS INT 
    READS SQL DATA 
    BEGIN
		DECLARE edad INT;
        SET edad = TRUNCATE((DATEDIFF(CURDATE(), fecha_nacimiento) / 365), 0);
        RETURN edad;
	END
|
    
DELIMITER ;

 SELECT id_socio AS 'ID Socio', nombre AS 'Nombre', apellido1 AS 'Apellido',  CURDATE() AS 'Fecha Actual', fecha_nacimiento AS 'Fecha de Nacimiento', edad(fecha_nacimiento) AS 'Edad'
	FROM socio;

--
-- Ejercicio 6. Crear una función UDF llamada Nombre_Completo que reciba como parámetros un nombre y dos apellidos y retorne un nombre completo en formato (Apellido1 + Inicial de Apellido2 (de existir) + “., “ + Nombre. Ejemplo: Pérez P., Pepito) . Probar la función en una consulta contra la tabla de socios. La consulta deberá mostrar el idSocio, Nombre, Apellido1, Apellido2 y el Nombre completo y estar ordenada por este campo.
--

DELIMITER |

CREATE FUNCTION nombre_completo(nombre VARCHAR(30), apellido1 VARCHAR(20), apellido2 VARCHAR(20))
	RETURNS VARCHAR(70)
    READS SQL DATA
    BEGIN
		DECLARE nombre_completo VARCHAR(70);
        SET nombre_completo = CASE 
			WHEN LENGTH(apellido2) >= 1 THEN CONCAT(apellido1, ' ', CONCAT(LEFT(apellido2, 1), '.'), ',', ' ', nombre)
			ELSE CONCAT(apellido1, ',', ' ', nombre)
			END;
        RETURN nombre_completo;
	END
|

DELIMITER ;

SELECT id_socio AS 'ID Socio', nombre AS 'Nombre', apellido1 AS 'Primer Apellido', apellido2 AS 'Segundo Apellido', nombre_completo(nombre, apellido1, apellido2) AS 'Nombre Completo'
	FROM socio
    ORDER BY `Nombre Completo`;

--
-- Ejercicio 7. Crear una función UDF llamada IMC que permita calcular el índice de masa corporal de una persona. El índice de masa corporal (IMC) es el peso de una persona en kilogramos dividido por el cuadrado de la estatura en metros. Ejemplo: para una persona de 1,50m de estatura y 50 kg de peso, el IMC sería de 22,22. Probar la función contra los datos de la tabla seguimientos.
--

DELIMITER |

CREATE FUNCTION imc(peso DECIMAL(10, 2), estatura INT)
	RETURNS DECIMAL(10, 2)
    READS SQL DATA
    BEGIN
		DECLARE imc DECIMAL(10, 2);
		SET imc = ROUND((peso / POWER((estatura / 100), 2)), 2);
        RETURN imc;
	END
|

DELIMITER ;

SELECT DISTINCT id_socio AS 'ID Socio', estatura_cm AS 'Estatura en cm', peso AS 'Peso en Kg', imc(peso, estatura_cm) AS 'IMC'
	FROM seguimiento
    ORDER BY id_socio;

--
-- Ejercicio 8. Crear una función UDF llamada regalosAniversario que se aplicará a los socios del gimnasio cuyo mes de Alta en el gimnasio coincida con el mes en curso. Para ello, se seguirán los siguientes criterios. Hacer la consulta pertinente para probar la función.
--

DELIMITER |

CREATE FUNCTION regalos_aniversario (tipo_socio VARCHAR(30), alta DATE)
	RETURNS VARCHAR(100) 
    READS SQL DATA
    BEGIN
		DECLARE bono VARCHAR(100);
        SET bono = CASE
			WHEN (MONTH(alta) = MONTH(CURDATE())) AND tipo_socio = 'Corporativo' THEN '-'
            WHEN (MONTH(alta) = MONTH(CURDATE())) AND tipo_socio = 'Principal' THEN 'Tarjeta de regalo de 40€ en tiendas de suplementos deportivos'
            WHEN (MONTH(alta) = MONTH(CURDATE())) AND tipo_socio = 'Beneficiario' THEN 'Tarjeta de regalo de 10€ en tiendas de suplementos deportivos'
            ELSE 'No es su aniversario'
			END;
		RETURN bono;
    END
|    

DELIMITER ;

SELECT s.id_socio AS 'ID Socio', nombre_completo(nombre, apellido1, apellido2) AS 'Nombre Completo', (SELECT `Tipo de Socio` 
	FROM v_tipo_socio v WHERE s.id_socio = v.id_socio) AS 'Tipo de Socio', regalos_aniversario((SELECT `Tipo de Socio` 
	FROM v_tipo_socio v WHERE s.id_socio = v.id_socio), fecha_alta) AS 'Criterio Bono'
FROM socio s
ORDER BY id_socio;

--
-- Ejercicio 9. Inventar una función UDF que se considere útil para las operaciones del Gimnasio. Explicarla y justificarla en los comentarios de la plantilla .sql
--

DELIMITER |

CREATE FUNCTION buscar_altas_validas(anio int)
	RETURNS INT
    READS SQL DATA
    BEGIN
		DECLARE total_altas INT;
        SET total_altas = IF((SELECT YEAR(fecha_alta) 
			FROM socio 
			WHERE YEAR(fecha_alta) = (anio - 1)
            GROUP BY YEAR(fecha_alta)) IS NULL, NULL, (SELECT COUNT(id_socio)
				FROM socio
				WHERE YEAR(fecha_alta) = (anio - 1)));
        WHILE total_altas IS NULL DO
			SET anio = anio - 1;
            SET total_altas = (SELECT COUNT(id_socio)
				FROM socio
				WHERE YEAR(fecha_alta) = (anio - 1));
		END WHILE;
	RETURN total_altas;
	END;
|

CREATE FUNCTION crecimiento_anual_socios(anio INT)
	RETURNS DECIMAL(10, 2)
    READS SQL DATA
    BEGIN
		DECLARE porcentaje_crecimiento DECIMAL(10, 2);
        DECLARE num_altas_anual INT;
        DECLARE num_altas_anterior INT;
        SET num_altas_anual = (SELECT COUNT(id_socio)
			FROM socio 
			WHERE YEAR(fecha_alta) = anio);
		SET num_altas_anterior = IF(anio = (SELECT MIN(YEAR(fecha_alta))
			FROM socio), 0, (SELECT buscar_altas_validas(anio)));
		SET porcentaje_crecimiento = CASE WHEN (anio = (SELECT MIN(YEAR(fecha_alta))
			FROM socio)) THEN 0.00
            ELSE (((num_altas_anterior - num_altas_anual) / num_altas_anterior) * 100) * -1
        END;
    RETURN porcentaje_crecimiento;
    END
|

DELIMITER ;

SELECT YEAR(fecha_alta) 'Año', COUNT(id_socio) AS 'Total de Altas Anuales', 
	crecimiento_anual_socios(YEAR(fecha_alta)) AS '% de Crecimiento Anual'
	FROM socio
    GROUP BY YEAR(fecha_alta)
    ORDER BY YEAR(fecha_alta) ASC;

-- Variable de @usuario

--
-- Ejercicio 10. Crear una variable de usuario denominada @nivel. Asignar un valor a la misma entre los niveles que tienen las actividades del gimnasio. Usar la variable @nivel para filtrar las actividades que pertenezcan a ese nivel.
--

SET @nivel = 'Intermedio';

SELECT id_actividad AS 'ID Actividad', actividad AS 'Nombre', descripcion AS 'Descripción', dirigida_a AS 'Dirigida a', duracion_sesion_minutos AS 'Duración en min', nivel AS 'Nivel'
	FROM actividad
    WHERE nivel = @nivel
    ORDER BY id_actividad;
    
--
-- Ejercicio 11. Crear una consulta que guarde en dos variables denominadas @numeroSocios y @EstimadoFacturacion el total de socios corporativos y el estimado de facturación para los mismos.
--

SET @numero_socios = (SELECT SUM(bf.`Numero Afiliados`) 
	FROM Base_Facturacion bf 
    JOIN empresa e
    ON (e.nif = bf.`NIF/DNI`)
    WHERE bf.`ID Plan` in (7, 8)), 
    @estimado_facturacion = ROUND((SELECT SUM(`Importe Total`) 
		FROM Base_Facturacion WHERE `ID Plan` IN (7, 8)), 2);

-- Comprobamos 

SELECT @numero_socios AS 'Número de Socios Corporativos', @estimado_facturacion AS 'Estimado Facturacion';

--
-- Ejercicio 12. Crear una consulta agrupada que muestre los siguientes datos. Realizar el cálculo de porcentaje sobre las variables guardadas en el punto anterior
--

SELECT e.empresa AS 'Nombre Empresa', e.nif AS 'NIF', SUM(bf.`Numero Afiliados`) AS 'Afiliados',
	ROUND((SUM(bf.`Numero Afiliados`) / @numero_socios) * 100, 0) AS '% sobre socios corporativos',
    ROUND(SUM(bf.`Importe Total`), 2) AS 'Estimado Facturación',
    ROUND((SUM(bf.`Importe Total`) / @estimado_facturacion) * 100, 0) AS '% sobre Total Estimado'
FROM empresa e
INNER JOIN Base_Facturacion bf
ON (bf.`NIF/DNI` = e.nif)
GROUP BY e.nif;
-- --------------------
DELIMITER |

CREATE FUNCTION contar_socios_corporativos(nif_empresa VARCHAR(15))
	RETURNS INT
    READS SQL DATA
    BEGIN
		DECLARE total_socios INT;
        SET total_socios = (SELECT COUNT(c.id_socio)
			FROM empresa e
			LEFT JOIN corporativo c	
				ON(c.nif = e.nif)
			WHERE (e.nif = nif_empresa)
			GROUP BY empresa); 
		RETURN total_socios;
	END
|
    
DELIMITER ;
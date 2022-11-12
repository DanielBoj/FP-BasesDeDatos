-- PLANTILLA DE ENTREGA DE LA PARTE PRÁCTICA DE LAS ACTIVIDADES
-- --------------------------------------------------------------
-- Actividad: FP.046_PRODUCTO2
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

--
-- Pasos previos
--

-- Creación de índices

START TRANSACTION;

ALTER TABLE beneficiario
	ADD UNIQUE INDEX beneficiario_id_socio (id_socio),
    ADD UNIQUE INDEX beneficiario_id_beneficiario (id_beneficiario);
/* Los necesitaremos para agilizar y evitar duplicados */

-- Combinaciones Externas

--
-- Ejercicio 1. Mostrar aquellos socios corporativos que no se han inscrito en ninguna actividad. El listado deberá mostrar los siguientes campos: idSocio, Nombre, 
-- Apellido1, Nombre del Plan.
--

SELECT  c.id_socio AS 'ID Socio', s.nombre AS 'Nombre', s.apellido1 as "Apellido", p.plan as "Nombre del Plan" 
	FROM corporativo c
	LEFT JOIN inscripcion i 
        ON c.id_socio = i.id_socio
	INNER JOIN socio s 
        ON s.id_socio=c.id_socio
	INNER JOIN plan p 
        ON p.id_plan=s.id_plan
	WHERE i.id_socio IS NULL;
/* Realizaremos una consulta sobre varias tablas usando la cláusula JOIN:
* 1. Usamos como tabla principal  "corporativo" donde obtendremos el id_socio para realizar el filtrado.
* 2. Usamos un LEFT JOIN con "inscripcion" que retorne todos los valores, coincidentes y no, y los filtramos mediante la cláusula WHERE para obtener solo 
* aquellos socios que no aparecen en la tabla "inscripcion".
* 3. Usamos JOINS con "socio" y "plan" para obtener los valores de los campos de la consulta. */
    
--
-- Ejercicio 2. Mostrar un listado de socios a los cuales no se les haya registrado cambios desde que se registraron en el gimnasio (no aparecen en la tabla histórico) 
-- ordenados por idPlan y Fecha Alta.
-- El listado deberá mostrar los siguientes campos: idSocio, Nombre, Apellido1, Nombre del Plan.
--

SELECT  s.id_socio AS 'ID Socio', s.nombre AS 'Nombre', s.apellido1 AS "Apellido", p.plan AS "Nombre del Plan" 
	FROM socio s
	LEFT JOIN historico h 
		ON s.id_socio = h.id_socio
	INNER JOIN plan p 
		ON p.id_plan = s.id_plan 
	WHERE h.id_socio IS NULL
	ORDER BY p.id_plan, s.fecha_alta;
/* Realizamos una consulta cobre varias tablas con la cláusula JOIN:
* 1. Usamos como tabla principal "socio" y realizamos un INNNER JOIN con plan para obtener los valores de los campos de la consulta y el id_socio para
* los filtrados.
* 2. Mediante un LEFt JOIN con "historico" buscamos todos los valores y los filtramos escogiendo aquellos socios que no estén presentes
* en la tabla "historico".
* 3. Ordenamos por plan y fecha de alta. */
    
--
-- Ejercicio 3. Mostrar un listado de socios no corporativos a los cuales no se les haya realizado ningún seguimiento, ordenado por tipo de socio 
-- (principal y beneficiarios). 
-- El listado deberá mostrar los siguientes campos: idSocio, Nombre, Apellido1, Días de Alta en el Gimnasio.
--

SELECT sc.id_socio AS 'ID Socio', sc.nombre AS 'Nombre', sc.apellido1 AS 'Apellido', 
	IF (sc.activo = 1, (DATEDIFF(CURDATE(), sc.fecha_alta)), DATEDIFF(h.fecha_cambio, sc.fecha_alta)) AS 'Días de Alta en el Gimnasio'
	FROM socio sc 
    INNER JOIN plan p 
		ON (p.id_plan = sc.id_plan)
    LEFT JOIN seguimiento sg
		ON (sg.id_socio = sc.id_socio)
	LEFT JOIN historico h 
		ON (h.id_socio = sc.id_socio)
	WHERE p.tipo = 'P' AND sg.id_socio IS NULL
	ORDER BY  (
		SELECT IF (s.id_socio IN (b.id_socio), 'Beneficiario', 'Principal')
		FROM socio s
		LEFT JOIN beneficiario b
		ON (b.id_socio = s.id_socio)
        WHERE (s.id_socio = sc.id_socio)) DESC, sc.id_socio;
/* Importante: Esta consulta diferencia entre los socios que están de alta y los que han cursado baja; para los primeros,
* muestro los dñias totales que llevan dados de alta; de los segundos, muestra los días que estuvieron dados de alta, es decir,
* los días entre la fecha de alta y la fecha de baja. 
* Usamos una consulta sobre varias tablas con la cláusula JOIN y una SUBCONSULTA para ordenar la consulta:
* 1. Usamos como tabla principal "socio" de dibde obtenemos los valores de los campos y el id_socio para el filtrado.
* 2. Mediante un INNE JOIN con "plan" podremos filtrar a los socios no corporativos ya que tienen un tipo de plan P.
* 3. Usamos un LEFT JOIN con "seguimiento" para poder obtener todos los valores de la tabla y usarlos para escoger, en la
* cláusula WHWERE solo aquellos socios que no aparezcan en "seguimiento".
* 4. Usamos un LEFT JOIN con "historico" para poder obtener la fecha de baja de los usuarios que han cursado baja.
* 5. Para obtener el número de días que ha estado de alta un socio, usamos una función IF() para diferenciar entre socios activos
* y los que han cursado baja, si están activos, contamos los días desde el alta hasta la fecha actual, pero si se han dado de baja,
* contamos los días entre la fecha de alta y la fecha de baja.
* 6. Ordenamos la consulta mediante una SUBCONSULTA que diferencia entre los socios Principales y los socios Beneficiarios. Usa 
* también una función IF() para obtener el patrón de ordenamiento, luego ordenamos en segundo nivel por el id de socio. */
        
-- Subconsultas

--
-- Ejercicio 4. Mostrar el idSocio, nombre, apellido1, apellido2 y la fecha de alta del socio más antiguo del gimnasio.
--
SELECT  id_socio AS 'ID Socio', nombre 'Nombre', CONCAT(apellido1, ' ', apellido2) AS 'Apellidos', fecha_alta AS "Fecha de Alta"
	FROM socio
	WHERE fecha_alta = (
		SELECT min(fecha_alta) 
        FROM socio);
/* Usamos una SUBCONSULTA dentro de la cláusula WHERE para establecer una condición que compare la fecha de alta de cada socio con la fecha 
* de alta menor de la tabla socio, para ello usaremos la funcion MIN() sobre la columna fecha de alta. De este modo, la consulta nos devuelve 
* una única fila, la más antigua. */

--
-- Ejercicio 5. Mostrar todos los datos de la Empresa que firmó el último convenio con el gimnasio.
--

SELECT * 
	FROM  empresa 
    WHERE fecha_inicio_convenio = (
		SELECT MAX(fecha_inicio_convenio) 
        FROM empresa);
/* Deberemos usar una SUBCONSULTA a la izquierda de la comparación de la cláusula WHERE que compare las fechas de inicio de convenio de cada 
* empresa con la fecha del convenio más reciente que obtenemos aplicando la función MAX() a la columna fecha_inicio_convenio */
        
--
-- Ejercicio 6. Mostrar el id, nombre y apellidos de aquellos socios con IMC más bajo que el mejor IMC del socio que esté inscrito en el Plan id=3. 
-- Mostrar en la consulta el mejor IMC.
--

-- IMPORTANTE: Consulta calculando el IMC no usando el % de grasa corporal

SELECT s.id_socio 'ID Socio', s.nombre AS 'Nombre', CONCAT(s.apellido1, ' ', s.apellido2) AS 'Apellidos', MIN((sg.peso / POWER((sg.estatura_cm / 100), 2))) AS 'Mejor IMC'
	FROM socio s
	INNER JOIN seguimiento sg
	    ON (sg.id_socio = s.id_socio)
	WHERE (peso / POWER((estatura_cm / 100), 2)) < (
		SELECT MIN((sgm.peso / POWER((sgm.estatura_cm / 100), 2))) AS IMC
			FROM seguimiento sgm
            INNER JOIN socio sco
            ON (sco.id_socio = sgm.id_socio)
			WHERE (sco.id_plan = 3))
	GROUP BY s.id_socio
     ORDER BY `Mejor IMC`;
/* Esta consulta se basa en el cálculo del IMC de los socios usando la fórmula IMC = kg / m al cuadrado. Obtiene el mejor IMC, es decir el más bajo,
* de entre los socios del plan 3 y lo compara con los socios que tienen seguimiento devolviendo aquellos socios con menor IMC y escogiendo de estos
* el mejor IMC personal de los diferentes seguimientos que tienen. 
* Para realizar este ejercicio debemos usar JOIN, SUBCONSULTAS y funciones:
* 1. Seleccionamos el menor IMC de los usuarios mediante la función MIN() en la que seleccionaremos las columnas peso y estatura_cm para realizar el cálculo del IMC.
* 2. Usamos "socio" como tabla principal para obtener los datos: id_socio, nombre y apellidos, peso y estatura y el id_socio que usaremos para filtrar.
* 3. Usamos un INNER JOIN con la tabla "seguimiento" para filtrar únicamente a los socios que tengan un seguimiento realizado.
* 4. Usamos un filtrado del retorno mediante WHERE donde, a la izquierda de la comparación colocamos el IMC del usuario actualmente consultado y a la derecha 
* una SUBCONSULTA que nos devuelve el mejor IMC de los usuarios en el plan 3.
* 5. Para esta SUBCONSULTA obtenemos el IMC como columna virtual que devolveremos y filtramos, mediante un JOIN para unir los datos de la tabla principal "socio" con la 
* tabla hija "seguimiento" y mediante la cláusula WHERE para limitarlo a usuarios del plan 3. Mediante la función MIN() obtendremos únicamente el mejor IMC. */

/* Añadimos también, manteniéndolo comentadp el cálculo con el campo porcentaje de grasa corporal por si fuera eso lo que quería solicitar el ejercico */
/* SELECT DISTINCT a.id_socio,a.nombre,a.apellido1, a.apellido2,b.porcentaje_grasa_corporal 
	FROM socio a
	INNER JOIN seguimiento b 
		ON b.id_socio=a.id_socio
		WHERE b.porcentaje_grasa_corporal  <  (
        SELECT  max(c.porcentaje_grasa_corporal) FROM seguimiento c 
			INNER JOIN socio d 
            ON  d.id_socio=c.id_socio 
            WHERE d.id_plan=3); */

-- Consultas UNION

-- Consultas previas al uso de clásulas UNION

--
-- Ejercico 7. Generar una consulta resumen que tenga como campos los siguientes:
-- NIF (empresa), Nombre Empresa, Teléfono, idPlan, nombre del Plan, Número Afiliados, Cuota Mensual por Afiliado (de la tabla Plan), Importe Total.
--

SELECT e.nif As 'NIF', e.empresa AS 'Nombre Empresa', e.telefono AS 'Teléfono', s.id_plan AS 'ID Plan', p.plan As 'Nombre Plan', 
COUNT(s.id_socio) AS "Numero Afiliados", p.cuota_mensual, (COUNT(s.id_socio) * p.cuota_mensual) AS "Importe Total" 
	FROM empresa e
	LEFT JOIN corporativo sc
		ON sc.nif = e.nif
	LEFT JOIN socio s
		ON s.id_socio = sc.id_socio
	LEFT JOIN plan p
		ON s.id_plan = p.id_plan
	GROUP BY e.nif, p.id_plan;
/* Usamos una consulta sobre varias tablas mediante la cláusula JOIN:
* 1. Usamos como tabla principal "empresa" de donde obtendremos varios valores de campos a retornar y el nif para filtrar los socios corporativos
* asociados a cada empresa.
* 2. Usamos varios LEFT JOIN, con las tabla "corporativo" para obtener los socios de cada empresa, con la tabla "socio" y con la tabla "plan" para
* poder obtener los valores necesarios para calcular los importes.
* 3. Con la función COUNT() obtenemos el total de socios afiliados a cada empresa y divididos por planes, para ello dependemos d ela cláusula GROUP BY.
*. Usando la misma función y multiplicando por el valor de la cuota mensual que obtenemos d ela tabla "plan", sabemos el total mensualq ue paga cada
* empresa. */

--
-- Ejercicio 8. Generar otra consulta resumen que tenga como campos los siguientes:
-- Documento Identidad (socio), Nombres y Apellidos del Socio (en una sola columna), Teléfono, idPlan, nombre del Plan, Número Afiliados 
-- (el socio principal + sus beneficiarios), Cuota Mensual  (de la tabla Plan), Importe Total.
--

SELECT s.documento_identidad AS 'Documento Identidad', CONCAT_WS(' ', s.nombre, s.apellido1, s.apellido2) AS 'Nombres y Apellidos del Socio', s.telefono_contacto AS 'Teléfono', 
	s.id_plan AS 'ID Plan', p.plan AS 'Nombre del Plan', IFNULL((
    SELECT COUNT(bf.id_beneficiario) + 1
		FROM beneficiario bf
        WHERE bf.id_socio_principal_referencia = s.id_socio
		GROUP BY bf.id_socio_principal_referencia), IF (s.id_socio IN (SELECT id_socio FROM beneficiario), 0, 1)) AS 'Número de Afiliados', p.cuota_mensual AS 'Cuota Mensual', (
    SELECT IF (s.id_socio NOT IN (SELECT id_socio FROM beneficiario) AND s.id_socio NOT IN (SELECT id_socio FROM corporativo), IFNULL(p.cuota_mensual + (
		SELECT SUM(pl.cuota_mensual - (pl.cuota_mensual * (bf.porcentaje_descuento / 100)))
			FROM plan pl
			JOIN socio sc
			    ON (sc.id_plan = pl.id_plan)
			JOIN beneficiario bf
			    ON (bf.id_socio = sc.id_socio)
			WHERE s.id_socio = id_socio_principal_referencia
			GROUP BY id_socio_principal_referencia), cuota_mensual), 0)
		FROM socio sco
		JOIN plan p 
		    ON(sco.id_plan = p.id_plan)
        WHERE s.id_socio = sco.id_socio
		ORDER by s.id_socio) AS 'Importe Total'
	FROM socio s
    INNER JOIN plan p
        ON (s.id_plan = p.id_plan)
    LEFT JOIN beneficiario b
        ON (s.id_socio = b.id_socio_principal_referencia)
    ORDER BY s.id_socio;
/* En esta consulta, tras la conversación con la consultora, el resultado suma la cuota del socio principal + la de los socios beneficiarios, pero si es beneficiario o 
* corporativo lo deja a 0, porque se entiende que su cuota la pagan los socios principales o las empresas a los que están relacionados, pero mantiene el precio de la 
* cuota mensual de los socios beneficiarios en la columna 'Cuota Mensual' para conocer el valor de la cuota del plan al que están asociados.
* 1. Como en los casos anteriores, usamos cláusulas JOIN para relacionar los datos d evarias tablas, teniendo como tabla principal "socio" de donde obtenemos
* el valor de id_socio que usamos como filtro. 
* 2. Usamos varias subconsultas para realizar los cálculos del número de afiliados (Principal + Beneficiarios si los hay) y del importe total, en este último caso
* usamos también JOIN para poder obtener los datos que necesitamos para calcular los descuentos que se aplican a los socios beneficiarios y relacionar cada socio con
* la cuota mensual de su plan.
* 3. Mediante las funciones IF() podemos escoger para mostrar unos resultados u otros, o relaizar unas operaciones u otras. Con IFNULL() nos aseguramos de que la 
* operación de cálculod e cuota mensual no arroje un error si no hay socios beneficiarios. */
    
--
-- Ejercico 9. Crea una consulta de UNION con los datos de las dos consultas anteriores.
--

SELECT e.nif AS 'NIF/DNI', e.empresa AS 'Nombre', e.telefono As 'Teléfono', s.id_plan As 'ID Plan', plan AS 'Nombre del Plan', 
COUNT(s.id_socio) AS "Numero Afiliados", p.cuota_mensual AS 'Cuota Mensual por Afiliado', ( COUNT(s.id_socio) * p.cuota_mensual ) AS "Importe Total" 
	FROM empresa e
	LEFT JOIN corporativo sc
		ON sc.nif = e.nif
	LEFT JOIN socio s
		ON s.id_socio = sc.id_socio
	LEFT JOIN plan p
		ON s.id_plan = p.id_plan
	GROUP BY e.nif, p.id_plan	
UNION
SELECT s.documento_identidad, CONCAT_WS(' ', s.nombre, s.apellido1, s.apellido2), s.telefono_contacto, s.id_plan, p.plan, IFNULL((
    SELECT COUNT(bf.id_beneficiario) + 1
		FROM beneficiario bf
        WHERE bf.id_socio_principal_referencia = s.id_socio
		GROUP BY bf.id_socio_principal_referencia), IF (s.id_socio IN (SELECT id_socio FROM beneficiario), 0, 1)), p.cuota_mensual, (
    SELECT IF (s.id_socio NOT IN (SELECT id_socio FROM beneficiario) AND s.id_socio NOT IN (SELECT id_socio FROM corporativo), IFNULL(p.cuota_mensual + (
		SELECT SUM(pl.cuota_mensual - (pl.cuota_mensual * (bf.porcentaje_descuento / 100)))
			FROM plan pl
			JOIN socio sc
			ON (sc.id_plan = pl.id_plan)
			JOIN beneficiario bf
			ON (bf.id_socio = sc.id_socio)
			WHERE s.id_socio = id_socio_principal_referencia
			GROUP BY id_socio_principal_referencia), cuota_mensual), 0)
		FROM socio sco
		JOIN plan p 
		ON(sco.id_plan = p.id_plan)
        WHERE s.id_socio = sco.id_socio
		ORDER by s.id_socio)
	FROM socio s
    INNER JOIN plan p
		ON (s.id_plan = p.id_plan)
    LEFT JOIN beneficiario b
		ON (s.id_socio = b.id_socio_principal_referencia)
	GROUP BY s.id_socio;
    /* Usamos UNION para unir las dos consultas, debemos tener en cosideración que deben haber el mismo número de columnas y cada columna
    * coincidente debe tener tipos de datos iguales o compatibles. Además, usarán los alias de la primera consulta. */
    
    --
-- Ejercicio 10. Crea una consulta de UNION que muestre TODAS las actividades del Gimnasio, La consulta deberá tener los siguientes campos:
-- idActividad, Actividad, tipo (Dirigida/Extra), matrícula (si es dirigida mostrar 0, de lo contrario, mostrar el precio de la matrícula), 
-- precio mensual (si es dirigida mostrar 0, de lo contrario, mostrar el precio), porcentaje de descuento abonados (si es dirigida mostrar 0, de lo contrario, mostrar el precio).
--
 
-- Añadimos los registros a las tablas dirigida y extra

START TRANSACTION;
    
INSERT INTO dirigida (id_actividad, resistencia, fuerza, velocidad, coordinacion, flexibilidad, equilibrio, agilidad) VALUES
	(1, 1, 0, 0, 1, 1, 1, 1),
	(2, 1, 0, 0, 1, 0, 1, 1),
	(3, 1, 0, 0, 1, 0, 1, 1),
	(4, 1, 1, 0, 1, 0, 1, 0),
	(5, 1, 1, 0, 1, 0, 0, 0),
    (6, 1, 1, 0, 0, 0, 0, 0),
	(7, 1, 0, 0, 0, 0, 0, 0),
	(8, 0, 1, 0, 1, 1, 1, 0),
	(9, 1, 1, 0, 0, 0, 0, 0),
	(10, 0, 1, 0, 0, 0, 0, 0),
    (11, 1, 1, 1, 1, 0, 0, 0),
    (12, 1, 1, 1, 1, 0, 0, 0),
    (13, 1, 1, 1, 1, 0, 0, 0),
    (14, 0, 1, 0, 0, 1, 0, 0),
    (15, 1, 0, 0, 1, 0, 1, 1),
    (16, 0, 0, 0, 1, 1, 0, 0),
    (17, 0, 0, 0, 1, 1, 1, 1),
    (18, 1, 1, 1, 1, 0, 0, 1),
    (19, 1, 1, 1, 1, 1, 0, 0),
    (20, 1, 0, 0, 1, 1, 1, 0),
    (21, 0, 0, 0, 1, 0, 0, 1);
    
COMMIT;
    
START TRANSACTION;
    
INSERT INTO extra (id_Actividad, clases_semanales, matricula, mensualidad, descuento_abonados) VALUES
	(1, 4, 20.00, 15.00, 10),
	(2, 3, 15.00, 10.00, 5),
	(3, 2, 30.00, 20.00, 20),
	(4, 5, 15.00, 10.00, 5),
	(5, 4, 25.00, 15.00, 10),
	(6, 4, 20.00, 15.00, 10),
	(7, 3, 15.00, 10.00, 5),
	(8, 2, 30.00, 20.00, 20),
	(9, 5, 15.00, 10.00, 5),
	(10, 4, 25.00, 15.00, 10),
	(11, 5, 30.00, 20.00, 25),
	(12, 5, 10.00, 5.00, 5),
	(13, 5, 20.00, 10.00, 10),
	(14, 3, 25.00, 15.00, 10),
	(15, 4, 20.00, 10.00, 5),
	(16, 5, 15.00, 10.00, 0),
	(17, 2, 25.00, 15.00, 10),
	(18, 3, 40.00, 30.00, 20),
	(19, 4, 40.00, 30.00, 20),
	(20, 2, 35.00, 20.00, 15);

SELECT a.id_actividad AS 'ID Actividad', a.actividad AS 'Nombre', 
	IF(a.id_actividad IN (SELECT id_actividad FROM dirigida), 'DIRIGIDA', null) AS 'Tipo', 
    IF(a.id_actividad IN (SELECT id_actividad FROM dirigida), 0, null)  AS 'Matrícula', 
    IF(a.id_actividad IN (SELECT id_actividad FROM dirigida), 0, null) AS 'Precio Mensual', 
    IF(a.id_actividad IN (SELECT id_actividad FROM dirigida), 0, null) AS 'Mensualidad con Porcentaje Descuento Abonados'
    FROM actividad a
    INNER JOIN dirigida d
        ON (d.id_actividad = a.id_actividad)
UNION ALL
SELECT a.id_actividad AS 'ID Actividad', a.actividad AS 'Nombre', 
	IF(a.id_actividad IN (SELECT id_actividad FROM extra), 'EXTRA', null)  AS 'Tipo',  
    IF(a.id_actividad IN (SELECT id_actividad FROM extra), matricula, 0)  AS 'Matrícula', 
    IF(a.id_actividad IN (SELECT id_actividad FROM extra), mensualidad, 0) AS 'Precio Mensual', 
    IF(a.id_actividad IN (SELECT id_actividad FROM extra), (e.mensualidad - (e.mensualidad * (e.descuento_abonados / 100))), 0) AS 'Mensualidad con Porcentaje Descuento Abonados'
    FROM actividad a
    INNER JOIN extra e
        ON (e.id_actividad = a.id_actividad)
    ORDER BY `ID Actividad`;
/* Esta tabla, siguiendo la consulta realizada a la tutora, en "Mensualidad con Porcentaje Descuento Abonados", como en la descripción interna del ejercicio solicita mostrar
* precio, se calcula la mensualidad aplicando el descuento por socio beneficiario.
* 1. La consulta usa las funciones IF() para escoger ente el valor por defecto o los diferentes valores que obtenemos de las tablas relacionadas mediante el JOIN
* entre la tabla principal "actividad" que es una tabla padre y las tablas hijas extra o dirigida.
* 2. Se usan subconsultas para diferenciar, dentro de los IF(), si la actividad esta dentro de la tabla "extra" o dentro de la tabla "dirigida",
* 3. Capturamos el id_actividad de la tabla "actividad" para usar como filtro.
* 4. Usamos UNION para unir las dos consultas, debemos tener en cosideración que deben haber el mismo número de columnas y cada columna
* coincidente debe tener tipos de datos iguales o compatibles. Además, usarán los alias de la primera consulta.
*/
    
--
-- Ejercicio 11. Crea una vista a la cual llamarás Base_Facturacion  y que guardará la consulta de UNIÓN del punto 9.
--

CREATE OR REPLACE VIEW Base_Facturacion
	AS SELECT e.nif AS 'NIF/DNI', e.empresa AS 'Nombre', e.telefono As 'Teléfono', s.id_plan As 'ID Plan', plan AS 'Nombre del Plan', 
COUNT(s.id_socio) AS "Numero Afiliados", p.cuota_mensual AS 'Cuota Mensual por Afiliado', ( COUNT(s.id_socio) * p.cuota_mensual ) AS "Importe Total" 
	FROM empresa e
	LEFT JOIN corporativo sc
		ON sc.nif = e.nif
	LEFT JOIN socio s
		ON s.id_socio = sc.id_socio
	LEFT JOIN plan p
		ON s.id_plan = p.id_plan
	GROUP BY e.nif, p.id_plan	
UNION
SELECT s.documento_identidad, CONCAT_WS(' ', s.nombre, s.apellido1, s.apellido2), s.telefono_contacto, s.id_plan, p.plan, IFNULL((
    SELECT COUNT(bf.id_beneficiario) + 1
		FROM beneficiario bf
        WHERE bf.id_socio_principal_referencia = s.id_socio
		GROUP BY bf.id_socio_principal_referencia), IF (s.id_socio IN (SELECT id_socio FROM beneficiario), 0, 1)), p.cuota_mensual, (
    SELECT IF (s.id_socio NOT IN (SELECT id_socio FROM beneficiario) AND s.id_socio NOT IN (SELECT id_socio FROM corporativo), IFNULL(p.cuota_mensual + (
		SELECT SUM(pl.cuota_mensual - (pl.cuota_mensual * (bf.porcentaje_descuento / 100)))
			FROM plan pl
			JOIN socio sc
			ON (sc.id_plan = pl.id_plan)
			JOIN beneficiario bf
			ON (bf.id_socio = sc.id_socio)
			WHERE s.id_socio = id_socio_principal_referencia
			GROUP BY id_socio_principal_referencia), cuota_mensual), 0)
		FROM socio sco
		JOIN plan p 
		ON(sco.id_plan = p.id_plan)
        WHERE s.id_socio = sco.id_socio
		ORDER by s.id_socio)
	FROM socio s
    INNER JOIN plan p
		ON (s.id_plan = p.id_plan)
    LEFT JOIN beneficiario b
		ON (s.id_socio = b.id_socio_principal_referencia)
	GROUP BY s.id_socio;
    
 -- Comprobamos
 
SELECT * FROM Base_facturacion;
/* Para crear una vista usamos la cláusula CREATE [OR REPLACE] VIEW, en este caso añadimos la consulta UNION que habíamos creado en ell ejercicio
9 y comprobamos que funcione. */

--
-- Ejercicio 12. Crea una vista a la cual llamarás Actividades_Gym  y que guardará la consulta de UNIÓN del punto 10.
--

CREATE OR REPLACE VIEW Actividades_Gym
	AS SELECT a.id_actividad, a.actividad, 
		IF(a.id_actividad IN (SELECT id_actividad FROM dirigida), 'DIRIGIDA', null) AS 'Tipo', 
		IF(a.id_actividad IN (SELECT id_actividad FROM dirigida), 0, null)  AS 'Matrícula', 
		IF(a.id_actividad IN (SELECT id_actividad FROM dirigida), 0, null) AS 'Precio Mensual', 
		IF(a.id_actividad IN (SELECT id_actividad FROM dirigida), 0, null) AS 'Mensualidad con Porcentaje Descuento Abonados'
		FROM actividad a
		JOIN dirigida d
		ON (d.id_actividad = a.id_actividad)
	UNION ALL
	SELECT a.id_actividad, a.actividad, 
		IF(a.id_actividad IN (SELECT id_actividad FROM extra), 'EXTRA', null)  AS 'Tipo',  
		IF(a.id_actividad IN (SELECT id_actividad FROM extra), matricula, 0)  AS 'Matrícula', 
		IF(a.id_actividad IN (SELECT id_actividad FROM extra), mensualidad, 0) AS 'Precio Mensual', 
		IF(a.id_actividad IN (SELECT id_actividad FROM extra), (e.mensualidad - (e.mensualidad * (e.descuento_abonados / 100))), 0) AS 'Mensualidad con Porcentaje Descuento Abonados'
		FROM actividad a
		JOIN extra e
		ON (e.id_actividad = a.id_actividad)
		ORDER BY id_actividad;

-- Comprobamos

SELECT * FROM Actividades_Gym;
/* Para crear una vista usamos la cláusula CREATE [OR REPLACE] VIEW, en este caso añadimos la consulta UNION que habíamos creado en ell ejercicio
10 y comprobamos que funcione. */

--
-- Ejercicio 13. Crea una vista a la cual llamarás Socios_Planes que guardará los siguientes campos: idPlan, Nombre Plan, Total_Socios.
--

CREATE OR REPLACE VIEW Socios_Planes AS
	SELECT p.id_plan AS 'ID Plan', p.plan AS 'Nombre Plan', COUNT(s.id_socio) AS 'Total Socios'
	FROM plan p
	LEFT JOIN socio s
		ON p.id_plan = s.id_plan
	GROUP BY p.id_plan;

-- Comprobamos

SELECT * FROM Socios_Planes;
/* Para crear esta vista, usamos la cláusula CREATE VIEW y creamos una consulta que retorna los diferentes planes y cuantos miembros hay afiliados
a cada plan.
* 1. Relacionamos las tablas "plan" y "socio" mediante el id_plan, así conocemos a qué plan está afiliado cada socio.
* 2. Usamos un LEFT JOIN porque también necesitamos los datos de los planes que no tengan ningún socio afiliado. 
* 3. Mediante la función COUNT() contamos los socios que hay afiliados ha cada plan. */

--
-- Ejercicio 14. Crea una vista a la cual llamarás Socios_Totales que guardará el número total de socios del gimnasio.
--

CREATE OR REPLACE VIEW Socios_Totales AS
	SELECT COUNT(id_socio) AS 'Socios Totales'
	FROM socio;
/* Para crear esta vista, usamos la cláusula CREATE VIEW y creamos una consulta que retorna los diferentes planes y cuantos miembros hay afiliados
a cada plan.
* 1. Usamos la función COUNT() para conocer el número de registros totales de la tabla "socio"*/
    
--
-- Ejercicio 15. Haciendo uso de las dos vistas anteriores, crea una consulta que muestre el % de socios de cada plan respecto de 
-- los socios totales del gimnasio, ordenada por el porcentaje calculado de mayor a menor.
--

SELECT sp.`ID Plan`, sp.`Nombre Plan`, ROUND((sp.`Total Socios` / (SELECT * FROM Socios_Totales)) * 100) AS 'Porcentaje de Socios'
	FROM Socios_Planes sp
	ORDER BY `Porcentaje de Socios` DESC;

/* Esta consulta devuelve el tanto porciento que representan los afiliados de cada plan sobre el número de socios totales, se ha REDONDEADO
* el resultado para facilitar su legibilidad.
* 1. Utilizamos LITERALES para seleccionar las columnas que queremos devolver de la vista.
* 2. Accedemos a la Vista mediante un SELECT indicando el nombre de la vista tras la cláusula FROM.
* 3. Podemos usar alias para la vista como en las tablas reales.
* 4. Ordenamos los resultados de forma descendente según el porcentaje representado. */
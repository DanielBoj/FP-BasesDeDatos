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

-- Generamos algunas Vistas para facilitar la legibilidad del código

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
            
CREATE OR REPLACE VIEW v_num_planes_corporativos AS
	SELECT p.id_plan
		FROM plan p
		JOIN socio s
			ON (s.id_plan = p.id_plan)
		JOIN v_tipo_socio vts
			ON (vts.id_socio = s.id_socio)
	WHERE vts.`Tipo de Socio` = 'Corporativo'
	GROUP BY id_plan;

-- Funciones condicionales

--
-- Ejercicio 1. Mostrar aquellos socios que cumplen años en el mes en curso.
--

SELECT id_socio as 'ID Socio', CONCAT_WS(' ', nombre, apellido1) AS 'Nombre', email AS 'Email', 
fecha_nacimiento AS 'Fecha de Nacimiento', 
IF(MONTH(fecha_nacimiento) = MONTH(CURDATE()), 'Sí', 'No') AS 'Cumpleaños'
	FROM socio
    ORDER BY DAY(fecha_nacimiento);
/* Utilizamos un operador condicional condicional IF y obtenemos los meses de tipos DATE mediante la función MONTH() -> Para realizar la consulta, obtenemos el mes de cumpleaños del socio ma través de la columna
* con su fecha de nacimiento y el mes actual, a través de la función CURDATE(). Dentro del IF, definimos como condición que el mes de aniversario de socio sea igual al mes actual (expr1), si es así,
* devolvemos el string 'Sí'(expr2), si no se cumple la condición, devolvemos 'No' (expre3).
* Mediante la función DAY() obtenemos el día de la fecha para poder ordenar los resultados. 
*/

--
-- Ejercicio 2.  Contar cuántos socios mujeres y hombres cumplen años en el mes, agrupados por tipo de socio.
--

SELECT IF(s.id_socio IN (SELECT * FROM v_socios_corporativos), 'Corporativo', 'No Corporativo') AS 'Tipo de Socio', 
	COUNT(IF(MONTH(fecha_nacimiento) = MONTH(CURDATE()) AND sexo = 'H', id_socio, NULL)) AS 'Cumpleañeros Masculinos', 
	COUNT(IF(MONTH(fecha_nacimiento) = MONTH(CURDATE()) AND sexo = 'M', id_socio, NULL)) AS 'Cumpleañeros Femeninos'
	FROM socio s
    GROUP BY `Tipo de Socio`;
/* Utilizamos el operador IF para escoger entre varios posibles valores de respuestya y las funciones COUNT() para realizar un recuento del número de filas qsegún las condiciones que especificamos y, una
* vez más, MONTH() para extyrae el valor de un mes de un dato tipo DATE -> 
* 1. Asiganamos el tipo de socio mediante el operador IF(), la condición es que el id_socio aparezce en la selección de socios de la tabla corporativo que obtenemos mediante la vista que hemos creado
* al principio del script. Si se cumple, no devolvera como valor el string 'Corporativo', sino, 'No corporativo'.
* 2. Ahora realizamos el conteo del total de socio mediante la función COUNT(). Para pasarle los valores que nos interesa, usaremos un operador IF() en el cual las condiciones serán que el mes de 
* aniversario del socio y el mes actual sean iguales. Si se cumple la expresión, retornamos el valor de la columna id_socio y la función contará la columna, de lo contrario, devolvemos NULL y la función
* no contará la columna.
* 3. Esta operación la usaremos 2 veces, en la primera añadimos a la condición una igualdad entre el campo sexo y el caracter 'H', mientras que en la segunda lo compararemos con el caracter 'M'; de esta
* forma, discriminaremos entre hombres y mujeres. 
* 4. Por último, agrupamos por la columna Tipo de Socio pasándola como literal, de esta forma, realizará el conteo agrupado. */

--
-- Ejercicio 3. Contar cuántos socios no corporativos están registrados, agrupados por plan y cruzados por tipo de socio.
--

SELECT s.id_plan As 'ID Plan', p.plan  AS 'Nombre Plan', 
	COUNT(CASE WHEN s.id_socio IN(SELECT* FROM v_socios_principales) THEN s.id_socio END) AS 'Núm de Socios Principales', 
	COUNT(CASE WHEN s.id_socio IN (SELECT * FROM v_socios_beneficiarios) THEN s.id_socio END) AS 'Núm. de Socios Beneficiarios'
	FROM socio s
    INNER JOIN plan p 
		ON (p.id_plan = s.id_plan)
	INNER JOIN v_tipo_socio vts
		ON vts.id_socio = s.id_socio
	WHERE vts.`Tipo de Socio` != 'Corporativo'
	GROUP BY s.id_plan
    ORDER by s.id_plan;
    
    select * from v_tipo_socio;
    
/* Para esta consulta, usaremos las funciones COUNT() y los operadores condicionales CASE. Case nos permitirá definir una serie de valores de respuesta según se cumplan una serie de condiciones 
* predefinidad -> 
* 1. Para contar los socios principales totales, usamos la función COUNT()
* 2. Para discriminar que filas contaremos, usamos un operador CASE, en caso de que se cumpla la condición de que el campo de id_socio aparezca en la lista de id_socios principales, que obtenemos
* mediante la Vista que hemos generado al prinicpio, pasaomos el valor de id_socio a la función COUNT() de la columna para los socios principales. Como condicion del segundo CASE, establecemos siguiemdo el 
* mismo método que el id_socio debe aparecer en la lista de id_socio de los socios beneficiarios.
* 3. Para poder mostrar la información de los planes y filtrar por id_plan, realizamos un JOIN con la tabla planes y, finalmente, agrupamos los resultamos del COUNT() por el id_plan, es decir, los agrupamos
* por planes.
* 4. Discriminamos los planes corporativos a traves de un INNEr JOIN con la vista v_tipo_socio
* que permite obtener el valor de tipo y no mostrar los corporativos.
*/
    
--
-- Ejercicio 4. Inventar una consulta que haga uso de una de las siguientes funciones: COALESCE, IFNULL, NULLIF. 
--

-- 1
 
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
	ORDER BY i.id_instalacion, `Fecha`, `Hora`;
/* Esta consulta sirve para obtener un informe con la programación de las actividades en las diferentes instalaciones el cuál nos mostrará qué instalaciones están libres y en cuales hay actividades 
* programadas. Esta consulta resultaría útil para poder realizzar los cuadrantes de actividades cuando necesitemos saber si dispones de una sala específica en un día y hora concretos.
* La consulta hace uso del operador IFNULL() que devuelve un valor predefinodo si se cumple una condición o NULL si esta no se cumple y del operador COALLESCE() que devuelve la primera expresión no NULA
* de una lista que oredefinidmos en su sintaxis ->
* 1. Colaesce comprueba si exite una actividad relacionada con el id de instalación, si es así, la devuelve, si no, devuelve el string 'Libre'.
* 2. De forma pàrecida, IFNULL() devuelve el número de instalación comprobando si la id_instalación aparece como FK en horario y relacionándolo también con el nombre d elas actividades, sino, devuelve 
* 'Disponible'.
* 3. Usamos IFNULL() para comprobar, del mismo modo, si la actividad tiene programadas fecha y horas. 
* 4. Usamos JOIN para cruzar las tablas entre sí, usamos LEFT JOIN porque así obtendremos una lista completa de todas las instalaciones estén o no relacionadas con una actividad. 
*/

-- 2

SELECT 
id_socio AS "Id Socio",
documento_identidad AS "DNI",
IFNULL( s.tarjeta_acceso, "No Tiene Tarjeta" ) AS "Tarjeta acceso"
FROM socio s;
/* IFNULL  acepta dos argumentos y retorna el primero que es no nulo por tanto devuelve el Nº de tarjeta 
* en caso de que disponga de ella y si no devulve el literal "No tiene tarjeta".
*/

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
        SET edad = TIMESTAMPDIFF(YEAR,fecha_nacimiento,CURDATE());
        RETURN edad;
	END
|
    
DELIMITER ;

 SELECT id_socio AS 'ID Socio', nombre AS 'Nombre', apellido1 AS 'Apellido',  CURDATE() AS 'Fecha Actual', fecha_nacimiento AS 'Fecha de Nacimiento', edad(fecha_nacimiento) AS 'Edad'
	FROM socio;
/* Para crear esta función, usaremos la cláusula CREATE FUNCTION:
* 1. El nombre de la función es edad y recibe como único parámetro una tipo DATE que será la fecha de nacimiento del socio.
* 2. RETURNS -> Indicamos que el tipo de dato de retorno sera un entero.
* 3. Usamos las cláusulas BEGIN y END para envolver el cuerpo de la función.
* 4. DECLARE -> Declaramos la variable 'edad' de retorno de tipo entero. 
* 5. SET -> Asignamos la variable mediante la función TIMESTAMPDIFF() que nos devuelve la diferencia entre las
* dos fechas en el tipo expecificado, en este caso, YEAR. 
* 6. RETURN -> Una vez asignado el cálculo de la edad del socio, devolvemos la variable.
*/

--
-- Ejercicio 6. Crear una función UDF llamada Nombre_Completo que reciba como parámetros un nombre y dos apellidos y retorne un nombre completo en formato (Apellido1 + Inicial de Apellido2 (de existir) + “., “ + Nombre. Ejemplo: Pérez P., Pepito) . Probar la función en una consulta contra la tabla de socios. La consulta deberá mostrar el idSocio, Nombre, Apellido1, Apellido2 y el Nombre completo y estar ordenada por este campo.
--

DELIMITER |

CREATE FUNCTION nombre_completo(nombre VARCHAR(30), apellido1 VARCHAR(20), apellido2 VARCHAR(20))
	RETURNS VARCHAR(70)
    READS SQL DATA
    BEGIN
		DECLARE nombre_completo VARCHAR(70);
        IF LENGTH(apellido2) >= 1 THEN
			SET nombre_completo = CONCAT(apellido1, ' ', CONCAT(LEFT(apellido2, 1), '.'), ',', ' ', nombre);
			ELSE SET nombre_completo = CONCAT(apellido1, ',', ' ', nombre);
			END IF;
        RETURN nombre_completo;
	END
|

DELIMITER ;

SELECT id_socio AS 'ID Socio', nombre AS 'Nombre', apellido1 AS 'Primer Apellido', apellido2 AS 'Segundo Apellido', nombre_completo(nombre, apellido1, apellido2) AS 'Nombre Completo'
	FROM socio
    ORDER BY `Nombre Completo`;
/* Como en el caso anterior, creamos la función mediante la misma sintaxis. Explicamos a continuación las características de su implementacióon:
* 1. La función recibe tres variables; el nombre del usuario, el primer apellido y el segundo, todas de tipo string VARCHAR().
* 2. Podemos encontrarnos 2 escenarios, que el socio haya informado de su segundo apellido o que no lo haya hecho, en muchos casos, al hacerlo, puede haberse entrado el valor como un carácter 
* vacío o como NULL, para discriminar si el segundo apellido aparece o no, usamos una sentencia IF para decidir que valor asignamos a la variable. Como hemos visto que puede haberse entrado el 
*segundo apellido como un carácter en blanco, para asegurar todos los escenarios, usamos la función LENGHT() para 
* obtener la longitud del campo y  decidir cómo proseguimos.
* 3. Usamos la función CONCAT() para generar el string con los diferentes campos concatenados. Si no existiria segundo
* apellido, deviolvemos un string con el formato requerido pero solamente con el primer apellido.
* 4. El valor de retorno es el nombre completo concatenado en el formato especificado por el enunciado.
 */

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
/* La estructura de la función es igual a la de los ejercicios anteriorres, pero explicaremos las particularidades 
* de su implementación: 
* 1. La funcuión recibe como parámetrps de entrada el peso en Kg y la estatura en cm y devuelve un valor del tipo DECIMAL.
* 2. Podemos ver que, al aplicar la fórmula, la consecución de las dos divisiones podría darnos como resultado
* una cifra con más de 2 decimales, para evitar que la función arroje null o un error, usamos la dunción ROUND() para mantener el
* número máximo de decimales en 2.
* 3. Usamos la función POWER() para elevar la estatura al cuadrado. Hay que dividir la altura por 100 ya que la recibimos
* como cm.
*/

--
-- Ejercicio 8. Crear una función UDF llamada regalosAniversario que se aplicará a los socios del gimnasio cuyo mes de Alta en el gimnasio coincida con el mes en curso. Hacer la consulta pertinente para probar la función.
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
/* La función se estructura del mismo modo que en los ejercicios anteriores. A continuación, analizamos la implementación:
* 1. La función recibe por parámentros de entrada el tipo de socio y la fecha de alta del socio. Para encontar el tipo de socio
* usamos la vista que creamos al principio del script ya que simplifica la implementación y lectura del código.
* 2. La función devuelve un valor de tipo string VARCHAR().
* 3. Usamos la función MONTH() para obtener el valor del mes tanto de la fecha de alta como de la fecha actual, obtenida con
* CURDATE().
* 4. Para asignar el valor de la variable de retorno, usamos una sentencia CASE. Tenemos tres condiciones posibles, en
* las tres comenzamos por comprobar si el mes actual es igual al mes de la fehca de alta del socio. A continuación,
* en cada una comparamos el valor de tipo de socio con uno de los posibles resultados: Corporativo, Principal o Beneficiario.
* 5. Cuando los meses coincidam. cada CASE devolverá uno de los resultados especificados, en caso de que no se su anoversario,
* ELSE devolverá un valor por defecto, 'No es su aniversario'.
*/

--
-- Ejercicio 9. Inventar una función UDF que se considere útil para las operaciones del Gimnasio. Explicarla y justificarla en los comentarios de la plantilla .sql
--

-- 1

DELIMITER |
CREATE FUNCTION provincias(idsocio int)
	RETURNS varchar(50)
    READS SQL DATA
	BEGIN
		DECLARE salida varchar(100);
		SET salida =  (Select 
                CASE  
	WHEN (codigo_postal>=01000 and codigo_postal<=01520) then 'Alava'                 
	WHEN (codigo_postal>=02000 and codigo_postal<=02696) then 'Albacete'              
	WHEN (codigo_postal>=03000 and codigo_postal<=03860) then 'Alicante'              
	WHEN (codigo_postal>=04000 and codigo_postal<=04897) then 'Almería'               
	WHEN (codigo_postal>=33000 and codigo_postal<=33993) then 'Asturias'              
	WHEN (codigo_postal>=05000 and codigo_postal<=05697) then 'Avila'                 
	WHEN (codigo_postal>=06000 and codigo_postal<=06980) then 'Badajoz'               
	WHEN (codigo_postal>=07000 and codigo_postal<=07860) then 'Baleares'              
	WHEN (codigo_postal>=08000 and codigo_postal<=08980) then 'Barcelona'             
	WHEN (codigo_postal>=09000 and codigo_postal<=09693) then 'Burgos'                
	WHEN (codigo_postal>=10000 and codigo_postal<=10991) then 'Cáceres'               
	WHEN (codigo_postal>=11000 and codigo_postal<=11693) then 'Cádiz'                 
	WHEN (codigo_postal>=39000 and codigo_postal<=39880) then 'Cantabria'             
	WHEN (codigo_postal>=12000 and codigo_postal<=12609) then 'Castellón'             
	WHEN (codigo_postal>=51000 and codigo_postal<=51001) then 'Ciudad Real'           
	WHEN (codigo_postal>=13000 and codigo_postal<=13779) then 'Córdoba'               
	WHEN (codigo_postal>=14000 and codigo_postal<=14970) then 'Cuenca'                
	WHEN (codigo_postal>=16000 and codigo_postal<=16891) then 'Gerona'                
	WHEN (codigo_postal>=17000 and codigo_postal<=17869) then 'Granada'               
	WHEN (codigo_postal>=18000 and codigo_postal<=18890) then 'Guadalajara'           
	WHEN (codigo_postal>=19000 and codigo_postal<=19495) then 'Guipuzcoa'             
	WHEN (codigo_postal>=20000 and codigo_postal<=20870) then 'Huelva'                
	WHEN (codigo_postal>=21000 and codigo_postal<=21891) then 'Huesca'                
	WHEN (codigo_postal>=22000 and codigo_postal<=22880) then 'Jaén'                  
	WHEN (codigo_postal>=23000 and codigo_postal<=23790) then 'La Canduña'             
	WHEN (codigo_postal>=15000 and codigo_postal<=15981) then 'La Rioja'              
	WHEN (codigo_postal>=26000 and codigo_postal<=26589) then 'Las Palmas'            
	WHEN (codigo_postal>=35000 and codigo_postal<=35640) then 'León'                  
	WHEN (codigo_postal>=24000 and codigo_postal<=24996) then 'Lérida'                
	WHEN (codigo_postal>=25000 and codigo_postal<=25796) then 'Lugo'                  
	WHEN (codigo_postal>=27000 and codigo_postal<=27891) then 'Madrid'                
	WHEN (codigo_postal>=28000 and codigo_postal<=28991) then 'Málaga'                
	WHEN (codigo_postal>=29000 and codigo_postal<=29792) then 'Murcia'                
	WHEN (codigo_postal>=30000 and codigo_postal<=30892) then 'Navarra'               
	WHEN (codigo_postal>=31000 and codigo_postal<=31890) then 'andense'                
	WHEN (codigo_postal>=32000 and codigo_postal<=32930) then 'Palencia'              
	WHEN (codigo_postal>=34000 and codigo_postal<=34889) then 'Pontevedra'            
	WHEN (codigo_postal>=36000 and codigo_postal<=36980) then 'Salamanca'             
	WHEN (codigo_postal>=37000 and codigo_postal<=37900) then 'Santa Cruz de Tenerife'
	WHEN (codigo_postal>=40000 and codigo_postal<=40593) then 'Segovia'               
	WHEN (codigo_postal>=41000 and codigo_postal<=41980) then 'Sevilla'               
	WHEN (codigo_postal>=42000 and codigo_postal<=42368) then 'Sandia'                 
	WHEN (codigo_postal>=43000 and codigo_postal<=43896) then 'Tarragona'             
	WHEN (codigo_postal>=38000 and codigo_postal<=38911) then 'Teruel'                
	WHEN (codigo_postal>=44000 and codigo_postal<=44793) then 'Toledo'                
	WHEN (codigo_postal>=45000 and codigo_postal<=45960) then 'Valencia'              
	WHEN (codigo_postal>=46000 and codigo_postal<=46980) then 'Valladolid'            
	WHEN (codigo_postal>=47000 and codigo_postal<=47883) then 'Vizcaya'               
	WHEN (codigo_postal>=48000 and codigo_postal<=48992) then 'Zamanda'                
	WHEN (codigo_postal>=49000 and codigo_postal<=49882) then 'Zaragoza'             
	ELSE 0                                                                                                
	END as "Provincia"
	FROM socio WHERE id_socio=idsocio);
   RETURN salida;
END
|

DELIMITER ;

SELECT id_socio,documento_identidad,nombre,apellido1,fecha_alta,codigo_postal,
	provincias(id_socio) AS "Provincia"
FROM socio;

/* la función provincia() recibe como parámetro el id_socio y comprubea, a través del
* código postal, a qué provincia pertenece. Utiliza una sentencia CASE para asignar el
* valor de retorno. */

-- 2

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
/* La función principal permite obtener el valor de crecimiento anual de altas de socios comparándolo con los datos anteriores 
* existentes. Para poder realizar el cálculo de manera correcta, también se ha creado una función que devuelve el número de 
* altas del último año con altas, así podemos discriminar los casos en los que * no hay datos existentes.
* 1. La función auxiliar hace uso de una sentencia de control de flujo del tipo WHILE, así podemos comprobar cómo funciona.
* Recibe como parámetro el año con el que queremos comparar los datos, si hay la fución primero intenta obtener el valor del
* total de altas para el año anterior, si no existe, la función WHILE busca el primer año con datos existentes y devuelve 
* el valor de total de altas de ese año.
* 2. La función principal, recibe por parñametro el años actual y retorna un valor de tipo DECIMAL que representa el % de crecimiento.
* Usamos dos variables internas, además de la variable d eretorno, una con el númeor de altas del año actual y otra 
* con el número de altas del año anterio que calculamos con la función auxiliar.
* Por último, discriminamos el resultado del año de apertura y lo fijamos en 0,ya que no hay crecimiento relativo al año anterior.
*/

-- Variable de @usuario

--
-- Ejercicio 10. Crear una variable de usuario denominada @nivel. Asignar un valor a la misma entre los niveles que tienen las actividades del gimnasio. Usar la variable @nivel para filtrar las actividades que pertenezcan a ese nivel.
--

SET @nivel = 'Intermedio';

SELECT id_actividad AS 'ID Actividad', actividad AS 'Nombre', descripcion AS 'Descripción', dirigida_a AS 'Dirigida a', duracion_sesion_minutos AS 'Duración en min', nivel AS 'Nivel'
	FROM actividad
    WHERE nivel = @nivel
    ORDER BY id_actividad;
/* Para crear una variable de usuario usamos la cláusula SET e iniciamos el nombre de la variable con '@'-
* Para el test, igualamos el valor de la variable a 'Intermedio' y comprobamos mediante la sentencia SELECT como obtenemos 
* únicamente las actividades de nivel intermedio al usar la variable como segundo elemento de la condición de la cláusula
* WHERE. 
*/

--
-- Ejercicio 11. Crear una consulta que guarde en dos variables denominadas @numeroSocios y @EstimadoFacturacion el total de socios corporativos y el estimado de facturación para los mismos.
--

SET @numero_socios = (SELECT SUM(bf.`Numero Afiliados`) 
	FROM Base_Facturacion bf 
    JOIN empresa e
    ON (e.nif = bf.`NIF/DNI`)
    WHERE bf.`ID Plan` IN (SELECT * FROM v_num_planes_corporativos)),
    @estimado_facturacion = ROUND((SELECT SUM(`Importe Total`) 
		FROM Base_Facturacion WHERE `ID Plan` IN (SELECT * FROM v_num_planes_corporativos)), 2);

-- Comprobamos 

SELECT @numero_socios AS 'Número de Socios Corporativos', @estimado_facturacion AS 'Estimado Facturacion';
/* Usamos la cláusula SET para crear las variables recordando inciar su nombre con el carácter '@', separamos la definición y
* asignación de cada variable con ','.
* 1. Para la asignación de @numero_socios, realizamos una subconsulta sobre la vista Base_facturación que creamos en el producto
* anterior y que devuelve el número de socios relacionado con una empresa que identificamos por su NIF.
* Discriminamos a través del tipo de plan.
* 2. Para la asignación de @estimado_facturacion realizamos una subconsulta que devuelve la suma total de los dos tipos de planes
* y usando como base los resultados que obtenemos de la vista Base_facturacion.
* 3. Para filtar los resultados obtenidos de la vista Base_facturacion, usamos la vista que hemos
* creado al inicio v_num_planes_corporativos que devuelve los identificadores de los planes corporativos.
*/

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
/* Para obtener los datos solicitados, usaremos una consulta cruzando dos tablas, empresa como principal, de donde
* obtendremos el nombre y el nif de la empresa y, como secundaria, la vista Base_facturacion que creamos en el anterior
* producto cruzándolas mediante un INNER JOIN ya que nos interesan solo los resultados que coincidan en el nif, de esta
* forma realizamos el cálculo sobre los datos de una sola empresa a la vez.
* 1. Para obtener el % sobre el total de socios y % sobre total estimado, realizamos una fórmula de porcentaje básica 
* sonre la variables que creamos en el ejercicio anterior. 
*/

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
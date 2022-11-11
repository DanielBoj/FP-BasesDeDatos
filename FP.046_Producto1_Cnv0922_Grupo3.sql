-- PLANTILLA DE ENTREGA DE LA PARTE PRÁCTICA DE LAS ACTIVIDADES
-- --------------------------------------------------------------
-- Actividad: FP.046_PRODUCTO1
--
-- Grupo: Cnv0922_Grupo03: Nínive
-- 
-- Integrantes: 
-- 1. Miki Alvarez Vidal
-- 2. Katiane Coutinho Rosa
-- 3. Daniel Zafra del Pino
-- 4. Daniel Boj Cobos
--
-- Database: ICX0_P3_3
-- --------------------------------------------------------------

--
-- Pregunta 1 Importar la base de datos Gym que se encuentra en el archivo FP.046_PRODUCTO1_script.sql, al servidor de Base de Datos, sustituyendo la sentencia USE Gym; por el nombre del SCHEMA asignado al grupo.
--
USE ICX0_P3_3;

--
-- Pregunta 2 Realizar un análisis de las claves foráneas existentes, eliminar las claves foráneas y rehacerlas, agregando las cláusulas ON UPDATE, ON DELETE y justificar con un comentario.
--
SHOW CREATE TABLE socio;
/* Comprobamos cómo se han implementado las FK en las creaciones de la tabla para porde decidir
* los cambios necesarios
*/

ALTER TABLE socio DROP FOREIGN KEY socio_plan;

ALTER TABLE socio
    ADD CONSTRAINT socio_plan FOREIGN KEY (id_plan) REFERENCES plan (id_plan)
    ON UPDATE CASCADE ON DELETE RESTRICT;

/* Eliminamos las FK actuales y las actualizamos volviéndolas a crear, si el plan cambia de ID,  el mismo cambio se propagará por toda la tabla socio cambiando el valor de ID de los registros
* afectados. En caso de borrado, para no perder la información de los socios, ya que podríamos querer moverlos a otro plan si su plan actual deja de existir, usaremos un RESTRICT para 
* empedir la operación mientras existan registros relacionados, o sea, socios registrados en ese plan. 
*/

SHOW CREATE TABLE principal;

ALTER TABLE principal DROP FOREIGN KEY socio_principal;

ALTER TABLE principal 
    ADD CONSTRAINT socio_principal FOREIGN KEY (idsocio) REFERENCES socio (id_socio)
    ON UPDATE CASCADE ON DELETE CASCADE;
/* En este caso actualizamos para que ambas operaciones se extiendan a la tabla relacionada; si el socio cambia de ID, este cambiará en todos los registros de la tabla coorporativo asociados.
* De igual modo, si se borra el socio, se borran todos los registros asociados. 
*/

SHOW CREATE TABLE corporativo;

ALTER TABLE corporativo 
    DROP FOREIGN KEY socio_corporativo, 
    DROP FOREIGN KEY socio_empresa;

ALTER TABLE corporativo
    ADD CONSTRAINT socio_corporativo FOREIGN KEY (id_socio) REFERENCES socio (id_socio)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT socio_empresa FOREIGN KEY (nif) REFERENCES empresa (nif)
    ON UPDATE RESTRICT ON DELETE CASCADE;

/* En el caso de la relación con socio, como en el anterior, si el socio cambia de ID, el cambió afectará a todos los registros relacionados de la tabla corporativo, y, si se borra, se borrarrán 
* sus registro asociado. Para el caso de las empresas, legalmente, una empresa no puede cambiar de NIF, cito textualmente la inforación de la sede jurídica de la Agencia Tributaria "¿Puede variar 
* el NIF de una persona jurídica o entidad? No, el NIF será invariable salvo que cambie su forma jurídica o nacionalidad", así que no deberíamos permitir cambios en este valor, por otro lado, si 
* borramos la empresa, también se borrarán todos los asociados corporativos de esta. Creo que en este caso, además, deberemos extender el borrado en la tabla de socios de los registros que coincidan 
* con la FK de ID del socio, ya que la emprensa ha dejado de colaborar con el gimnasio.
*/

SHOW CREATE TABLE seguimiento;

ALTER TABLE seguimiento DROP FOREIGN KEY seguimiento_socio;

ALTER TABLE seguimiento
    ADD CONSTRAINT seguimiento_socio FOREIGN KEY (id_socio) REFERENCES socio (id_socio)
    ON UPDATE CASCADE ON DELETE CASCADE;

/* Para este caso, si el socio cambia de ID, realizaremos el mismo cambio en los registros asociados en seguimiento. Para le borrado, de la misma forma, si borramos su ID,
* borraremos los registros asociados de la tabla seguimientos
*/

SHOW CREATE TABLE historico;

ALTER TABLE historico DROP FOREIGN KEY historico_socio;

ALTER TABLE historico
    ADD CONSTRAINT historico_socio FOREIGN KEY (id_socio) REFERENCES socio (id_socio)
    ON UPDATE CASCADE ON DELETE CASCADE;

/* Como en el anterior, si cambiamos el ID, lo cambiaremos también en los registros asociados de la tabla historico, y si borramos el cliente, borraremos los registros asociados 
*/

SHOW CREATE TABLE horario;
/* Podemos considerar que horario realiza una función de entidad de intersección entre instalacion y actividad 
*/

ALTER TABLE horario 
    DROP FOREIGN KEY actividad_horario,
    DROP FOREIGN KEY actividad_instalacion;

ALTER TABLE horario
    ADD CONSTRAINT actividad_horario FOREIGN KEY (id_actividad) REFERENCES actividad (id_actividad)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT instalacion_horario FOREIGN KEY (id_instalacion) REFERENCES instalacion (id_instalacion)
    ON UPDATE CASCADE ON DELETE RESTRICT;

/* Por un lado, si cambiamos el ID de una actividad, lo tenemos que cambiar también en su horario asociado, y si borramos la actividad, hay que borrar también el horario
de esta. Si una instalacion cambia de ID, lo cambiaremos también en la tabla relaciionada de horario, si decidimos borrar una instalación, opino que sucede como en el primer
caso y deberíamos asegurarnos de trasladar todas las actividades que se realizan en esa instalación primera, así que una buena idea es impedir el borrado de una instalación
mientras tenga un horario de actividad relacionado. */

--
-- Ejercicio 3 Realizar las modificaciones pertinentes en la Base de Datos para que la misma se ajuste a los nuevos requisitos.
--

--
-- Ejercicio 3.A Añadir la tabla gimnasio para registrar los datos del gimnasio
--

START TRANSACTION;

-- Creación de las tablas --

CREATE TABLE IF NOT EXISTS gimnasio (
    id_gimnasio int NOT NULL AUTO_INCREMENT,
    nombre varchar(45) NOT NULL,
    slogan varchar(250) DEFAULT NULL,
    cif varchar(9) NOT NULL,
    direccion varchar(45) NOT NULL,
    ciudad varchar(45) NOT NULL,
    codigo_postal int(5) NOT NULL,
    comunidad_autonoma enum('Andalucía', 'Aragón', 'Asturias', 'Baleares', 'Canarias', 'Cantabria', 'Castilla y León', 'Castilla-La Mancha', 'Cataluña', 
    'Comunitat Valenciana', 'Extremadura', 'Galicia', 'Madrid', 'Murcia', 'Navarra', 'País Vasco', 'La Rioja', 'Ceuta', 'Melilla') NOT NULL COMMENT 'lista de Comuniades Autónomas de España',
    telefono varchar(45) NOT NULL,
    mail varchar(45) NOT NULL,
    website varchar(60) NOT NULL,
    apertura_laborables time NOT NULL COMMENT 'Horario de apertura entre semana',
    apertura_festivos time NOT NULL COMMENT 'Horario de apertura en festivos y domingos',
    PRIMARY KEY (id_gimnasio)
);

/* Creamos la tabla según las especificaciones, además, el slogan queda como opcional y con valor null por defecto, porque no lo veo plantado como un campo obligatorio.
* Comunidad_autónoma se escoge mediante un enumerador ya que hay una cantidad limitada pequeña de posibles respuestas.
* Los horarios de apertura usan el tipo TIME */

COMMIT;

--
-- Ejercicio 3.B Incluir dos columnas adicionales en la tabla de Planes: Socios adicionales y Descuento en clases extras.
-- Adicionalmente, se crean dos nuevos planes:  INFANTIL (< 16 años) y puntual
--

START TRANSACTION;

-- Añadimos las columnnas --
ALTER TABLE plan
    ADD COLUMN socio_adicional enum('SÍ', 'NO') NOT NULL,
    ADD COLUMN descuento_clases_extra enum('SÍ', 'NO') NOT NULL;

/* Añadimos la nueva tabla usanso enumeradores para dar uno de los dos posibles valores. Escogemso enumeradores por la clariadad del resultado,
* pero también funcionaría con tinyint 
*/

-- Modificamos los nuevos datos de la tabla
UPDATE plan
    SET socio_adicional = 1,
    descuento_clases_extra = 1
    WHERE id_plan BETWEEN 1 and 5;

UPDATE plan
    SET socio_adicional = 2,
    descuento_clases_extra = 2
    WHERE id_plan BETWEEN 6 and 8;

/* Actualizamos los planes de la manera más ágil posible, los 5 primeros aceptan socios adicionales y tienen descuentos, de los 3 restantes, ninguno
* tiene descuento ni acepta socios adicionales. Reducimos el nñumeor de consultas para ir más rápido */

-- Añadimos los nuevos planes --
ALTER TABLE plan
    AUTO_INCREMENT = 8;

INSERT INTO plan (plan, tipo, matricula, cuota_mensual, descripcion, socio_adicional, descuento_clases_extra) VALUES
    ('Infantil (<16 años)', 'P', 45.00, 25.00, 'Acceso a todo el gimnasio. Horario completo', 1, 2),
    ('Puntual', 'P', 0.00, 0.00, 'Acceso puntual al gimnasio para realizar clases extra', 2, 2);
/* Añadimos los nuevos planes mediante una sentencia INSERT, reseteamos el id_plan manualmente ya que el contador quedó variado de las actividades del año pasado,
* y usamos enteros para seleccionar los enumeradores.
*/

COMMIT;

--
-- Ejercicio 3.C y D Nuevo tipo de Socio, el Socio Beneficiario.
--

START TRANSACTION;

-- Creación de la tabla --
CREATE TABLE IF NOT EXISTS beneficiario (
    id_beneficiario int NOT NULL AUTO_INCREMENT,
    id_socio int NOT NULL,
    id_socio_principal_referencia int NOT NULL,
    tipo_descuento enum('FAMILIAR', 'MONOPARENTAL', 'NUMEROSA', 'AMIGO') NOT NULL,
    tipo_afiliacion enum('Hijo menor de 18 años', 'Hijo entre 18 y 25 años', 'Pareja/Amigo/Familiar') NOT NULL,
    porcentaje_descuento int GENERATED ALWAYS AS (CASE 
        WHEN tipo_descuento = 1 AND tipo_afiliacion = 1 THEN 40
        WHEN tipo_descuento = 1 AND tipo_afiliacion = 2 THEN 25
        WHEN tipo_descuento = 1 AND tipo_afiliacion = 3 THEN 20
        WHEN tipo_descuento = 2 OR tipo_descuento = 3 AND tipo_afiliacion = 1 THEN 50
        WHEN tipo_descuento = 2 OR tipo_descuento = 3 AND tipo_afiliacion = 2 THEN 30
        WHEN tipo_descuento = 2 OR tipo_descuento = 3 AND tipo_afiliacion = 3 THEN 20
        WHEN tipo_descuento = 4 AND tipo_afiliacion = 3 THEN 20
        ELSE 0
    END),
    PRIMARY KEY (id_beneficiario) 
);

/* Creamos la tabla añadiendo una PK, id_beneficiario, y usando enumeraciones para los valores de tipo de descuento y afiliación ya que, por un lado, son 
una pequeña lista d evalores conocidos y siempre iguales y, por el otro, nos permite crear una columna autogenerada para poder calcular el 
descuento.  Relacionamos la tabla hija con l atabla padre 'socio', por un lado, el nuevo socio beneficiario se relacion con 'id_socio' por el
* otro, lo relacionamos también con el socio principal que lo refiere como beneficiario a través de id_socio_principal_referencia*/

-- Añadimos las relaciones --

ALTER TABLE beneficiario
    ADD CONSTRAINT socio_beneficiario FOREIGN KEY (id_socio) REFERENCES socio (id_socio)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT socio_principal_referencia FOREIGN KEY (id_socio_principal_referencia) REFERENCES socio (id_socio)
    ON UPDATE CASCADE ON DELETE CASCADE;

/* Si cambiamos el id del socio principal, se cambiara en sus registros asociados de beneficiario y, si borramos al socio prinicpal,
* se borrarán también su registro asociado. */

COMMIT;

--
-- Ejercicio 3.E El Gimnasio tendrá ahora 2 tipos de actividades: Actividades Dirigidas (incluidas en el precio del Plan) y 
-- Clases Extras, que el gimnasio ofrecerá para grupos reducidos y que conllevan un coste adicional.
--

START TRANSACTION;

-- Creamos las nuevas tablas --
CREATE TABLE IF NOT EXISTS dirigida (
    id_actividad int NOT NULL,
    resistencia tinyint DEFAULT NULL,
    fuerza tinyint DEFAULT NULL,
    velocidad tinyint DEFAULT NULL,
    coordinacion tinyint DEFAULT NULL,
    flexibilidad tinyint DEFAULT NULL,
    equilibrio tinyint DEFAULT NULL,
    agilidad tinyint DEFAULT NULL,
    PRIMARY KEY (id_actividad)   
);

CREATE TABLE IF NOT EXISTS extra (
    id_actividad int NOT NULL,
    clases_semanales int NOT NULL,
    matricula decimal (10,2) NOT NULL,
    mensualidad decimal (10,2) NOT NULL,
    equipamiento varchar(255) DEFAULT NULL,
    descuento_abonados int NOT NULL, -- Puede necesitar restricción?
    PRIMARY KEY (id_actividad)
);

-- Añadimos las relaciones --
ALTER TABLE dirigida
    ADD CONSTRAINT actividad_dirigida FOREIGN KEY (id_actividad) REFERENCES actividad (id_actividad)
    ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE extra
    ADD CONSTRAINT actividad_extra FOREIGN KEY (id_actividad) REFERENCES actividad (id_actividad)
    ON UPDATE CASCADE ON DELETE CASCADE;

-- Modificamos la tabla actividad --
ALTER TABLE actividad
    DROP COLUMN resistencia,
    DROP COLUMN fuerza,
    DROP COLUMN velocidad,
    DROP COLUMN coordinacion,
    DROP COLUMN flexibilidad,
    DROP COLUMN equilibrio,
    DROP COLUMN agilidad;

/* Para solucionar este ejercicio tomamos el ejemplo de socio: Tendremos una tabla padre 'actividad' y dos tablas hijas con esta que especificarán
* el tipo de actividad, 'dirigida' y 'extra'. En la tabla 'actividad', mantenemos todos los campos comunes a todas las actividades, en las tablas secundarias, 
* colocamos los campos específicos de cada tipo de actividad y hacemos que id_actividad sea, a ña vez, PK y FK que la relacione con 'actividad', así mantenemos
* la herencia. Por último, relacionamos las tabla scon las FK y borramos las filas no comunes de la table padre 'actividad'. */

COMMIT;

--
-- Ejercicio 3.F Se desea llevar un registro de INSCRIPCIONES en las actividades no incluidas en el plan, para generar posteriormente la facturación.
--

START TRANSACTION;

-- Creamos la tabla --
CREATE TABLE IF NOT EXISTS inscripcion (
    id_inscripcion SERIAL,
    id_actividad int NOT NULL,
    id_socio int NOT NULL,
    fecha_alta date NOT NULL,
    fecha_baja date DEFAULT NULL,
    PRIMARY KEY (id_inscripcion)
);

-- Creamos las relaciones --
ALTER TABLE inscripcion
    ADD CONSTRAINT inscripcion_actividad FOREIGN KEY (id_actividad) REFERENCES actividad (id_actividad)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT inscripcion_socio FOREIGN KEY (id_socio) REFERENCES socio (id_socio)
    ON UPDATE CASCADE ON DELETE CASCADE;
/* Creamos una tabla nueva, usamos la cláusula SERIAL como shorthand para 'int NOT NULL AUTO_INCREMENT UNIQE KEY'. Definimos la fecha_baja como no obligatorio, ya
* que es un campo que, de salida, tendrá el valor de nulo, porque se sobreentiende que el usuario va a estar dado de alta en el momento de crear su registro. Por
último, creamos las FK con las dos tablas en las que queremos que se relacionen los registros, 'usuario' y 'actividad'. Para las restricciones, en caso de 
* modificar el id de un usuario o actividad, se modificará también en la tabla secundaria; por otro lado, no tiene sentido que borremos una actividad que aún tenga 
* usuarios registrados, ya que perderíamos la información actual y no podrñiamos calcular la factura, así que restringimos el borrado para que solo pueda eliminarse
* la actividad si ya no hay usuarios relacionados con esta. Por último, en el caso de borrar un usuario, borramos también su alta en la actividad eliminando su
* registro en inscripción. */

COMMIT;

--
-- Ejercicio 4. Agregar el campo FechaCreacionBD en la tabla Gimnasio y llenarlo con la fecha de inicio de la convocatoria.
--

START TRANSACTION;

-- Creamos un registro --
INSERT INTO gimnasio (nombre, slogan, cif, direccion, ciudad, codigo_postal, comunidad_autonoma, telefono, mail, website, apertura_laborables, apertura_festivos) VALUES
    ('Nínive', 'No Pain, No Database', 'H06072458', 'Calle Platón, 14', 'Utopia Capital', 99333, 9, '967458525', 'ninive@gym.com', 'ninivegym.es', '06:00:00', '08:00:00');

-- Modificamos la tabla --
ALTER TABLE gimnasio
    ADD COLUMN fecha_creacion_bd date NOT NULL;

UPDATE gimnasio
    SET fecha_creacion_bd = '2022-09-28'
    WHERE id_gimnasio = 1;

/* Para poder realizar el UPDATE debemos rellenar primero un registro en la tabla. Ahora podemos modificar la tabla para añadir la nueva columna que será del
* tipo date y actualizar el registro que hemos creado para añadir la fecha. Hay que recordar, por seguridad, usar la cláusula WHERE para selecionar los registros correctos, 
además, hay que incluir una selección basada en la PK de la tabla siempre que usemos el Modo Seguro de la BD, que es lo más recomendable y el modo por defecto.*/


COMMIT;

--
-- Ejercicio 5. Crear una columna calculada en la tabla Gimnasio, que calcule la diferencia en días entre la FechaCreacionBD y la FechaApertura del Gimnasio.
-- 

START TRANSACTION;

-- Modificamos la tabla --
ALTER TABLE gimnasio
    ADD COLUMN fecha_apertura date NOT NULL,
    ADD COLUMN diferencia_apertura_creacion int GENERATED ALWAYS AS (
        DATEDIFF(fecha_creacion_bd, fecha_apertura)
    );

-- Actualizamos el campo de apertura del gimnasio para obtener un valor --
UPDATE gimnasio
    SET fecha_apertura = '2022-09-01'
    WHERE id_gimnasio = 1;

-- Confirmamos que el cálculo sea correcto --
SELECT diferencia_apertura_creacion AS 'Días de diferencia'
    FROM gimnasio
    WHERE id_gimnasio = 1;

/* Como no hay ningún campo que contenga la fecha de apertura dle gimnasio, lo añadimos. A continuación, podemos añadir el campo autocalculado, para ello usamos
* la cláusula GENERATED AS (expresión). Para el cálculo, podemos usar la función DATEDIFF() que nos devuelve la diferencia en dias entre dos fechas. */

COMMIT;

--
-- Ejercicio 6. Generar una restricción CHECK en la tabla Inscripciones. Se deberá verificar que la Fecha Alta sea menor a la Fecha Baja.
--

START TRANSACTION;

ALTER TABLE inscripcion
    ADD CONSTRAINT verificacion_fecha_alta CHECK (fecha_alta < fecha_baja);

COMMIT;

--
-- Ejercicio 7. Revisar el resto de tablas y generar dos restricciones check para controlar la integridad de los datos.
--

-- Creación de nuevas restricciones --

-- 1 Control de fechas --
ALTER TABLE historico
    ADD CONSTRAINT chk_fechas_cambio_plan CHECK (fecha_cambio >= fecha_alta_plan);

ALTER TABLE empresa
    ADD CONSTRAINT chk_fechas_convenio CHECK (fecha_inicio_convenio < fecha_fin_convenio);

-- 2. Control de DNI

ALTER TABLE socio
    ADD CONSTRAINT ck_documento_identidad CHECK (documento_identidad REGEXP '^[0-9]{8}[TRWAGMYFPDXBNJZSQVHLCKE]');
/* Con estos checks controlamos que las fechas en los cambios de plan y en los convenios con las empresas guarden siempre la integridad de los datos. Además, ck_documento_identidad 
* verifica que el DNI que se intenta registrar tenga una estructura correcta. */

--
-- Ejercicio 8. Diseñar un disparador que prevenga que un socio no pueda registrarse al mismo tiempo en las tablas corporativo, principal y beneficiario, sino exclusivamente en una de ellas.
--

START TRANSACTION;

-- Cambiamos el delimiter --
DELIMITER |

CREATE TRIGGER trg_beneficiario_control_tipo_socio
    BEFORE INSERT
    ON beneficiario
    FOR EACH ROW 
    BEGIN
        IF EXISTS (
            SELECT *
            FROM corporativo c, principal p 
            WHERE c.id_socio = new.id_socio OR p.idsocio = new.id_socio
        ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El socio ya está registrado con otro tipo';
        END IF;
    END|

CREATE TRIGGER trg_corporativo_tipo_socio
    BEFORE INSERT
    ON corporativo
    FOR EACH ROW
    BEGIN
        IF EXISTS (
            SELECT *
            FROM beneficiario b, principal P
            WHERE b.id_socio = new.id_socio OR p.idsocio = new.id_socio
        ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El socio ya está registrado con otro tipo';
        END IF;
    END|
    
DELIMITER ;

/* Como un disparador solamente actúa sobre una tabla a la vez, tenemos que crear varios disparadores para resolver todos los posibles casos.
* Si creamos un control sobre corporativo y otro sobre beneficiario, por descarte, principal también quedará protegida. Hayq ue recordad
* cambiar el delimiter antes de empezar a declarar los disparadores y restaurarlo al finalizar. Tenemos que actuar antes de la inserción, 
por lo que usaremos la cláusula BEFORE y la manera de evitar la inseción, es generar un error, en MySQL usamos la cláusula SIGNAL SQLSTATE y
usamos el código '45000' que se refiere de forma genérica a 'unhandled user-defined exception' */

COMMIT;

--
-- Ejercicio 9. Agregar el campo usuario a la tabla Histórico. Diseñar un disparador que guarde en la tabla histórico, 
-- los datos pertinentes cuando un socio cambia de plan. Guardar el usuario actual de la Base de Datos en el campo usuario.
--

START TRANSACTION;

-- Modificamos la tabla --
ALTER TABLE historico
    ADD COLUMN usuario varchar(45) NULL COMMENT 'Usuario actual de la BD';

-- Creamos el disparador --
DELIMITER |

CREATE TRIGGER trg_actualizacion_planes_socio
    AFTER UPDATE
    ON socio
    FOR EACH ROW
    BEGIN
        IF EXISTS (
            SELECT *
            FROM historico h
            WHERE h.id_socio = new.id_socio
        ) THEN
        UPDATE historico h
            SET plan_anterior = plan_actual,
            plan_actual = new.id_plan,
            fecha_cambio = CURDATE()
            WHERE h.id_socio = new.id_socio;
        ELSE
            INSERT INTO historico (id_socio, tipo_socio, fecha_cambio, plan_anterior, plan_actual, fecha_alta_plan) VALUES
            (new.id_socio, 0, CURDATE(), id_plan, new.id_plan, CURDATE());
        END IF;
	END|

DELIMITER ;

-- Añadir usuario actual --
UPDATE historico
    SET usuario = CURRENT_USER()
    WHERE id_socio > 0;

/* En cuanto a la creación del disparador: Aquí manejamos 2 escenarios, que le socio ya tenga un registro en histórico o que sea su primer 
* registro. En el primer caso, el disparador actualizará los datos que han cambiado: El plan anterior, el nuevo plan y la fecha del cambio 
* de plan. En el caso de sea el primer registro en histórico, se creará un registro nuevo con los datos esenciales. Aquí he tenido un problema, 
* tipo_socio es un valor NOT NULL, pero la automatización creo que no puede saber qué tipo de socio es ya que depende de qué subclase de socio
* tiene. He probado de escoger el campo realizando un IF ELSE con subqueries, pero o no lo sé hacer o no está permitido, así que
* lo seteo a valor 0 y tendría que cambiarse a mano. La soluciñon que se me ocurre, es modificar la tabla socio para añadir este campo
* para poder ir aa buscarlo allí.
* Por lo que respecta a añadir el usuario de la BD, primero modificamos la tabla para añadir la columna y después la podemos actualizar
* usandola función CURRENT_USER() y recordando que debemos establecer en WHERE un límite relacionado con la PK. */

COMMIT;

--
-- Ejercicio 10. Inventar un disparador.
--

START TRANSACTION;

DELIMITER |

CREATE TRIGGER trg_verificación_socio_adicionales
    BEFORE INSERT
    ON beneficiario 
    FOR EACH ROW 
    BEGIN
        IF EXISTS (
            SELECT * 
            FROM beneficiario b, socio s, plan p
            WHERE s.id_socio = NEW.id_beneficiario AND s.id_plan = p.id_plan AND p.socio_adicional = 'NO')
            THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El plan al que está intentando suscribirse no admite socios adicionales';
        END IF;
    END|


CREATE TRIGGER trg_verificación_update_socios_adicionales
    BEFORE UPDATE
    ON socio 
    FOR EACH ROW 
    BEGIN
        IF EXISTS (SELECT * FROM beneficiario b, socio s, plan p
        WHERE s.id_socio = id_beneficiario AND NEW.id_plan = p.id_plan AND p.socio_adicional = 'NO')
        THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El plan al que está intentando suscribirse no admite socios adicionales';
        END IF;
    END|

DELIMITER ;

/* 
* Creamos un TRIGGER para impedir que un socio beneficiario pueda inscribirse a un plan que no admita este tipo de socios.
* Por tanto declaramos el TRIGGER en la tabla socio_beneficiario para que cuando se inserte un socio benecifiario compruebe el plan en el que está inscrito.
* hacemos un SELECT en el IF EXISTS para comprobar que se cumple la condición para ellos usamos p.socio_adicionales = 'NO',
* ya que no podemos harcodear los id_plan que no lo cumplan.
*
* Hacemos otro TRIGGER para impedir que puedan actualizar, el id_plan de un socio beneficiario, a un plan que no lo permita.
*
*/

COMMIT;

--
-- Ejercicio 11. Agregar a la tabla socio a los miembros del grupo.
--

START TRANSACTION;

-- Tarea individual: 
-- Daniel Boj
INSERT INTO socio (documento_identidad, nombre, apellido1, apellido2, sexo, fecha_nacimiento, id_plan, fecha_alta, 
activo, tarjeta_acceso, telefono_contacto, email, codigo_postal, enfermedades, observaciones) VALUES
    ('47702695M', 'Daniel', 'BOJ', 'COBOS', 'H', '1985-3-6', 5, CURDATE(), 1, 'DABO000101', '653609499', 'dboj@uoc.edu', '22790', 'Diabético Tipo I', 'Kung-Fu' ),
    ('29628232S', 'KATIANE', 'COUTINHO', 'ROSA', 'M', '1986-06-15', 3, CURDATE(), 1, 'KACO00001', '629060465','kcoutinho@uoc.edu', '41700', 'hipotiroidismo', 'Crossfit' ),
    ('47117048F', 'Daniel', 'Zafra', '', 'H', '1993-02-26', 5, CURDATE(), 1, 'DANI65874', '662236541', 'daz1993@gymsport.com', '05045', NULL, 'Sillonball'),
    ('51254544F', 'Miki', 'Alvarez', '', 'H', '1925-05-02', 9, CURDATE(), 1, NULL, '657472808', 'miki@gymsport.com', '38045', NULL, 'Beisbol');


INSERT INTO principal (idsocio, cuenta, banco) VALUES
	((select id_socio FROM socio WHERE documento_identidad = '47702695M'), '01820539763925149920', 'BANCO BBVA'),
    ((select id_socio FROM socio WHERE documento_identidad = '29628232S'), '18205313151925149920', 'SANTANDER'),
    ((select id_socio FROM socio WHERE documento_identidad = '47117048F'), '00011100011100011100', 'BANCO BBVA'),
    ((select id_socio FROM socio WHERE documento_identidad = '51254544F'), '67778890888889876666', 'BANCO SABADELL');


-- Daniel Zafra


-- Miki Alvarez

/* Creamos un socio nuevo en la tabla socio, he escogido el plan 5 que es privado y de acceso 24h, con lo que requiere
* añadir un número de tarjeta. La fecha de alta, la asigno mediante CURDAY() para hacer ver que es el mismo día que se
* ejecuta la inserción. Como es un usuario de tipo privado, añado el registro correspondiente en la tabla 'privado',
* para evitar posibles errores de inserción cuando una este código al de mis compañeros de equipo, uso una subquerie
* para seleccionar el campo id_socio, así capturaré el campo correcto, sea cuál sea la posición en la que se coloque
* la sentencia de inserción de mi socio en relación con la del resto de miembros. */

COMMIT;

--
-- Ejercicio 12. Agregar un socio beneficiario para cada miembro del grupo (Hijo, Pareja, Amigo, Familiar) e indicar 
-- el tipo de descuento que se le aplicará.
--

-- Tarea individual 
-- Daniel Boj
START TRANSACTION;

INSERT INTO socio (documento_identidad, nombre, apellido1, apellido2, sexo, fecha_nacimiento, id_plan, fecha_alta, 
activo, tarjeta_acceso, telefono_contacto, email, codigo_postal, enfermedades, observaciones) VALUES
    ('44423467W', 'Elia', 'GONZALEZ', 'MARTINEZ', 'M', '1980-8-22', 1, CURDATE(), 1, '', '642622209', 'eliag@gmail.com', '22790', '', 'Yoga' ),
    ('45424458L' , 'Manuel' , 'VALENCIA' , 'BENITEZ' , 'H', '1986-05-21' , 1 , CURDATE() , 1 , '' , '639454968' , 'manu@gmail.com', '41700','','ciclismo'),
    ('47122342L', 'Claudia', 'GARCIA', 'CLEMENTE', 'M', '1997-09-18', 1, CURDATE(), 1, NULL, '662256655','clauditarevolution@yahoo.com', '08292', 'Preciositis', 'Trekking'),
    ('05420736G', 'Miguelito', 'Alvarez', '', 'H', '2005-06-12', 1, CURDATE(), 1, NULL, '667586425','migalv@gmail.com', '38045', NULL, 'Escalada');



INSERT INTO beneficiario (id_socio, id_socio_principal_referencia, tipo_descuento, tipo_afiliacion) VALUES
    ((select id_socio FROM socio WHERE documento_identidad = '44423467W'), (select id_socio FROM socio WHERE documento_identidad = '47702695M'), 4, 3),
    ((select id_socio FROM socio WHERE documento_identidad = '45424458L'), (select id_socio FROM socio WHERE documento_identidad = '29628232S'), 1, 3),
    ((select id_socio FROM socio WHERE documento_identidad = '47122342L'), (select id_socio FROM socio WHERE documento_identidad = '47117048F'), 1, 3),
    ((select id_socio FROM socio WHERE documento_identidad = '05420736G'), (select id_socio FROM socio WHERE documento_identidad = '51254544F'), 1, 1);

/* Primero hemos de crear e insertar el nuevo socio en la tabla padre. 'socio'. Luego, creamos el registro en la tabla
* hija indicando que es un amigo y su tipo de afiliación será PAREJA/AMIGO/FAMILIAR, por lo tanto,
* usamos el  tipo de descuento 'Pareja/Amigo/Familiar', el % se calcula automáticamente y será del 20. Para escoger
* el id_usuario que lo relaciona con la tabla principal, uso una subconsulta que arroja mi id_socio. */

COMMIT;

--
-- Ejercicio 13. Insertar un mínimo de 10 registros en la tabla Inscripciones.
--

START TRANSACTION;

INSERT INTO inscripcion (id_actividad, id_socio, fecha_alta, fecha_baja) VALUES
    (1, 32, '2022-10-06', NULL),
    (5, 43, '2022-09-29', '2022-10-15'),
    (7, 13, '2022-09-28', NULL),
    (10, 67, '2022-10-01', NULL),
    (8, 54, '2022-10-10', NULL),
    (2, 23, '2022-09-29', NULL),
    (4, 2, '2022-09-28', '2022-10-22'),
    (6, 17, '2022-10-18', NULL),
    (3, 87, '2022-09-29', NULL),
    (9, 93, '2022-10-21', NULL);

/* Registro múltiple con casos de usuarios que ya se han dado de baja de la actividad. */

COMMIT;
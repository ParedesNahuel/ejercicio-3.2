--1 Hacer un trigger que al ingresar una colaboración obtenga el precio de la misma a partir del
--precio hora base del tipo de tarea. Tener en cuenta que si el colaborador es externo el costo
--debe ser un 20% más caro.


CREATE TRIGGER tr_PrecioColaboracionIngresante ON colaboraciones
AFTER INSERT
AS 
BEGIN--1
--DECLARANDO EL VALOR DEL PRECIOHORABASE DE TIPOTAREA
DECLARE @preciohorabase money
DECLARE @IDTarea int
DECLARE @IDColaborador INT
DECLARE @Tipocolaborador char
SELECT @IDColaborador=IDColaborador FROM INSERTED 

SET @IDTarea = (SELECT IDTarea FROM inserted)

SET @preciohorabase = (SELECT PrecioHoraBase FROM TiposTarea AS TT
INNER JOIN Tareas AS T ON T.IDTipo= TT.ID
WHERE T.ID= @IDTarea
)

SELECT @Tipocolaborador=Tipo FROM Colaboradores
WHERE ID=@IDColaborador

IF @Tipocolaborador = 'E' BEGIN--2

SET @preciohorabase= @preciohorabase *1.2

END--2

UPDATE Colaboraciones SET PRECIOHORA = @preciohorabase
WHERE @IDColaborador= IDColaborador AND @IDTarea= IDTarea

END--1
go

insert into Colaboraciones
(
IDColaborador ,
IDtarea,
tiempo,
preciohora,
estado
)
VALUES
(39,50,49,3249,1)
GO

SELECT * FROM Colaboraciones
WHERE IDTarea =50 and idcolaborador=39
GO

--2 Hacer un trigger que no permita que un colaborador registre más de 15 tareas en
-- un mismo mes. De lo contrario generar un error con un mensaje aclaratorio

select c1.idcolaborador, count(c1.IDTarea) from Colaboraciones as c1
where (
select count (c2.IDTarea) from Colaboraciones as c2
where  c2.IDColaborador= c1.IDColaborador
)>15
group by c1.idcolaborador
GO


CREATE TRIGGER tr_TareasdeColaborador on colaboraciones 
INSTEAD OF INSERT 
AS
BEGIN--1
--seleccionar al colaborador Y FECHA DE LA TAREA
DECLARE @IDCOLABORADOR INT = (SELECT IDColaborador FROM inserted)
DECLARE @FECHANUEVA DATE

SELECT @FECHANUEVA =T.FechaInicio  FROM INSERTED
INNER JOIN Tareas AS T ON T.ID= IDTarea
WHERE IDColaborador= @IDCOLABORADOR

--contar los registros del mismo
DECLARE @TAREASCONTADAS SMALLINT

SELECT @TAREASCONTADAS= COUNT (IDTarea) FROM INSERTED AS C 
INNER JOIN TAREAS T ON T.ID= C.IDTarea
WHERE IDColaborador= @IDCOLABORADOR AND MONTH(T.FECHAINICIO)= MONTH (@FECHANUEVA) AND YEAR(T.FechaInicio)= YEAR(@FECHANUEVA)

--si son mas de 15 mostrar error

IF @TAREASCONTADAS >15
BEGIN
RAISERROR ( 'EL COLABORADOR ALCANZO EL MAX DE TAREAS A COLABORAR EN EL MES',15,1)
END

END--1
GO

SELECT T.FechaInicio FROM Colaboraciones AS C1
INNER JOIN Tareas AS T ON C1.IDTarea= T.ID
WHERE C1.IDColaborador = 29 AND YEAR( T.FechaInicio)=2020-- AND MONTH(T.FechaInicio)=10
GO

SELECT * FROM Colaboraciones AS C1
INNER JOIN Tareas AS T ON C1.IDTarea= T.ID
WHERE C1.IDColaborador = 29 AND YEAR( T.FechaInicio)=2018 AND MONTH(T.FechaInicio)=10
GO
--TIENE 9
INSERT INTO Colaboraciones (IDTarea,IDColaborador,Tiempo,PrecioHora,Estado)
VALUES (70,29,53,2,1)


INSERT INTO Colaboraciones (IDTarea,IDColaborador,Tiempo,PrecioHora,Estado)
VALUES (38,29,53,2,1)


INSERT INTO Colaboraciones (IDTarea,IDColaborador,Tiempo,PrecioHora,Estado)
VALUES (50,29,40,2,1)

INSERT INTO Colaboraciones (IDTarea,IDColaborador,Tiempo,PrecioHora,Estado)
VALUES (61,29,12,2,1)


INSERT INTO Colaboraciones (IDTarea,IDColaborador,Tiempo,PrecioHora,Estado)
VALUES (42,29,31,2,1)

INSERT INTO Colaboraciones (IDTarea,IDColaborador,Tiempo,PrecioHora,Estado)
VALUES (39,29,53,2,1)


INSERT INTO Colaboraciones (IDTarea,IDColaborador,Tiempo,PrecioHora,Estado)
VALUES (66,29,27,2,1)


INSERT INTO Colaboraciones (IDColaborador,IDTarea,Tiempo,PrecioHora,Estado)
VALUES (29,53,40,2,1)

go

--3 Hacer un trigger que al ingresar una tarea cuyo tipo contenga el nombre
-- 'Programación' se agreguen automáticamente dos tareas de tipo 'Testing unitario' y 
--'Testing de integración' de 4 horas cada una. La fecha de inicio y fin de las 
--mismas debe ser NULL. Calcular el costo estimado de la tarea

CREATE TRIGGER tr_TareaProgramacion ON Tareas
AFTER INSERT
AS
BEGIN--1

--revisar si el tipo de tarea es PROGRAMACION 

DECLARE @TIPOTAREA SMALLINT 

SELECT @TIPOTAREA= IDTIPO FROM inserted

DECLARE @NOMBRETIPO VARCHAR

SELECT @NOMBRETIPO= Nombre FROM TiposTarea
WHERE @TIPOTAREA=ID

IF @NOMBRETIPO LIKE '%PROGRAMACION%'
BEGIN--2

DECLARE @IDMODULO INT = (SELECT IDModulo FROM inserted)
DECLARE @idTIPO SMALLINT = (SELECT IDTipo FROM inserted)


--agregar tareas TESTING UNITARIO Y TESTING DE INTEGRACION de 4h de trabajo
INSERT INTO Tareas(idmodulo,idtipo,estado)
VALUES (@IDMODULO,@idTIPO,1)
--fechas de inicio y fin son null
END--2


END--1
GO

--4 Hacer un trigger que al borrar una tarea realice una baja lógica de la 
-- misma en lugar de una baja física.

--en vez de borrar baja logica

CREATE TRIGGER TR_BorrarTarea ON Tareas
INSTEAD OF DELETE
AS
BEGIN--1

--buscar el id de la tarea a borrar
DECLARE @IDtarea int

SELECT @IDtarea = ID FROM deleted

--modificar el estado 

UPDATE Tareas SET Estado=0
WHERE ID= @IDtarea
-- guardar el cambio

END--1

delete Tareas where ID = 198
GO

--5) Hacer un trigger que al borrar un módulo realice una baja lógica
-- del mismo en lugar de una baja física. Además, debe borrar todas 
--las tareas asociadas al módulo.

--buscar el modulo
CREATE TRIGGER tr_BorrarModulo on Modulos
INSTEAD OF DELETE
AS
BEGIN--1
DECLARE @IDmodulo int
select @IDmodulo = ID from deleted
--dar de baja el modulo

UPDATE Modulos SET Estado= 0 WHERE @IDmodulo = ID

--dar de baja todas las tareas
UPDATE Tareas SET Estado =0 WHERE @IDmodulo = IDModulo

END --1
go

--6 Hacer un trigger que al borrar un proyecto realice una baja lógica del 
--mismo en lugar de una baja física. Además, debe borrar todas los módulos 
--asociados al proyecto.

CREATE TRIGGER tr_BorrarProyecto ON proyectos
INSTEAD OF DELETE
AS
BEGIN
DECLARE @IDproyecto varchar

SELECT @IDproyecto = ID FROM deleted

UPDATE Proyectos SET Estado = 0 WHERE @IDproyecto = ID

UPDATE MODULOS SET Estado=0 WHERE IDProyecto= @IDproyecto

END
GO

--7 Hacer un trigger que si se agrega una tarea cuya fecha de fin es mayor a
-- la fecha estimada de fin del módulo asociado a la tarea entonces se
-- modifique la fecha estimada de fin en el módulo.

CREATE TRIGGER TR_ActualizarFEFModulo on Tareas
INSTEAD OF INSERT
AS
BEGIN
-- VARIABLE FECHA DE TAREA
DECLARE @FECHATAREA DATE
DECLARE @IDMODULO INT

SELECT @FECHATAREA = FechaFin FROM inserted
SELECT @IDMODULO = IDModulo FROM inserted
--VARIABLE FECHA DEL MODULO
DECLARE @FECHAMODULO DATE
SELECT @FECHAMODULO = FechaEstimadaFin FROM Modulos
--MODIFICAR LA FECHA DEL MODULO POR LA FECHA DE TAREA

IF @FECHATAREA > @FECHAMODULO
BEGIN
UPDATE Modulos SET FechaEstimadaFin = @fechatarea
where @IDMODULO= ID
END


END
GO
--8 Hacer un trigger que al borrar una tarea que previamente se ha dado
-- de baja lógica realice la baja física de la misma.

CREATE TRIGGER TR_borrarTareaDrop ON TAREAS
INSTEAD OF DELETE 
AS
BEGIN
--buscar tarea que tenga estado 0
DECLARE @ESTADO BIT
DECLARE @IDTarea INT

SELECT @ESTADO = ESTADO FROM deleted

SELECT @IDTarea = ID FROM deleted

	IF @ESTADO = 0 BEGIN
	-- hacer el drop
	DELETE  FROM Tareas WHERE @IDTarea= ID AND @ESTADO= Estado
	
	END 
	else
	
	raiserror('no se pudo borrar porque no se dio de baja antes',12,2)
	
--mensaje de error
END
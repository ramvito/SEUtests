# Como usarlo
1- Descargar el fichero SEUtests.sh

2- Meterlo en el directorio del proyecto descargado de la web de la asignatura: /SEU/usuario/

3- Dar permisos de ejecución:
```{bash}
chmod +x SEUtests.sh
```
4- Ejecutar:
```{bash}
./SEUtests.sh
```

4- Seleccionar:
```{bash}
1) Fase4
2) Fase5
3) Fase6
# Para seleccionar hay que elegir el número de la opción, no el nombre de la opción (e.g. si ponemos 1 seleccionamos la Fase4). Lo siento, bash es así de feo :(
```



# Cosas a tener en cuenta
- El script solo contempla las fases 4, 5 y 6 del proyecto. Esto es porque las pruebas de las 3 primeras fases son con prints que cada uno puede poner como quiera.
- Este script solo lanza los distintos casos de prueba que se plantean en el enunciado para cada una de las fases. Por tanto, **una vez lanzada la prueba con el script hay que mirar el dmesg** (o escuchar los pitidos) para ver si el código funciona correctamente.
	- Algunas pruebas si que lanzan el dmesg (tengo pensado ponerlo para que lo muestren todas las pruebas)
	- Algunas pruebas si que comprueban que el código está funcionando bien y no es necesario revisar el dmesg (muestran mensajes en verde si todo ha ido bien o en rojo donde haya fallado).
- Los parametros que se pasan al cargar el modulo tienen que llamarse buffer_size y buffer_threshold (como pone en el enunciado).
- **Cualquier fallo que veais o que creais que se pueda mejorar haced un push con los cambios o abrid una issue (nada de doodles XD).**

Last updated: _04/11/2016
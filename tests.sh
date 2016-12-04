#!/bin/bash

#
# This file is part of the SEUtests distribution (https://github.com/ramvito/SEUtests.git).
# Copyright (c) 2015 Victor Ramperez.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

MODULE="spkr"

fases=("Fase4" "Fase5" "Fase6" "Fase7" "Quit")

function setUp {

    lsmod | grep "$MODULE" &> /dev/null
    if [ $? == 0 ]; then
        rmmod spkr
    fi

    dmesg --clear
}

function tearDown {

    echo "Descargando el modulo..."

    lsmod | grep "$MODULE" &> /dev/null
    if [ $? == 0 ]; then
        echo quitando
        rmmod spkr
    fi
}

function init {
    echo "Elija una fase del proyecto: (las pruebas de las 3 primeras fases son muy artesanales y cada uno debe probarlas como considere [ver enunciado])"

    select opt in "${fases[@]}"; do

        case $opt in

            "Fase4")
                fase4
                ;;
            "Fase5")
                fase5
                ;;
            "Fase6")
                fase6
                ;;
            "Quit")
                tearDown
                break
                ;;
            *)
                echo Invalid option
        esac
    done
}

function fase4 {

    tests=("1" "2" "3" "4" "5_1" "5_2" "6_1" "6_2" "7_1" "7_2" "8" "9_1" "9_2" "10" "Volver a selección de fase")

    TEST1="1. Esta prueba comprueba si se procesa correctamente un único sonido (la primera nota de la sintonía de Los Simpsons)."
    TEST2="2. En esta prueba se genera el mismo sonido pero realizando dos escrituras de dos bytes. El comportamiento dede ser el mismo que la prueba anterior."
    TEST3="3. Esta prueba genera los 8 primeros sonidos del fichero songs.bin usando 8 escrituras y dejando tanto el tamaño del buffer como del umbral en sus valores por defecto. La primera escritura debe activar el primer sonido y las restantes deben devolver el control inmediatamente. Con dmesg se debe apreciar que, exceptuando el primer sonido, los demás son programados en el contexto de la rutina de tratamiento del temporizador. "
    TEST4="4. La misma prueba que la anterior pero con una única escritura, que debe completarse inmediatamente."
    TEST5_1="5_1. Esta prueba intenta comprobar que se tratan adecuadamente las pausas o silencios que aparecen en una secuencia. Para ello, se van a generar los 20 primeros sonidos, donde aparecen dos pausas. Debe comprobarse que el altavoz se desactiva al tratar esas pausas y que se reactiva al aparecer nuevamente sonidos convencionales en la secuencia. Se va a probar con escrituras de 4 bytes y con una única escritura: "
    TEST5_2="5_2. Lo mismo que la prueba anterior pero con una única escritura"
    TEST6_1="6_1. Esta prueba va a forzar que se llene la cola pero no va a definir ningún umbral. Para llevarla a cabo, se debe cargar el módulo especificando un tamaño de buffer de 32. A continuación, se va ejecutar una prueba que genere 20 sonidos. En primer lugar, con escrituras de 4 bytes: "
    TEST6_2="6_2. Lo mismo que la prueba anterior pero con una única escritura de 80 bytes"
    TEST7_1="7_1. Esta prueba comprueba el funcionamiento del umbral. Para ello, se repetirá la anterior (programa que genera 20 sonidos) pero especificando un tamaño de umbral de 16 bytes. La prueba que realiza escrituras de 4 bytes no se verá afectada por el cambio"
    TEST7_2="7_2. Lo mismo que la prueba 6_2 pero se bloqueará 3 veces, en lugar de 2"
    TEST8="8. Aunque se podrían probar múltiples situaciones de error, vamos a centrarnos sólo en una: la dirección del buffer de la operación write no es válida y, por tanto, esta llamada debe retornar el error -EFAULT. La prueba consiste simplemente en ejecutar el programa error proporcionado como material de apoyo."
    TEST9_1="9_1. Esta es una prueba de esfuerzo (usa los valores por defecto de todos los parámetros): se reproduce todo el fichero de canciones usando escrituras de 4 bytes: "
    TEST9_2="9_2. Lo mismo que la prueba anterior pero usando escrituras de 4KiB: "
    TEST10="10. En esta prueba, que también usa los valores por defecto de todos los parámetros, se va a comprobar que cuando se descarga el módulo justo después de completarse la aplicación, se hace de forma correcta deteniendo el procesamiento de sonidos y dejando en silencio el altavoz."

    echo "Elija un test: "

    select test in "${tests[@]}"; do

        case $test in

            "1")
                echo "$TEST1"
                setUp
                insmod ../kernel/spkr.ko
                dd if=songs.bin of=/dev/intspkr bs=4 count=1
                ;;

            "2")
                echo "$TEST2"
                setUp
                insmod ../kernel/spkr.ko
                dd if=songs.bin of=/dev/intspkr bs=2 count=2
                ;;

            "3")
                echo "$TEST3"
                setUp
                insmod ../kernel/spkr.ko
                dd if=songs.bin of=/dev/intspkr bs=4 count=8
                ;;

            "4")
                echo "$TEST4"
                setUp
                insmod ../kernel/spkr.ko
                dd if=songs.bin of=/dev/intspkr bs=32 count=1
                ;;

            "5_1")
                echo "$TEST5_1"
                setUp
                insmod ../kernel/spkr.ko
                dd if=songs.bin of=/dev/intspkr bs=4 count=20
                ;;

            "5_2")
                echo "$TEST5_2"
                setUp
                insmod ../kernel/spkr.ko
                dd if=songs.bin of=/dev/intspkr bs=80 count=1
                ;;

            "6_1")
                echo "$TEST6_1"
                setUp
                insmod ../kernel/spkr.ko buffer_size=32
                dd if=songs.bin of=/dev/intspkr bs=4 count=20

                echo "Debe comprobar con dmesg como la llamada de escritura que encuentra la cola llena se bloquea y que, cada vez que completa el procesado de un sonido, se desbloquea al proceso escritor puesto que, al realizar operaciones de 4 bytes, ya tiene sitio en la cola para completar la llamada y ejecutar en paralelo con el procesamiento de los sonidos previos."
                ;;

            "6_2")
                echo "$TEST6_2"
                setUp
                insmod ../kernel/spkr.ko buffer_size=32
                dd if=songs.bin of=/dev/intspkr bs=80 count=1

                echo "En este caso, debe comprobar cómo en la operación de escritura se producen sólo dos bloqueos. "
                ;;

            "7_1")
                echo "$TEST7_1"
                setUp
                insmod ../kernel/spkr.ko buffer_size=32 buffer_threshold=16
                dd if=songs.bin of=/dev/intspkr bs=4 count=20

                echo "Debe comprobar con dmesg como la llamada de escritura que encuentra la cola llena se bloquea y que, cada vez que completa el procesado de un sonido, se desbloquea al proceso escritor puesto que, al realizar operaciones de 4 bytes, ya tiene sitio en la cola para completar la llamada y ejecutar en paralelo con el procesamiento de los sonidos previos."
                ;;

            "7_2")
                echo "$TEST7_2"
                setUp
                insmod ../kernel/spkr.ko buffer_size=32 buffer_threshold=16
                dd if=songs.bin of=/dev/intspkr bs=80 count=1

                echo "En este caso, debe comprobar cómo en la operación de escritura se producen 3 bloqueos. "
                ;;

            "8")
                echo "$TEST8"
                setUp
                insmod ../kernel/spkr.ko
                ./error
                ;;

            "9_1")
                echo "$TEST9_1"
                echo "Esta prueba puede tardar mucho (varios minutos)"
                setUp
                insmod ../kernel/spkr.ko
                dd if=songs.bin of=/dev/intspkr bs=4
                ;;

            "9_2")
                echo "$TEST9_2"
                echo "Esta prueba puede tardar mucho (varios minutos)"
                setUp
                insmod ../kernel/spkr.ko
                dd if=songs.bin of=/dev/intspkr bs=4096
                ;;

            "10")
                echo "$TEST10"
                setUp
                insmod ../kernel/spkr.ko
                dd if=songs.bin of=/dev/intspkr bs=4096 count=1
                sleep 1
                rmmod spkr
                ;;

            "Volver a selección de fase")
                init
                break
                ;;
            *)
                echo Invalid option
        esac
    done
}

function fase5 {

    tests=("1" "2" "Volver a selección de fase")

    TEST1="1. Teniendo el módulo cargado con los valores por defecto, se va a ejecutar el siguiente mandato que hace una llamada fsync justo antes del close (nótese el uso del strace para comprobar que se bloquea la llamada fsync), primero con 20 escrituras de 4 bytes"
    TEST2="2. y luego con 1 de 80: "

    echo "Elija un test: "

    select test in "${tests[@]}"; do

        case $test in

            "1")
                echo "$TEST1"
                setUp
                insmod ../kernel/spkr.ko
                strace dd if=songs.bin of=/dev/intspkr bs=4 count=20 conv=fsync
                ;;

            "2")
                echo "$TEST2"
                setUp
                insmod ../kernel/spkr.ko
                strace dd if=songs.bin of=/dev/intspkr bs=80 count=1 conv=fsync
                ;;

            "Volver a selección de fase")
                init
                break
                ;;
            *)
                echo Invalid option
        esac
    done
}

# Start
init
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

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

MODULE="spkr"

fases=("Fase2" "Fase4" "Fase5" "Fase6" "Quit")

function setUp {

    lsmod | grep "$MODULE" &> /dev/null
    if [ $? == 0 ]; then
        rmmod spkr
    fi

    dmesg --clear
}

function tearDown {

    printf "${BLUE}Descargando el modulo...{$NC}\n"

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

            "Fase2")
                fase2
                ;;
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

function fase2_aux {

    printf "${BLUE}comprobando que se ha creado la entrada correcta en /proc/devices ${NC} \n"
    cat /proc/devices | grep "spkr"

    if [ $? == 0 ]; then
        printf "${GREEN}OK${NC} \n"
    else
        printf "${RED}Error${NC} \n"
    fi

    printf "${BLUE}comprobando: ls -l /sys/class/speaker/intspkr /dev/intspkr${NC} \n"
    ls -l /sys/class/speaker/intspkr /dev/intspkr

    if [ $? == 0 ]; then
        printf "${GREEN}OK${NC} \n"
    else
        printf "${RED}Error${NC} \n"
    fi

    printf "${BLUE}comprobando que el minor por defecto es 0${NC} \n"
    RES=$(stat -c %T /dev/intspkr)

    if [ $RES == $1 ]; then
        printf "${GREEN}OK${NC} \n"
    else
        printf "${RED}Error${NC} \n"
    fi

    printf "${BLUE}Eliminando el dispositivo: rmmod spkr${NC} \n"
    rmmod spkr

    printf "${BLUE}comprobando que se ha eliminado la entrada correcta en /proc/devices ${NC} \n"
    cat /proc/devices | grep "spkr"

    if [ $? != 0 ]; then
        printf "${GREEN}OK${NC} \n"
    else
        printf "${RED}Error${NC} \n"
    fi

    printf "${BLUE}comprobando que se ha eliminado: ls -l /sys/class/speaker/intspkr /dev/intspkr${NC} \n"
    ls -l /sys/class/speaker/intspkr /dev/intspkr

    if [ $? != 0 ]; then
        printf "${GREEN}OK${NC} \n"
    else
        printf "${RED}Error${NC} \n"
    fi
}

function fase2 {

    tests=("1" "2" "3" "Volver a selección de fase")

    TEST1="1. Test que prueba que el modulo se registra correctamente con el minor por defecto (0) y se elimina correctamente"
    TEST2="2. Test que prueba que el modulo se registra correctamente con el minor especificado (1)"
    TEST3="3. Test que prueba las operaciones de apertura, escritura y cierre"

    MINOR=0

    echo "Elija un test: "

    select test in "${tests[@]}"; do

        case $test in

            "1")
                echo "$TEST1"
                setUp
                insmod ../kernel/spkr.ko

                fase2_aux 0

                ;;

            "2")
                echo "$TEST2"
                setUp
                insmod ../kernel/spkr.ko minor=1

                fase2_aux 1

                ;;

            "3")
                echo "$TEST3"
                setUp
                insmod ../kernel/spkr.ko
                echo X > /dev/intspkr
                rmmod spkr

                printf "${BLUE}Salida dmesg tras la prueba...(comprobar la traza, prints)${NC} \n"
                dmesg
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
                printf "${RED}OJO:${NC} Esta prueba puede tardar mucho (varios minutos)\n"
                setUp
                insmod ../kernel/spkr.ko
                dd if=songs.bin of=/dev/intspkr bs=4
                ;;

            "9_2")
                echo "$TEST9_2"
                printf "${RED}OJO:${NC} Esta prueba puede tardar mucho (varios minutos)\n"
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

function fase6 {

    tests=("1" "2" "3" "4" "Volver a selección de fase")

    TEST1="1. Esta prueba intenta comprobar si se gestiona correctamente el estado del mute: "
    TEST2="2. La siguiente prueba va realizando operaciones que enmudecen y desenmudecen el altavoz en distintas circunstancias (en momentos donde se están reproduciéndos sonidos y en momentos en los que no). Para comprobar si la evolución del estado del altavoz es correcta, se recomienda revisar el log del núcleo con dmesg al final de cada etapa y el borrado del mismo antes de comenzar la siguiente. "
    TEST3="3. Esta prueba se centra en el comportamiento de la operación mute cuando coincide con la reproducción de pausas. (se espera 5 segundos entre una prueba y otra)"
    TEST4="4. Debe comprobarse que de los 20 primeros sonidos, debido al reset, sólo se procesa uno, mientras que la segunda tanda de 20 sonidos se procesa de forma normal. "

    printf "${RED}OJO: ${NC}"
    echo "Antes de comenzar con las pruebas, debe modificar los programas setmute, getmute y reset para incluir en los mismos las definiciones de las operaciones ioctl correspondientes tal como se han definido en el módulo. Recuerde que, como se comentó previamente, el programa reset no sólo incluye la llamada ioctl sino que, a continuación, invoca la llamada fsync, lo que asegura que al finalizar el programa el vaciado se ha completado. "
    echo "Elija un test: "

    select test in "${tests[@]}"; do

        case $test in

            "1")
                echo "$TEST1"
                setUp
                insmod ../kernel/spkr.ko

                getmute=$(./getmute)
                echo "./getmute"
                if [ "$getmute" == "mute off" ]; then
                    printf "${GREEN}OK${NC}\n"
                else
                    printf "${RED}MAL${NC}\n"
                fi

                echo "./setmute 1"
                ./setmute 1

                echo "./getmute"
                getmute2=$(./getmute)
                if [ "$getmute2" == "mute on" ]; then
                    printf "${GREEN}OK${NC}\n"
                else
                    printf "${RED}MAL${NC}\n"
                fi

                echo "./setmute 0"
                ./setmute 0

                echo "./getmute"
                getmute3=$(./getmute)
                if [ "$getmute3" == "mute off" ]; then
                    printf "${GREEN}OK${NC}\n"
                else
                    printf "${RED}MAL${NC}\n"
                fi

                ;;

            "2")

                setUp
                insmod ../kernel/spkr.ko
                ./setmute 1
                dd if=songs.bin of=/dev/intspkr bs=48 count=1
                sleep 1
                ./setmute 0
                sleep 1
                ./setmute 1
                echo etapa1
                read v
                dd if=songs.bin of=/dev/intspkr bs=48 count=1
                echo etapa2
                read v
                ./setmute 0
                dd if=songs.bin of=/dev/intspkr bs=48 count=1

                ;;

            "3")
                echo "$TEST3"

                printf "${RED}OJO: ${NC}"
                echo "Este test esta programado para mostrar el dmesg entre etapas y borrarlo para facilitar la comprobación de la prueba"
                setUp
                insmod ../kernel/spkr.ko

                printf "${BLUE}Iniciando Etapa 1...${NC}\n"
                ./setmute 0; dd if=songs.bin of=/dev/intspkr bs=40 count=1 skip=1; sleep 1; ./setmute 0
                sleep 5 # TODO: revisar si es tiempo suficiente
                printf "${BLUE}Dmesg tras etapa 1: ${NC}\n"
                dmesg
                dmesg --clear

                printf "${BLUE}Iniciando Etapa 2...${NC}\n"
                ./setmute 0; dd if=songs.bin of=/dev/intspkr bs=40 count=1 skip=1; sleep 1; ./setmute 1
                sleep 5 # TODO: revisar si es tiempo suficiente
                printf "${BLUE}Dmesg tras etapa 2: ${NC}\n"
                dmesg
                dmesg --clear

                printf "${BLUE}Iniciando Etapa 3...${NC}\n"
                ./setmute 1; dd if=songs.bin of=/dev/intspkr bs=40 count=1 skip=1; sleep 1; ./setmute 0
                sleep 5 # TODO: revisar si es tiempo suficiente
                printf "${BLUE}Dmesg tras etapa 3: ${NC}\n"
                dmesg
                dmesg --clear

                printf "${BLUE}Iniciando Etapa 4...${NC}\n"
                ./setmute 1; dd if=songs.bin of=/dev/intspkr bs=40 count=1 skip=1; sleep 1; ./setmute 0
                sleep 5 # TODO: revisar si es tiempo suficiente
                printf "${BLUE}Dmesg tras etapa 4: ${NC}\n"
                dmesg

                ;;

            "4")
                echo "$TEST4"
                setUp
                insmod ../kernel/spkr.ko
                dd if=songs.bin of=/dev/intspkr bs=80 count=1; ./reset; dd if=songs.bin of=/dev/intspkr bs=80 count=1 skip=1
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
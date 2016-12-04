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

fases=("Fase1" "Fase2" "Fase3" "Fase4" "Fase5" "Fase6" "Fase7" "Quit")

function setUp {
    dmesg --clear

    lsmod | grep "$MODULE" &> /dev/null
    if [ $? == 0 ]; then
        rmmod spkr
    fi
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
    echo "Elija una fase del proyecto: "

    select opt in "${fases[@]}"; do

        case $opt in

            "Fase4")
                fase4
                ;;
            "Fase5")
                fase5
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

    tests=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "Volver a selección de fase")

    TEST1="1. Esta prueba comprueba si se procesa correctamente un único sonido (la primera nota de la sintonía de Los Simpsons)."
    TEST10="1. En esta prueba, que también usa los valores por defecto de todos los parámetros, se va a comprobar que cuando se descarga el módulo justo después de completarse la aplicación, se hace de forma correcta deteniendo el procesamiento de sonidos y dejando en silencio el altavoz."

    echo "Elija un test: "

    select test in "${tests[@]}"; do

        case $test in

            "1")
                echo "$TEST1"
                setUp
                insmod ../kernel/spkr.ko
                dd if=songs.bin of=/dev/intspkr bs=4 count=1
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

// Start
init
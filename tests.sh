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
            "Quit")
                echo por la Q
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

    echo "Elija un test: "

    select test in "${tests[@]}"; do

        case $test in

            "1")
                echo "$TEST1"
                setUp
                insmod ../kernel/spkr.ko
                dd if=songs.bin of=/dev/intspkr bs=4 count=1
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
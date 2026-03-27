#!/bin/bash

MAX_WIDTH=11

for part in "Tiers" "Trunk" "Base"; do
    if [ "$part" == "Tiers" ]; then
        for (( tier=1; tier<=3; tier++ )); do
            if [ $tier -eq 1 ]; then
                current_w=1
            else
                current_w=3
            fi

            while [ $current_w -le 9 ]; do
                spaces=$(( (MAX_WIDTH - current_w) / 2 ))
                s_count=0
                while [ $s_count -lt $spaces ]; do
                    echo -n " "
                    s_count=$((s_count + 1))
                done

                h_count=0
                until [ $h_count -ge $current_w ]; do
                    echo -n "#"
                    h_count=$((h_count + 1))
                done

                echo ""
                current_w=$((current_w + 2))
            done
        done
    elif [ "$part" == "Trunk" ]; then
        t_rows=0
        while [ $t_rows -lt 2 ]; do
            for (( s=0; s<4; s++ )); do echo -n " "; done
            for (( h=0; h<3; h++ )); do echo -n "#"; done
            echo ""
            t_rows=$((t_rows + 1))
        done
    else
        b_count=0
        until [ $b_count -ge $MAX_WIDTH ]; do
            echo -n "#"
            b_count=$((b_count + 1))
        done
        echo ""
    fi
done
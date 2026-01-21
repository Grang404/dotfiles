#!/usr/bin/env bash

dir="$HOME/.config/rofi"
theme='groobofi'

## Run
rofi \
	-show drun \
	-theme "${dir}/${theme}.rasi"

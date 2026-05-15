#!/bin/sh
printf '\033c\033]0;%s\a' VampSur
base_path="$(dirname "$(realpath "$0")")"
"$base_path/HunterSurvivors.x86_64" "$@"

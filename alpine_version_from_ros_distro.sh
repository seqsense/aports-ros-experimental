#!/bin/bash

case "$(basename ${1})" in
  kinetic ) echo 3.7;;
  melodic ) echo 3.8;;
  noetic) echo 3.11;;
  * ) exit 1;;
esac

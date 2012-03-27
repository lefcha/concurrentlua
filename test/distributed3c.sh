#!/bin/sh

for i in register2c monitor2c link2c trapexit2c; do
	sleep 4
	echo running $i.lua
	lua distributed/$i.lua
	echo
done

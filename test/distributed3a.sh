#!/bin/sh

for i in register2a monitor2a link2a trapexit2a; do
	echo running $i.lua
	lua distributed/$i.lua
	echo
done

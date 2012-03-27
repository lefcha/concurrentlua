#!/bin/sh

for i in register2b monitor2b link2b trapexit2b; do
	sleep 2
	echo running $i.lua
	lua distributed/$i.lua
	echo
done

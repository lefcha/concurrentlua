#!/bin/sh

for i in process1b process2b message1b register1b monitor1b link1b trapexit1b \
	 node1b cookie1b cookie2b
do
	sleep 5
	echo running $i.lua
	lua distributed/$i.lua
	echo
done

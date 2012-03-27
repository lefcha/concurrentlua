#!/bin/sh

for i in process1 process2 message1 register1 register2 monitor1 monitor2 \
	 link1 link2 trapexit1 trapexit2
do
	sleep 1
	echo running $i.lua
	lua concurrent/$i.lua
	echo
done

#!/bin/sh

for i in process1a process2a message1a register1a monitor1a link1a trapexit1a \
	 node1a cookie1a cookie2a
do
	echo running $i.lua
	lua distributed/$i.lua
	echo
done

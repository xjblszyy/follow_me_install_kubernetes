#!/bin/bash

for name in $NODE_NAMES
do
	echo ">>> $name "
	scp $1 $name:./
	ssh $name "bash $1"
done

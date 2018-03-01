#!/bin/bash

if [ -d "res" ]; then
	echo "res exist"
else
	ln -s ../application/res res
	ln -s ../application/updater updater
	cd src
	ln -s ../../application/src/app app
	ln -s ../../application/src/battle battle
	cd ..
	# cocos, src are exist in engine
	ln -s cocos cocos_x64
	ln -s src src_x64
	ln -s ../application/updater updater_x64
	echo "mklink res ok"
fi

cd ../../tools/csv2lua/
python csv2lua_dev.py

cd ../../client/game01_new/
cp -R -f ../../tools/csv2lua/config/ ./src/config/

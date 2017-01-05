#!/bin/sh
col=$(($(tput cols)-6))
ip=8.8.8.8
#ip=192.168.0.1
symbol="="

blue="\e[1;34m"
green="\e[1;34m"
yellow="\e[1;34m"
red="\e[1;34m"

bLine=$(($col/10))
gLine=$(($(($col/4))-$bLine))
yLine=$(($(($col/2))-$gLine-$bLine))
#lost=($(for i in {1..60}; do echo 0; done))
clear

getLatency(){
	ping $ip -c1 -W1 -w1 | grep ttl | sed s/.*=// 2>/dev/null| awk '{print $1}' | sed 's/\..*//'
}
line(){
	for i in $(seq 1 $1); do echo -n $symbol; done
}
colorLine(){
	if [ "$dots" -gt $1 ]; then
		for i in $(seq 1 $1); do echo -n $symbol; done
		dots=$(($dots-$1))
		echo -en $2
	fi
}
updateLost(){
	lost=(${lost[@]} $1)
	if [ ${#lost[@]} -gt 60 ]; then
		lost=(${lost[@]:1})
	fi
}
lostSum(){
	sum=0
	for i in ${lost[@]}; do
		let sum+=$i
	done
	echo "$(printf "%03d" $(($sum*100/${#lost[@]})))%"
}

while true; do
	loss=0
	lat=0
	sleep=2000

	lat=$(getLatency)
	if [ "$lat" ]; then
		sleep=$(($sleep-$lat))
		updateLost 0
	else
		loss=1
		updateLost 1
	fi
	lat2=$(getLatency)
	if [ "$lat2" ]; then
		if [ "$lat" ]; then
			lat=$(($(($lat+$lat2))/2))
		else
			lat=0
		fi
		sleep=$(($sleep-$lat))
		updateLost 0
	else
		loss=$(($loss+1))
		updateLost 1
	fi

	sleep $(python -c "print ($sleep/1000)")

	echo -en "\e[1;37m"
	echo -n $(lostSum); echo -n " "
	echo -en "\e[1;34m"
	if [ $loss -ge 1 ]; then
		line $(($bLine-1)); echo -ne "\e[1;32m"
		line $gLine; echo -ne "\e[1;33m"
		line $yLine; echo -ne "\e[1;31m"
		line $(($col-$yLine-$gLine-$bLine-1))
		echo -n '>'
	else
		dots=$(($lat*$col/1000))
		colorLine $bLine "\e[1;32m"
		colorLine $gLine "\e[1;33m"
		colorLine $yLine "\e[1;31m"
		for i in $(seq 1 $dots); do echo -n $symbol; done
	fi
	echo
done

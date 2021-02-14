#!/usr/bin/env bash

log_success() {
	text="$1"
	level=$(convert_string_number "$2")
	local prefix
	for _ in $(seq 1 1 "$level");do
		prefix+="\t"
	done

	echo -e "$prefix\e[32;1mSUCCESS: \e[0m${text}"
}

log_fail() {
	text="$1"
	level=$(convert_string_number "$2")
	local prefix
	for _ in $(seq 1 1 "$level");do
		prefix+="\t"
	done

	echo -e "$prefix\e[31;1mFAIL: \e[0m${text}"
}

log_info() {
	text="$1"
	level=$(convert_string_number "$2")
	local prefix
	for _ in $(seq 1 1 "$level");do
		prefix+="\t"
	done
	echo -e "$prefix\e[1;33;1mINFO: \e[0m${text}"
}

convert_string_number() {
	string="$1"

	if [[ "$string" ==  '' ]];then 
			echo 0; 
	else 
		echo "$string"; 
	fi
}


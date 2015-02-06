#!/bin/sh

export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$PWD"
./mongoose \
	-cgi_interpreter  "$PWD/haserl" \
	-cgi_pattern      "$PWD/www/**.lua" \
	-document_root    "$PWD/www" \
	-index_files      index.html,index.lua \
	-listening_port   8181

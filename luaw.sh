#!/bin/sh

DIR=$(dirname $0)
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$DIR"
$DIR/mongoose \
	-cgi_interpreter  "$DIR/haserl" \
	-cgi_pattern      "$DIR/www/**.lua" \
	-document_root    "$DIR/www" \
	-index_files      index.html,index.lua \
	-listening_port   8080

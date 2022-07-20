#!/bin/bash
python3 six-local.py

cat myfile.bin | curl --trace - -X POST \
	--data-binary  @- \
	'http://127.0.0.1:8000/check_secret.html' \
	-H 'Connection: keep-alive' \
	-H 'Content-Length: 0' \
	--http0.9 \
	-H 'Authorization: Basic YWRtaW46cGFzc3dvcmQ='
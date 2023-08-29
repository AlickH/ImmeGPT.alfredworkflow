#!/usr/bin/env python3
# -*- coding: UTF-8 -*- 
import json, sys, os, subprocess, shutil

def read_json(file_json):
	with open(file_json, "r") as file:
		content = file.read()
		data = json.loads(content)
		return data
	
def write_json(data, file_json):
	formatted_json = json.dumps(data, indent=4, ensure_ascii=False)
	with open(file_json, "w") as file:
		file.write(formatted_json)
		
def read_data(file_data):
	with open(file_data, "r") as file:
		data = file.read()
		return data
	
def write_data(data, file_data):
	with open(file_data, "w") as file:
		file.write(data)
		
def create_folder(folder_name):
	current_directory = os.getcwd()
	folder_path = os.path.join(current_directory, folder_name)
	if not os.path.exists(folder_path):
		os.makedirs(folder_path)
	else:
		shutil.rmtree(folder_path)
		os.makedirs(folder_path)
		
def call_trigger(external_trigger):
	applescript_code = """
						tell application id "com.runningwithcrayons.Alfred" to run trigger %s in workflow "com.mayuzumi.immegpt" with argument ""
						""" % external_trigger
	subprocess.run(['osascript', '-e', applescript_code])
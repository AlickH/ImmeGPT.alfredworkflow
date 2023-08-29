#!/usr/bin/env python3
# -*- coding: UTF-8 -*- 

import json, sys
import gpt_snippets as s

s.create_folder("tmp")

try:
	data = s.read_json("prompts.json")
	prompt_data = s.read_json("selected_chat.json")
	file_name = prompt_data["name"]
	prompt = prompt_data["content"]
	s.write_data(prompt, "tmp/prompt.md")
	output_items = [{"uid":"current_chat","title":"Current chat:" + file_name,"subtitle":"Select to continue.","arg":"","quicklookurl":"tmp/prompt.md"}]
except FileNotFoundError:
	data = []
	
if len(data) != 0:
	for item in data:
		title = item["name"]
		subtitle = item["content"]
		file_index = int(data.index(item))
		file_md = "tmp/" + str(title) + ".md"
		s.write_data(subtitle, file_md)
		output_item = [{"uid":"chats","title":title,"subtitle":"Enter to Chat, with ⌘ to delete, with ⌥ to view history, with ⌃ to edit, ⇧ to preview prompt.","arg":file_index,"quicklookurl":file_md}]
		output_items += output_item
	output = json.dumps({"items":output_items})
	print(output)
else:
	s.call_trigger("prompt")
	sys.exit(0)
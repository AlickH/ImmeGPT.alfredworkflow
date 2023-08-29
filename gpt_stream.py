import json, sys
import helper as h
import gpt_snippets as s

user_ask = str(sys.argv[1])
api = "https://" + sys.argv[2] + "/v1/chat/completions"
key = "Bearer " + sys.argv[3]
model = sys.argv[4]
history_len = int(sys.argv[5])
temp = float(sys.argv[6])
presence = float(sys.argv[7])
frequency = float(sys.argv[8])
stream_type = str(sys.argv[9])

data = s.read_json("selected_chat.json")
file_name = "prompt_history/" + data["name"] + ".json"
token_limit = h.model_type(model)

try:
    history = s.read_json(file_name)
except:
    history = []

history_token_len = h.token_len(model, history)
while history_token_len > token_limit:
    del history[1:3]
    history_token_len = h.token_len(model, history)

user_ask_token_len = h.token_len(model, user_ask)
if user_ask_token_len > token_limit:
    print("字数太多啦，请减少你输入的字数哦。\nToo many words.")
    exit(0)
elif history_len == 0:
    history = [history[0]]
    history.append({"role": "user", "content": user_ask})
elif len(history) > history_len * 2 + 1:
    prompt = history[0]
    history_to_use = history[-(history_len * 2 + 1):]
    history = [prompt] + history_to_use
    history.append({"role": "user", "content": user_ask})
else:
    history.append({"role": "user", "content": user_ask})

new_history_token_len = h.token_len(model, history)
while new_history_token_len > token_limit:
    del history[1:3]
    new_history_token_len = token_len(model, history)
if history == []:
    history.append({"role": "user", "content": user_ask})
else:
    pass
args = [{"role":"user","content":str(history)}]

try:
    response = h.helper(model, key, args, api, temp, presence, frequency)
    if response.status_code == 200:
        output = h.stream_content(response, stream_type)
        pre_history = s.read_json(file_name)
        pre_history.append({"role": "user", "content": user_ask})
        pre_history.append({"role": "assistant", "content": output})
        s.write_json(pre_history, file_name)
        s.write_data(output, "tmp/result.md")
    else:
        print("连接出错了，请检查你的 API 和 API Key。\nConnecting error, please check your API or API Key.")
except:
    print("出错了，请重试。\nSomething wrong, please try again.")
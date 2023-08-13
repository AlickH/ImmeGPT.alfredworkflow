import requests, json, sys, keyboard, time, tiktoken

#请求回答
def xyhelper(model, key, user_prompt, api_url):
    
    headers = {
        'Authorization': key
    }
    
    data = {
        "stream": True,
        "messages": user_prompt,
        "frequency_penalty": 0,
        "model": model,
        "temperature": 0.5,
        "presence_penalty": 0.5,
        "frequency_penalty": 1,
        "top_p": 1
    }
    data = json.dumps(data)
    response = requests.post(api_url, headers=headers, data=data, stream=True)
    return response

#计算token
def token_len(model, history):
    encoding = tiktoken. encoding_for_model(model)
    codelist = encoding.encode(str(history))
    token_size = len(codelist)
    return token_size

#添加到历史记录
def add_to_context(message):
    previous_history.append(message)
    if len(previous_history) > 20:
        for _ in range(2):
            if previous_history:
                previous_history.pop(0)

#历史查重
def get_rank(item, lst):
    try:
        index = lst.index(item)
        rank = index
        return rank
    except ValueError:
        return None
    
#预设
api = "api.xyhelper.cn"
api_url = "https://" + api + "/v1/chat/completions"
key = "Bearer sk-api-xyhelper-cn-free-token-for-everyone-xyhelper"
model = "gpt-4-32k-0613"
history_len = 10 #历史消息数
token_limit = 6144
user_ask = sys.argv[1]
previous_history = []

try:
    with open("history.json", "r") as file:
        previous_history = json.load(file)
except FileNotFoundError:
    pass

previous_history_token_len = token_len(model, previous_history)
while previous_history_token_len > token_limit:
    del previous_history[0:2]
    previous_history_token_len = token_len(model, previous_history)

#读取历史记录
user_ask_token_len = token_len(model, user_ask)
if user_ask_token_len > token_limit:
    print("字数太多啦，请减少你输入的字数哦。")
    exit(0)
else:
#   item_to_find = {"role": "user", "content": user_ask}
#   rank = get_rank(item_to_find, history)
#   if rank != None:
#       del history[rank : rank+2]
#       history.append(item_to_find)
#       print("原始历史1:"+str(history))
#   else:
#       history.append(item_to_find)
#       print("原始历史2:"+str(history))
    history = previous_history if isinstance(previous_history, list) else []
    if history and history[-1]['role'] == 'user' and history[-1]['content'] == user_ask:
        history.pop()
    history.append({"role": "user", "content": user_ask})
        
    
history_token_len = token_len(model, history)
while history_token_len > token_limit:
    del history[0:2]
    history_token_len = token_len(model, history)
if history == []:
    history.append({"role": "user", "content": user_ask})
else:
    pass
args = [{"role":"user","content":history}]
#开始正事
try:
    response = xyhelper(model, key, args, api_url)
    output = ""
    if response.status_code == 200:
        time.sleep(1)
        for line in response.iter_lines():
            line = line.decode('utf-8').lstrip("data:")
            try:
                if line:
                    content = json.loads(line)["choices"][0]["delta"]["content"]
                    time.sleep(0.01)
                    if "\n" in content:
                        keyboard.write(content.rstrip('\n') + '\n')
                    else:
                        keyboard.write(content)
                    output += content
            except:
                pass
    else:
        print("字数太多啦，请减少你输入的字数哦。")
except:
    print("网络出错了，请重试。")

#add_to_context({"role": "user", "content": user_ask})
add_to_context({"role": "assistant", "content": output})

with open("history.json", "w") as file:
    json.dump(previous_history, file, ensure_ascii=False)
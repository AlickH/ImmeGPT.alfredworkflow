import requests, json, sys, time, tiktoken, os, keyboard

def helper(model, key, user_prompt, api_url, temp, presence, frequency):
    
    headers = {
        'Content-Type': 'application/json',
        'Authorization': key
    }
    
    data = {
        "stream": True,
        "messages": user_prompt,
        "model": model,
        "temperature": temp,
        "presence_penalty": presence,
        "frequency_penalty": frequency
    }
    data = json.dumps(data)
    response = requests.post(api_url, headers=headers, data=data, stream=True)
    return response

def token_len(model, history):
    if model == "net-gpt-4":
        encoding = tiktoken. encoding_for_model("gpt-4")
    elif model == "net-gpt-3.5-turbo-16k":
        encoding = tiktoken. encoding_for_model("gpt-3.5-turbo-16k")
    else:
        encoding = tiktoken. encoding_for_model(model)
    codelist = encoding.encode(str(history))
    token_size = len(codelist)
    return token_size

def model_type(model):
    model_3 = ["gpt-3.5-turbo", "gpt-3.5-turbo-0613", "gpt-3.5-turbo-0301"]
    model_3_16k = ["gpt-3.5-turbo-16k", "gpt-3.5-turbo-16k-0613", "gpt-3.5-turbo-0301", "net-gpt-3.5-turbo-16k"]
    model_4 = ["gpt-4", "gpt-4-0613", "net-gpt-4"]
    model_4_32k = ["gpt-4-32k", "gpt-4-32k-0613"]
    if model in model_3:
        token_limit = 4096
    elif model in model_3_16k:
        token_limit = 16384
    elif model in model_4:
        token_limit = 8192
    elif model in model_4_32k:
        token_limit = 32768
    else:
        token_limit = 100000
    return token_limit

def stream_content(response, stream_type):
    output = ""
    for line in response.iter_lines():
        line = line.decode('utf-8').lstrip("data:")
        try:
            if line:
                content = json.loads(line)["choices"][0]["delta"]["content"]
                time.sleep(0.01)
                if stream_type == "print":
                    if "\n" in content:
                        print(content.strip() + "\n")
                    else:
                        print(content, end = "", flush = True)
                elif stream_type == "write":
                    keyboard.write(content)
                output += content
        except:
            pass
    return output
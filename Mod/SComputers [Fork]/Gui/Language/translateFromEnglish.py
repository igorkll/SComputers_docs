fromLang = "English"
langs = ["Russian", "Dutch", "French", "German", "Italian", "Japanese", "Spanish"]
# langs = ["English"]

# --------------------------------------

import json
import shutil
import googletrans
import os
from googletrans import Translator

translator = Translator()

# --------------------------------------

def getLang(fullName):
    for k, v in googletrans.LANGUAGES.items():
        if v.lower() == fullName.lower():
            return k

    print(f"Unsupported lang {fullName}")

with open(fromLang + "/inventoryDescriptions.json", "r", encoding = 'utf-8') as file:
    russian = json.load(file)


for lang in langs:
    data = {}

    for k, v in russian.items():
        print(v)

        if "title" in v:
            atterms = 10
            while True:
                try:
                    title = translator.translate(v["title"], src=getLang(fromLang), dest=getLang(lang)).text
                    break
                except:
                    print("loop")

                    atterms = atterms - 1
                    if atterms == 0:
                        break
                    pass
        else:
            title = None
        
        if "description" in v:
            atterms = 10
            while True:
                try:
                    description = translator.translate(v["description"], src=getLang(fromLang), dest=getLang(lang)).text
                    break
                except:
                    print("loop")

                    atterms = atterms - 1
                    if atterms == 0:
                        break
                    pass
        else:
            description = None

        data[k] = {
            "title": title,
            "description": description
        }

        if "keywords" in v:
            data[k]["keywords"] = v["keywords"]
    
    print(data)
    os.mkdir(lang)
    with open(lang + "/inventoryDescriptions.json", 'w', encoding = 'utf-8') as file:
            json.dump(data, file, indent=4)

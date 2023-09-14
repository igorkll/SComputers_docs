import os
import shutil
import time

# Удаляем файлы из папки importer/files
shutil.rmtree("../USER/importer/files")

# Копируем файлы из папки pics в папку importer/files
shutil.copytree("pics", "../USER/importer/files")

# Запускаем makeJson.py
path = os.getcwd()
os.chdir("../USER/importer")
os.startfile("makeJson.py")
os.chdir(path)
time.sleep(1)

# Копируем файл disk.json из importer в gamedisks и переименовываем в pics.json
shutil.copyfile("../USER/importer/disk.json", "../gamedisks/pics.json")

# Удаляем файл disk.json и папку importer/files
os.remove("../USER/importer/disk.json")
shutil.rmtree("../USER/importer/files")
os.mkdir("../USER/importer/files")
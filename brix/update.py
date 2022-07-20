from os import listdir,system
from os.path import isfile, join
from glob import glob
ip="192.168.1.222"
system("ping 192.168.1.222")
path="C:\Develop\Storyboard\Projects\Brix\export\scripts"
files = [files for files in listdir(path) if isfile(join(path, files))]
for file in files:
    system("scp %s/%s root@%s:/opt/middleby/brix/scripts"%(path,file,ip))
for file in glob("C:\Develop\Storyboard\Projects\Brix\export\*.gapp"):
    system("scp %s root@%s:/opt/middleby/brix/"%(file,ip))
system("ssh root@192.168.1.222")

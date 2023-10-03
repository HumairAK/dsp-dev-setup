from builtins import print, open, repr

with open("artifact_script.sh", 'r') as f:
    lines = f.read()

print(repr(lines))
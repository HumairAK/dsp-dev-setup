from builtins import print, open, repr

with open("templates/artifact_script-template.sh", 'r') as f:
    lines = f.read()

print(repr(lines))
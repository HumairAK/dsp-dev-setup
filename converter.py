from builtins import print, open, repr
import argparse

parser = argparse.ArgumentParser(description="")
parser.add_argument("artifact", help="")
args = parser.parse_args()
af = args.artifact

with open(af, 'r') as f:
    lines = f.read()

print(repr(lines))
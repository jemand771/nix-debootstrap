import json
from pathlib import Path
import sys


src = Path(sys.argv[1])
out = Path(sys.argv[2])

lines_condensed: list[str] = []
for line in src.read_text().splitlines():
    if not line:
        continue
    if line.startswith(" "):
        lines_condensed[-1] += line
    else:
        lines_condensed.append(line)

result = []
current_package = {}
for line in lines_condensed:
    key, val = line.split(": ", 1)
    if key == "Package":
        if current_package:
            result.append(current_package)
        current_package = {}
    current_package[key] = val
if current_package:
    result.append(current_package)

out.write_text(json.dumps(result, indent=2))

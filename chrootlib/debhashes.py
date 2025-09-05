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

current_package = ""
for line in lines_condensed:
    key, val = line.split(": ", 1)
    if key == "Package":
        current_package = val
    if key not in ("Filename", "SHA256", "Depends", "Suggests", "Version", "Architecture"):
        continue
    file = out / current_package / key
    file.parent.mkdir(parents=True, exist_ok=True)
    file.write_text(val)

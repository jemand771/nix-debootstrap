from pathlib import Path
import sys

priority = sys.argv[1]
src = Path(sys.argv[2])
out = Path(sys.argv[3])

out.write_text("\n".join([
    pkg.name
    for pkg in src.glob("*")
    if (pkg / "Priority").read_text().strip() == priority
]))

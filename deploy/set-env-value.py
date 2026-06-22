from pathlib import Path
import sys


if len(sys.argv) != 3:
    raise SystemExit("usage: set-env-value.py ENV_FILE KEY")

path = Path(sys.argv[1])
key = sys.argv[2]
value = sys.stdin.read().strip()
if not value:
    raise SystemExit("value is empty")

lines = path.read_text(encoding="utf-8").splitlines()
replacement = f"{key}={value}"
updated = False

for index, line in enumerate(lines):
    if line.startswith(f"{key}="):
        lines[index] = replacement
        updated = True
        break

if not updated:
    lines.append(replacement)

path.write_text("\n".join(lines) + "\n", encoding="utf-8")

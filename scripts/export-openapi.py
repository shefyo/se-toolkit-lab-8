"""Export the OpenAPI schema from the FastAPI app to a JSON file."""

import json
import os
import sys
from pathlib import Path

# Enable all conditional routers so the full schema is exported
os.environ.setdefault("LMS_API_KEY", "dummy")
os.environ.setdefault("BACKEND_ENABLE_INTERACTIONS", "true")
os.environ.setdefault("BACKEND_ENABLE_LEARNERS", "true")

from app.main import app

REPO_ROOT = Path(__file__).resolve().parent.parent
OUTPUT = REPO_ROOT / "backend" / "openapi.json"


def main() -> None:
    schema = app.openapi()
    new_content = json.dumps(schema, indent=2) + "\n"

    if "--check" in sys.argv:
        if not OUTPUT.exists():
            print(f"ERROR: {OUTPUT} does not exist.")
            print("Run `uv run poe export-openapi` to generate it.")
            sys.exit(1)
        old_content = OUTPUT.read_text()
        if old_content != new_content:
            print(f"ERROR: {OUTPUT} is out of date.")
            print("Run `uv run poe export-openapi` and commit the result.")
            sys.exit(1)
        print("openapi.json is up to date.")
        return

    OUTPUT.write_text(new_content)
    print(f"Wrote {OUTPUT}")


if __name__ == "__main__":
    main()

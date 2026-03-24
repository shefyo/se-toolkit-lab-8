"""Allow running as `python -m nanobot_lms_mcp [base_url]`."""

import asyncio
import sys

from nanobot_lms_mcp import main

if __name__ == "__main__":
    base_url = sys.argv[1] if len(sys.argv) > 1 else None
    asyncio.run(main(base_url))

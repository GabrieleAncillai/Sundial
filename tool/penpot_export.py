#!/usr/bin/env python3
"""One-off Penpot MCP asset exporter.

Reads the Penpot MCP URL from the local Zed settings so the token never has
to be copied into the repository. Exports the two approved artboards as PNG
files under branding/exports/.

Delete this file after the assets are generated if the remote MCP setup is
not meant to be a permanent developer workflow.
"""

import base64
import json
import os
import re
import sys
from pathlib import Path

import requests

SETTINGS = Path.home() / ".var/app/dev.zed.Zed/config/zed/settings.json"
OUT = Path(__file__).resolve().parent.parent / "branding/exports"
SHAPES = {
    "penpot-classic": "69eaca29-c0c6-8019-8008-fee163fabaa1",
    "penpot-aero": "69eaca29-c0c6-8019-8008-fee16415cf6b",
    "export-classic-background": "69eaca29-c0c6-8019-8008-ff3585d79c0b",
    "export-classic-foreground": "69eaca29-c0c6-8019-8008-ff35883aaf0b",
    "export-aero-background": "69eaca29-c0c6-8019-8008-ff3589a5c0a2",
    "export-aero-foreground": "69eaca29-c0c6-8019-8008-ff358b1cf5d0",
    "export-monochrome": "69eaca29-c0c6-8019-8008-ff358fb8b27b",
}


def penpot_url() -> str:
    text = SETTINGS.read_text()
    match = re.search(r'"Penpot"\s*:\s*\{.*?"url"\s*:\s*"([^"]+)"', text, re.S)
    if not match:
        raise RuntimeError("Penpot MCP URL not found in Zed settings")
    return match.group(1)


def parse(resp: requests.Response) -> dict:
    ctype = resp.headers.get("content-type", "")
    if "text/event-stream" in ctype:
        for line in resp.text.splitlines():
            if not line.startswith("data:"):
                continue
            data = line[5:].strip()
            if not data:
                continue
            obj = json.loads(data)
            if "result" in obj or "error" in obj:
                return obj
        raise RuntimeError("No JSON-RPC result in SSE response")
    return resp.json()


def save_image(item: dict, path: Path) -> bool:
    if item.get("type") == "image" and item.get("data"):
        path.write_bytes(base64.b64decode(item["data"]))
        return True
    return False


def main() -> int:
    url = penpot_url()
    session = requests.Session()
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream",
    }

    init = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2025-06-18",
            "capabilities": {},
            "clientInfo": {"name": "sundial-assets", "version": "1.0"},
        },
    }
    resp = session.post(url, json=init, headers=headers, timeout=60)
    if resp.status_code >= 400:
        print("initialize failed:", resp.status_code)
        sys.exit(1)
    session_id = resp.headers.get("Mcp-Session-Id") or resp.headers.get("mcp-session-id")
    if session_id:
        headers["Mcp-Session-Id"] = session_id
    parsed = parse(resp)
    print("initialized:", parsed.get("result", {}).get("serverInfo", {}).get("name", "unknown"))

    session.post(
        url,
        json={"jsonrpc": "2.0", "method": "notifications/initialized"},
        headers=headers,
        timeout=30,
    )

    listed = session.post(
        url,
        json={"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}},
        headers=headers,
        timeout=60,
    )
    tools = parse(listed).get("result", {}).get("tools", [])
    print("tools:", ", ".join(t.get("name", "?") for t in tools))

    OUT.mkdir(parents=True, exist_ok=True)
    for name, shape_id in SHAPES.items():
        call = {
            "jsonrpc": "2.0",
            "id": 3,
            "method": "tools/call",
            "params": {
                "name": "export_shape",
                "arguments": {"shapeId": shape_id, "format": "png"},
            },
        }
        result = parse(session.post(url, json=call, headers=headers, timeout=120))
        if "error" in result:
            print(name, "error:", result["error"].get("message", result["error"]))
            continue
        content = result.get("result", {}).get("content", [])
        saved = False
        for item in content:
            target = OUT / f"{name}.png"
            if save_image(item, target):
                print(name, "saved", target.name, target.stat().st_size, "bytes")
                saved = True
                break
            print(name, "content item:", item.get("type"), str(item)[:200])
        if not saved:
            print(name, "no image content:", str(result.get("result", {}))[:600])

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

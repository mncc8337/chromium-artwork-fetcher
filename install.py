#!/usr/bin/env python3

import os
import sys
import json

XDG_CONFIG_HOME = os.environ.get("XDG_CONFIG_HOME", default = os.path.expanduser("~/.config"))
BROWSERS = [
    os.path.join(XDG_CONFIG_HOME, "chromium"),
    os.path.join(XDG_CONFIG_HOME, "google-chrome"),
    os.path.join(os.path.join(XDG_CONFIG_HOME, "BraveSoftware"), "Brave-Browser"),
    os.path.join(XDG_CONFIG_HOME, "microsoft-edge"),
    os.path.join(XDG_CONFIG_HOME, "vivaldi"),
]


extension_id = "dihmlaokcapfopigfdlbphplplmolghm"
# use provide id
if len(sys.argv) > 1:
    valid_id = all(97 <= ord(c) <= 112 for c in sys.argv[1])
    if valid_id:
        extension_id = sys.argv[1]

cwd = os.path.dirname(os.path.abspath(__file__))

manifest = {
    "name": "org.mncc.artwork_fetcher",
    "description": "fetch artworks",
    "path": os.path.join(cwd, "native/app"),
    "type": "stdio",
    "allowed_origins": [f"chrome-extension://{extension_id}/"]
}

for browser in BROWSERS:
    if not os.path.exists(browser):
        continue
    message_hosts = os.path.join(browser, "NativeMessagingHosts")
    manifest_path = os.path.join(message_hosts, "org.mncc.artwork_fetcher.json")

    os.makedirs(message_hosts, exist_ok = True)
    with open(manifest_path, "w") as f:
        json.dump(manifest, f)
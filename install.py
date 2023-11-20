#!/usr/bin/env python3

fold = "/home/mncc/.config/vivaldi/NativeMessagingHosts/"
file = "org.mncc.artwork_fetcher.json" ## DO NOT CHANGE
with open(fold + file, "wb") as f:
    f.write(open(file, "rb").read())
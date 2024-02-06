#!/usr/bin/env python3

import sys
# do not create `__pycache__`
sys.dont_write_bytecode = True
import struct
import subprocess
import os
import json
import datetime
import time
import threading
import config

current_time = datetime.datetime.now().strftime("%y-%m-%d_%H:%M:%S")
max_logtype_length = 10

def log(logmsg = "nothing", log_type = "INFO"):
    curr_t = datetime.datetime.now()
    dt = curr_t.strftime("%y-%m-%d %H:%M:%S ")
    with open(f"logs/{current_time}.log", "a") as file:
        file.write(dt + log_type + ' '*(max_logtype_length - len(log_type)) + str(logmsg) + '\n')

# get shell command output
def check_output(command):
    return subprocess.check_output(command, shell = True, stderr = subprocess.STDOUT, text = True)

# save image using `curl`
def save_image(url):
    image_donwloading_result = check_output(f"curl {url} > {config.save_art_location}")
    log("image download result:\n" + image_donwloading_result, "STDOUT")

    shell_command_result = check_output(config.shell_command)
    if len(shell_command_result) == 0:
        log("shell command run successfully")
    else:
        log("shell command result:\n" + shell_command_result, "STDOUT")

from gi.repository import Gio, GLib

PLAYER_IFACE = 'org.mpris.MediaPlayer2.Player'
player_name = None
player = None
connection = None

def find_chromium_player():
    names = Gio.DBusProxy.new_for_bus_sync(
            bus_type = Gio.BusType.SESSION,
            flags = Gio.DBusProxyFlags.NONE,
            info = None,
            name = 'org.freedesktop.DBus',
            object_path = '/org/freedesktop/DBus',
            interface_name = 'org.freedesktop.DBus',
            cancellable = None).ListNames()
    for name in names:
        if name.startswith('org.mpris.MediaPlayer2') and "chromium" in name:
            return name

def player_proxy(media_name):
    return Gio.DBusProxy.new_for_bus_sync(
            bus_type = Gio.BusType.SESSION,
            flags = Gio.DBusProxyFlags.NONE,
            info = None,
            name = media_name,
            object_path = '/org/mpris/MediaPlayer2',
            interface_name = PLAYER_IFACE,
            cancellable = None)

# doesnt work (some how)
# def set_artUrl(path):
#     metadata = player.get_cached_property("Metadata").unpack()
#     new_metadata = GLib.Variant("a{sv}",
#         {
#             'mpris:length':  GLib.Variant("i", metadata['mpris:length']),
#             'mpris:trackid': GLib.Variant("s", metadata['mpris:trackid']),
#             'xesam:album': GLib.Variant("s", metadata['xesam:album']),
#             'xesam:artist': GLib.Variant("(s)", tuple(metadata['xesam:artist'])),
#             'xesam:title': GLib.Variant("s", metadata['xesam:title']),
#             'mpris:artUrl': GLib.Variant("s", path)
#         }
#     )
#     changed_props = GLib.Variant("a{sv}", {
#         "Metadata": new_metadata,
#     })
#     res = connection.emit_signal(None, player.get_object_path(), "org.freedesktop.DBus.Properties", "PropertiesChanged",
#         GLib.Variant("(sa{sv}as)", (player.get_interface_name(), { "Metadata": new_metadata }, [])))
#     log(res, "RESULT")

# communicate with the extension
def send_message(message):
    encodedContent = json.dumps(message)
    encodedLength = struct.pack('@I', len(encodedContent))
    encodedMessage = {'length': encodedLength, 'content': encodedContent}

    sys.stdout.buffer.write(encodedMessage['length'])
    sys.stdout.write(encodedMessage['content'])
    sys.stdout.flush()

    log(str(message), "SENT")

def get_message():
    # get the 4 first chars (message length)
    raw_length = str.encode(sys.stdin.read(4))
    if len(raw_length) < 4:
        log("invalid text length, received `" + str(len(raw_length)) + '`', "EXIT")
        sys.exit(0)

    length = struct.unpack("@i", raw_length)[0]
    text = sys.stdin.read(length)
    return json.loads(text)


player_name = find_chromium_player()
if player_name:
    player = player_proxy(player_name)
    connection = player.get_connection()

current_trackid = None
interval = 1
# request for artwork if needed for each interval
def check_player_stat():
    global connection, player, player_name, current_trackid
    while True:
        player_name = find_chromium_player()
        if player_name:
            player = player_proxy(player_name)
            connection = player.get_connection()

            metadata = player.get_cached_property("Metadata").unpack()
            # log(metadata, "METADATA")

            track_changed = current_trackid != metadata["mpris:trackid"]
            if track_changed:
                log("new media (probably) detected")
                send_message({"type": "REQUEST", "content": "ARTWORK"})

            current_trackid = metadata["mpris:trackid"]
                
        time.sleep(interval)
check_player_stat_thread = threading.Thread(target = check_player_stat)
check_player_stat_thread.start()

# check if save art path is valid
if not os.path.exists(os.path.dirname(config.save_art_location)):
    send_message({"type": "ERROR", "content": "ART_DIR_INVALID", "dir": os.path.dirname(config.save_art_location)})
    log("invalid art dir", "EXIT")
    sys.exit(0)

# main thread
while True:
    message = get_message()
    log(str(message), "RECEIVED")
    try:
        match message["message"]:
            case "ping":
                send_message({"type": "MESSAGE", "content": "pong"})
            case "artworkURL":
                if message["url"] != "NO_ARTWORK":
                    log("got artwork `" + message["url"] + '`')
                    save_image(message["url"])
                else:
                    log("no artwork for this media")
            case "loopType":
                log("loop type changed to " + message["loop"])
            case "shuffle":
                log("shuffle changed to " + str(message["shuffle"]))
            case _:
                log(message["message"], "MESSAGE")
    except Exception as e:
        log(e, "ERROR")
        send_message({"type": "ERROR", "content": "RECEIVING_MESSAGE", "error": str(e)})
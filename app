#!/usr/bin/env python3

import struct
import os
import sys
import json
import datetime
import time
import threading

current_time = datetime.datetime.now().strftime("%d-%m-%y_%H:%M:%S ")
def log(logmsg = "nothing", log_type = "INFO"):
    curr_t = datetime.datetime.now()
    dt = curr_t.strftime("%d-%m-%y %H:%M:%S ")
    with open(f"logs/{current_time}.log", "a") as file:
        file.write(dt + log_type + ' ' + str(logmsg) + '\n')

def save_image(url):
    os.system(f"cd /home/mncc/.config/awesome && curl {url} > artwork.png")
# TODO: try to remove this xd
def set_image(path, awesome_dir = True):
    d = f"\\\"{path}\\\""
    if awesome_dir:
        d = "awesome_dir.." + d
    os.system(f'awesome-client "awesome.emit_signal(\\"music::set_cover\\", {d})"')

# communicate with mpris

from gi.repository import Gio, GLib

PLAYER_IFACE = 'org.mpris.MediaPlayer2.Player'
player_name = None
player = None
connection = None

current_trackid = None

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

    log("sent message `" + message + '`')

def get_message():
    # get the 4 first chars (message length)
    raw_length = str.encode(sys.stdin.read(4))
    if len(raw_length) < 4:
        log("invalid text length, received `" + len(raw_length) + '`', "ERROR")
        sys.exit(0)

    length = struct.unpack("@i", raw_length)[0]
    text = sys.stdin.read(length)
    return json.loads(text)


player_name = find_chromium_player()
if player_name:
    player = player_proxy(player_name)
    connection = player.get_connection()

# check thread
def check_player_stat():
    global connection, player, player_name, current_trackid
    # request for artwork if needed for each 1 second
    while True:
        player_name = find_chromium_player()
        if player_name:
            player = player_proxy(player_name)
            connection = player.get_connection()

            metadata = player.get_cached_property("Metadata").unpack()
            # log(metadata, "METADATA")
            if current_trackid != metadata["mpris:trackid"]:
                log("new media (probaly) detected")
                send_message("REQUEST_ARTWORK")
            current_trackid = metadata["mpris:trackid"]
                
        time.sleep(1)
check_player_stat_thread = threading.Thread(target = check_player_stat)
check_player_stat_thread.start()

# main thread
while True:
    message = get_message()
    log("received message `" + str(message) + '`')
    try:
        match message["message"]:
            case "ping":
                send_message("pong")
            case "artworkURL":
                if message["url"] != "NO_ARTWORK":
                    log("got artwork `" + message["url"] + '`')
                    save_image(message["url"])
                    # set_artUrl("/home/mncc/.config/awesome/artwork.png")
                    set_image("artwork.png")
                else:
                    log("no artwork for this media")
                    # set_image("fallback.png")
            case "loopType":
                log("loop type changed to " + message["loop"])
            case "shuffle":
                log("shuffle changed to " + str(message["shuffle"]))
            case _:
                log(message["message"], "MESSAGE")
    except Exception as e:
        log(e, "ERROR")
        send_message("ERROR `" + str(e) + "` when received URL")
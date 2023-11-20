## WIP, testing file

import dbus
import dbus.service
import dbus.mainloop.glib
import json, sys
from gi.repository import GLib

# https://stackoverflow.com/a/48546409
def python2dbus(data):
    if isinstance(data, str):
        data = dbus.String(data)
    elif isinstance(data, bool):
        # python bools are also ints, order is important !
        data = dbus.Boolean(data)
    elif isinstance(data, int):
        data = dbus.Int64(data)
    elif isinstance(data, float):
        data = dbus.Double(data)
    elif isinstance(data, list):
        data = dbus.Array([python2dbus(value) for value in data], signature='v')
    elif isinstance(data, dict):
        data = dbus.Dictionary(data, signature='sv')
        for key in data.keys():
            data[key] = python2dbus(data[key])
    return data
def dbus2python(data):
    if isinstance(data, dbus.String):
        data = str(data)
    elif isinstance(data, dbus.Boolean):
        data = bool(data)
    elif isinstance(data, dbus.Int64):
        data = int(data)
    elif isinstance(data, dbus.Double):
        data = float(data)
    elif isinstance(data, dbus.Array):
        data = [dbus2python(value) for value in data]
    elif isinstance(data, dbus.Dictionary):
        new_data = dict()
        for key in data.keys():
            new_data[dbus2python(key)] = dbus2python(data[key])
        data = new_data
    return data

dbus.mainloop.glib.DBusGMainLoop(set_as_default = True)
bus = dbus.SessionBus()
BUS_NAME = None

proxy = None
player = None
# playlists = None
# tracklist = None
properties = None

def properties_changed(player, changed_props, invalidated_props):
    print(json.dumps(changed_props, indent = 4))
    print(json.dumps(invalidated_props, indent = 4))

    props = properties.Get('org.mpris.MediaPlayer2.Player', 'Metadata')
    props = dbus2python(props)
    if not props.get("mpris:artUrl"):
        props["mpris:artUrl"] = "/home/mncc/.config/awesome/artwork.png"
        # props = python2dbus(props)
        properties.Set('org.mpris.MediaPlayer2.Player', "Metadata", str(props))

for name in bus.list_names():
    if "org.mpris.MediaPlayer2" in name:
        BUS_NAME = name
        break
if not BUS_NAME:
    print("cannot find any player")
    sys.exit(0)

print("found player", BUS_NAME)
proxy = bus.get_object(BUS_NAME,'/org/mpris/MediaPlayer2')
player = dbus.Interface(proxy, 'org.mpris.MediaPlayer2.Player')
# playlists = dbus.Interface(proxy, 'org.mpris.MediaPlayer2.Playlists')
# tracklist = dbus.Interface(proxy, 'org.mpris.MediaPlayer2.TrackList')

properties = dbus.Interface(proxy, 'org.freedesktop.DBus.Properties')
properties.connect_to_signal("PropertiesChanged", properties_changed)

properties.Set('org.mpris.MediaPlayer2', "Shuffle", True)

mainloop = GLib.MainLoop()
mainloop.run()
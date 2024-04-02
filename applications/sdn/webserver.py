#!/usr/bin/python3

from flask import Flask, request, jsonify
import threading
from pprint import pprint, pformat
from time import sleep
from datetime import datetime
import json
import struct

controller = None
app = Flask(__name__)


def htmlify(content, req, replace=True):
    # Feel free to update this function in case you want have a different HTML style
    s = "<html><body>"
    s += "<a href='/'> Go Back</a> \n<br>\n"
    if (replace):
        s += content.replace("\n", "\n<br>\n")
    else:
        s += content
    s += "</body></html>"
    return s


# When visiting /macs_map we want to see a map of the MAC addresses and to which switch port they have been seen incoming
# Hint: the events are sequential
#       So you can keep a list of the "first seen at" at the controller
#       And update that from each device when new packets come (and the source MAC is unknown)

@app.route('/macs_map')
def macs_map():
    res = ""
    res += f"Global MAC table\n"
    res += f"Fill it with a proper content\n"
    res += f"For instance:\n"
    res += f"11:22:33:44:55:66 : switch 1 - port 1 @ 2023-03-10 23:48:00"
    res += f"11:22:33:44:44:33 : switch 2 - port 4 @ 2023-03-10 23:42:00"
    res += f"11:22:33:44:11:22 : switch 3 - port 1 @ 2023-03-10 23:48:01"
    res += f"11:11:22:44:44:44 : switch 3 - port 2 @ 2023-03-11 23:43:01"
    return htmlify(res, request, True)


# When visiting /macs we should have a list of MAC addresses and to which port they have been seen
# They should be dividided by device
# The difference with the above is that here we want to see **all** mac addresses incoming to any port
# You should retrieve these information from the Python code of the L2 switches
@app.route('/macs')
def macs():

    res = ""
    res += f"Fill it with a proper content\n"
    res += f"For instance:\n"
    res += f"MAC table for switch 1:\n"
    res += f"* port 1 - 11:22:33:44:55:66\n"
    res += f"MAC table for switch 2:\n"
    res += f"* port 4 - 11:22:33:44:44:33\n"
    res += f"* port 1 - 11:22:33:44:55:66\n"
    res += f"MAC table for switch 2:\n"
    res += f"* port 4 - 11:22:33:44:44:33\n"
    res += f"* port 2 - 11:22:33:44:55:66\n"
    res += f"* port 3 - 11:22:33:44:33:33\n"
    return htmlify(res, request, True)


# Here we call the controller's function that flushes rules.
@app.route('/flush')
def flush():
    controller.flush()
    res = "Flushed!"
    return htmlify(res, request, True)


@app.route('/')
def index():
    # Feel free to change the main page with a design you like!
    s = ""
    s += "<body><html>"
    s += "Welcome to IK2220 OpenFlow Controller!<br>\n"
    s += "<a href='macs'> MAC table status</a><br></n>"
    s += "<a href='macs_map'> Global MAC map</a><br></n>"
    s += "<a href='flush'> Flush rules from all switches. Be careful! </a><br></n>"
    return s


def webserver(contr):
    global controller

    if contr is not None:
        controller = contr
    else:
        print("Controller is None!")

    # This starts a web server on a background thread on port 8080
    # All decorated methos with @app.route will be added as routes of the application
    threading.Thread(target=lambda:
                     app.run(host="0.0.0.0", port=8080, debug=False, use_reloader=False)).start()

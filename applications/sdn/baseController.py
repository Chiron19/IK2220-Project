from pox.core import core
import pox.openflow.libopenflow_01 as of
from pox.lib.addresses import IPAddr
from pox.lib.util import dpid_to_str
import pox.lib.packet as pkt
import networkFirewalls
import webserver
import subprocess
import shlex
import datetime
import click_wrapper

log = core.getLogger()


class controller (object):
    # Here you should save a reference to each element:
    devices = dict()

    # Here you should save a reference to the place you saw the first time a specific source mac
    firstSeenAt = dict()

    def __init__(self):

        webserver.webserver(self)
        core.openflow.addListeners(self)

    def _handle_ConnectionUp(self, event):
        
        """
        This function is called everytime a new device starts in the network.
        You need to determine what is the new device and run the correct application based on that.
        
        Note that for normal switches you should use l2_learning module that already is available in pox as an external module.
        """

        # In phase 2, you will need to run your network functions on the controller. Here is just an example how you can do it (Please ignore this for phase 1):
        # click = click_wrapper.start_click("../nfv/forwarder.click", "", "/tmp/forwarder.stdout", "/tmp/forwarder.stderr")

        # For the webserver part, you might need a record of switches that are already connected to the controller. 
        # Please keep them in "devices".
        # For instance: self.devices[len(self.devices)] = fw

        return

    # This should be called by each element in your application when a new source MAC is seen

    def updatefirstSeenAt(self, mac, where):
       
        """
        This function updates your first seen dictionary with the given input.
        It should be called by each element in your application when a new source MAC is seen
        """
       
        # TODO: More logic needed here!
        self.firstSeenAt[mac] = (where, datetime.datetime.now().isoformat())


    def flush(self):

        """
        This will be called by the webserver and act as a 'soft restart'. It should:
        1) ask the switches to flush the rules (look for 'how to delete openflow rules'
        2) clear the mac learning table in each l2_learning switch (Python side) 
        3) clear the firstSeenAt dictionary: it's like starting from an empty state
        """
        return


def launch(configuration=""):
    core.registerNew(controller)

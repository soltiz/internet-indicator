#!/usr/bin/env python3

import sys
import urllib.request
import hashlib
import lxml.html
from gi.repository import Gtk
from gi.repository import AppIndicator3 as appindicator
from gi.repository import GLib

class MyIndicator:
  def __init__(self):
    self.hash = ''
    self.ind = appindicator.Indicator.new(
                "NetworkStatus",
                "/home/cedric/dev/indicator/if_network-OK_118952.png",
                appindicator.IndicatorCategory.APPLICATION_STATUS)
    self.ind.set_status (appindicator.IndicatorStatus.ATTENTION)
#    self.ind.set_attention_icon("new-messages-red")
    self.ind.set_attention_icon("/home/cedric/dev/indicator/if_network-offline_118949.png")
    self.menu = Gtk.Menu()

    item = Gtk.MenuItem()
    item.set_label("Check again")
    item.connect("activate", self.check)
    self.menu.append(item)

    item = Gtk.MenuItem()
    item.set_label("Exit")
    item.connect("activate", self.quit)
    self.menu.append(item)

    self.menu.show_all()
    self.ind.set_menu(self.menu)

  def main(self):
    self.check(None)
    GLib.timeout_add_seconds(20, self.check)
    Gtk.main()


  def check(self, widget=None):
    print("CHECKING...")
    try:
      public_ip = urllib.request.urlopen('http://ipinfo.io/ip').read().decode('UTF-8').replace('\n','')
      self.ind.set_status(appindicator.IndicatorStatus.ACTIVE)
      print("NETWORK OK")
    except Exception as e:
      self.ind.set_status(appindicator.IndicatorStatus.ATTENTION)
      print("NETWORK KO")
      print(str(e))
    return True

  def quit(self, widget):
    Gtk.main_quit()

if __name__ == '__main__':
  indicator = MyIndicator();
  indicator.main();

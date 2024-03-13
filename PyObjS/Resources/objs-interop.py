#!env python3

##  #!/opt/homebrew/opt/python@3.9/bin/python3.9

import objc
from cheroot import wsgi
from wsgidav.wsgidav_app import WsgiDAVApp
from Cocoa import NSBundle

objs = NSBundle.bundleWithPath_("/Library/Frameworks/ObjectiveSmalltalk.framework")
objs.load()

envscheme = objc.lookUpClass("MPWEnvScheme").new()
print(envscheme.at_("HOME"))

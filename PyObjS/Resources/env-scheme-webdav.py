#!env python3


import re
import sys

sys.path.append("/opt/homebrew/lib/python3.11/site-packages/")


from Cocoa import NSBundle
import objc

from cheroot import wsgi
from wsgidav.wsgidav_app import WsgiDAVApp
import logging
import os
import io
from urllib.parse import quote

from wsgidav import util
from wsgidav.dav_error import (
    HTTP_FORBIDDEN,
    HTTP_INTERNAL_ERROR,
    DAVError,
    PRECONDITION_CODE_ProtectedProperty,
)
from wsgidav.dav_provider import DAVCollection, DAVNonCollection, DAVProvider
from wsgidav.util import join_uri

# -*- coding: utf-8 -*-
# (c) 2009-2023 Martin Wendt and contributors; see WsgiDAV https://github.com/mar10/wsgidav
# (c) 2024-2024 Adam Obeng
# Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php


__docformat__ = "reStructuredText en"


#NSBundle.bundleWithPath_("/Library/Frameworks/ObjectiveSmalltalk.framework").load()
#envscheme = objc.lookUpClass("MPWEnvScheme").new()
envscheme = objc.lookUpClass("MPWEnvScheme").new()
print(envscheme.at_("HOME"))

scheme = None
mountpoint = "env"

class RootCollection(DAVCollection):
    """Resolve top-level requests '/'."""

    def __init__(self, environ):
        super().__init__("", environ)

    @property
    def _member_names(self):
        r = tuple([ mountpoint ] )
        return r

    def get_member_names(self):
        r = self._member_names
        print("RootCollection get_member_names: ",r)
        return r

    def get_member(self, name):
        print("RootCollection get_member: ",name)
        if name in self._member_names:
            return DBCollection(
                path=join_uri(self.path, name),
                environ=self.environ,
            )
        return None


class DBCollection(DAVCollection):
    """Top level database, contains tables"""

    # TOOD: support multiple databases per file

    def __init__(
        self, path, environ
    ):
        super().__init__(path, environ)
        self.thePath = path

    def get_display_info(self):
        return {"type": "Category type"}

    def get_member_names(self):
        paths = scheme.pathsAtReference_(self.thePath)
        print("paths from scheme: ",paths)
#        paths = list(filter( lambda x: not x.startswith("."), paths))
#        print("paths after filtering dotfiles: ",paths)
        return paths

    def get_member(self, name):
        if name in self.get_member_names():
#            path=join_uri(self.path, name)
            path=join_uri("", name)
            print("combined path: ",path)
            hasChildren = scheme.hasChildren_(path)
            print("hasChildren: ",hasChildren)
            if hasChildren:
               return DBCollection(path=path, environ=self.environ)
            else:
               return DataArtifact(
                   path=path, environ=self.environ, db_collection=self
               )
        return None



#    def handle_delete(self):
#        raise DAVError(HTTP_FORBIDDEN)
#    def handle_move(self, destPath):
#        raise DAVError(HTTP_FORBIDDEN)
#    def handle_copy(self, destPath, depthInfinity):
#        raise DAVError(HTTP_FORBIDDEN)


class DataArtifact(DAVNonCollection):
    """ Data  """

    def __init__(self, path, environ, db_collection):
        #        assert name in _artifactNames
        super().__init__(path, environ)
        self.thePath = os.path.basename(os.path.normpath(path))
#        self.thePath = path

    def get_creation_date(self):
        print("get_creation_date for: ",self.thePath)
        return None

    def get_display_name(self):
        print("get_display_name: ",self.name)
        return self.name

    def get_display_info(self):
        print("get_display_info for: ",self.thePath)
        raise NotImplementedError

    def get_etag(self):
        return None

    def support_etag(self):
        return False

    def get_last_modified(self):
        return None

    def support_ranges(self):
        return False

    def get_content_length(self):
        print("get size for path: ",self.thePath)
        data =  scheme.at_(self.thePath)
        size = 0
        if data != None:
            size = data.asData().length()
            print("size: ",size)
        return size

    def get_content_type(self):
        print("get_content_type for: ",self.thePath)
        return "text/plain"

    def get_display_info(self):
        print("get_display_info for: ",self.thePath)
        return {"type": "Virtual info file"}

    def prevent_locking(self):
        print("prevent_locking for: ",self.thePath)
        return True

    def get_ref_url(self):
        print("get_ref_url for: ",quote(self.thePath))
        return quote(self.path)

    def get_content(self):
        print("get data for path ",self.thePath)
        baseVal = scheme.at_(self.thePath)
        if baseVal != None:
           dataVal = baseVal.asData()
           print("data retrieved has length ",dataVal.length)
           pyData = io.BytesIO(dataVal)
#        print("python data for path {} is {}",self.thePath,pyData)
           return pyData
        else:
           return io.BytesIO(b"")


class DBResourceProvider(DAVProvider):
    """
    DAV provider that serves a VirtualResource derived structure.
    """

    def __init__(self, allow_abspath=False):
        print("simple DAVProvider init")
        self.allow_abspath=allow_abspath
        super().__init__()

    def get_resource_inst(self, path, environ):
        global scheme
        print("get_resource_inst for path:", path)
        self._count_get_resource_inst += 1
        if path.startswith( mountpoint ):
            path = path[mountpoint.length:]

        root = RootCollection(environ)
        
        return root.resolve("", path)


def runServer(port):
    global scheme,mountpoint
    st =  objc.lookUpClass("STPython")
    scheme = st.param_("store")
    mountpoint = st.param_("mountpoint")
    config = {
        "host": "127.0.0.1",
        "port": port,
        "provider_mapping": {
            "/": DBResourceProvider(
                allow_abspath=True
            ),
        },
        "simple_dc": {"user_mapping": {"*": True}},
        "http_authenticator": {},
    }
    app = WsgiDAVApp(config)

    server_args = {
        "bind_addr": (config["host"], config["port"]),
        "wsgi_app": app,
        "timeout": 0.250,
    }
    server = wsgi.Server(**server_args)
    print("will start at port: ",port)
    didStart = server.start()
    printf("did start")
    print(didStart)

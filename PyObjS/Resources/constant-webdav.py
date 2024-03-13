#!env python3


import re
import sys

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



class RootCollection(DAVCollection):
    """Resolve top-level requests '/'."""

    def __init__(self, environ):
        super().__init__("/", environ)

    @property
    def _member_names(self):
        r = tuple([ "chinook.db"] )
        return r

    def get_member_names(self):
        print("RootCollection get_member_names")
        r = self._member_names
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

    def get_display_info(self):
        return {"type": "Category type"}

    def get_member_names(self):
        return ['hello.txt']

    def get_member(self, name):
        if name in self.get_member_names():
            return DataArtifact(
                path=join_uri(self.path, name), environ=self.environ, db_collection=self
            )
        return None



#    def handle_delete(self):
#        raise DAVError(HTTP_FORBIDDEN)
#    def handle_move(self, destPath):
#        raise DAVError(HTTP_FORBIDDEN)
#    def handle_copy(self, destPath, depthInfinity):
#        raise DAVError(HTTP_FORBIDDEN)


class DataArtifact(DAVNonCollection):
    """A virtual file, with hard-coded data """

    def __init__(self, path, environ, db_collection):
        #        assert name in _artifactNames
        super().__init__(path, environ)

    def get_creation_date(self):
        return None

    def get_display_name(self):
        return self.name

    def get_display_info(self):
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
        return  9

    def get_content_type(self):
        return "text/plain"

    def get_display_info(self):
        return {"type": "Virtual info file"}

    def prevent_locking(self):
        return True

    def get_ref_url(self):
        return quote("path")

    def get_content(self):
        return io.BytesIO(b"Some data")


class DBResourceProvider(DAVProvider):
    """
    DAV provider that serves a VirtualResource derived structure.
    """

    def __init__(self, db_paths=[], allow_abspath=False):
        print("simple DAVProvider init")
        self.allow_abspath=allow_abspath
        super().__init__()

    def get_resource_inst(self, path, environ):
        print("get_resource_inst for path:", path)
        self._count_get_resource_inst += 1
        root = RootCollection(environ)
        return root.resolve("", path)



config = {
    "host": "127.0.0.1",
    "port": 8080,
    "provider_mapping": {
        "/": DBResourceProvider(
            db_paths= ['chinook.db'],
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
server.start()


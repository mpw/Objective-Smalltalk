#!env stsh
host := MPWHost host:'130.61.236.203' user:'ubuntu'.
scheme:webserver := host http.
shell runInteractiveLoop.

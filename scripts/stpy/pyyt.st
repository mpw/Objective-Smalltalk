#!env st
#-<void>download:urlstring
framework:PyObjS load
scheme:py := STPython new
py:module/sys/path/append call:'/opt/homebrew/lib/python3.9/site-packages'.
py:module/yt_dlp/_real_main  call:['--format', 'mp4', urlstring].

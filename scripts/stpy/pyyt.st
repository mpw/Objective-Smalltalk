#!env st
framework:PyObjS load
py := STYtb_dlp new

urlstring := 'https://www.youtube.com/watch?v=XqUgUgiToNs'.

stdout println:urlstring.
append := py import:'sys' | at:'path' | at:'append'.
stdout println:append.
append  call:'/opt/homebrew/lib/python3.9/site-packages'.
yt := py import:'yt_dlp' | at:'_real_main'.
stdout println:yt.
yt  call:[urlstring].

stdout println:'did dowload'.

framework:StshFramework load.  
host := #MPWRemoteHost{ 
   #name: '130.61.236.203',
   #user:'ubuntu' 
}.
  
s := host  store   

scheme:s := s. 

#MPWBrowser{ #store: s } openInWindow:'Oracle' <NSWindow: 0x13b9603e0>


#!/usr/local/bin/stsh
#-<void>plist2objc:<ref>file
plist := file value rawData stringValue propertyList.
plist allKeys do:{ :key | stdout println:('@"' , key , '"  : @"',(plist objectForKey:key),'", '). }.

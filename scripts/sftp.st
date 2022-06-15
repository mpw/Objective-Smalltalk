#!env stsh
#-<void>scpto:host as:user
framework:ObjectiveSSH load.
session := SSHConnection new.
session setHost:host.
session setUser:user.
scheme:sftp := session store.
stdout println:'sftp:/ '.
shell runInteractiveLoop.

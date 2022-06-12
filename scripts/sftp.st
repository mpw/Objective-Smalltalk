#!env stsh
#-<void>scpto:host as:user
framework:ObjectiveSSH load.
writer := SCPWriter new.
writer setHost:host.
writer setUser:user.
scheme:sftp := writer.
stdout println:'sftp:/ '.
shell runInteractiveLoop.

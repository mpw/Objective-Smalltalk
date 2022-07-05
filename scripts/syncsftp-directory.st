#!env stsh
#-sync:<ref>source to:host user:user dir:dir
framework:ObjectiveSSH load.
sourceScheme ← source asScheme.
session := SSHConnection new.
session setHost:host.
session setUser:user.

scheme:sftp := session store.
targetScheme := ref:sftp:{dir} asScheme.

targetScheme |= sourceScheme.

runLoop run.

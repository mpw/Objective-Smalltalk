#!env st
framework:CloudTalk load.

config ← #CTMachineConfig{ os: 'ubunutu24', arch: 'aarch64'  }
 stdout println:config.

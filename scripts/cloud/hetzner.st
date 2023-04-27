#!env st
scheme:https setHeaders: #{ #Authorization: "Bearer {keychain:password/hetzner-api/metaobject}" }.
scheme:hetzner := ref:https://api.hetzner.cloud/v1 asScheme.
shell runInteractiveLoop.

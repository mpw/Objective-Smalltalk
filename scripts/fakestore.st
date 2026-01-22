#!env st
scheme:store ← #MPWJSONConverterStore{} → ref:https://fakestoreapi.com/ asScheme.
stdline ! 'store:/products/1'.
stdline ! 'store:/carts/1'.
stdline ! 'store:/users/1'.
shell runInteractiveLoop.

#!env stsh
source := MPWDictStore store.
scheme:dest := MPWDictStore store.
scheme:source := ( scheme:dest |= source ).
shell runInteractiveLoop.


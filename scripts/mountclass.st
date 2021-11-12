#!env stsh

framework:SchemeFUSE load.

fs := MPWClassScheme store mountAt:'/Volumes/SchemeFS' .

shell runInteractiveLoop.

fs unmount.

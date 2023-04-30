#!env stsh
#-sync:<ref>sourceRef to:<ref>targetRef
source ← sourceRef asScheme.
target ← targetRef asScheme.

target |= source.

runLoop run.

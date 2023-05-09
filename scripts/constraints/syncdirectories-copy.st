#!env stsh
#-<void>sync:<ref>sourceRef to:<ref>targetRef
source ← sourceRef asScheme.
target ← targetRef asScheme.

target copyFrom: source.

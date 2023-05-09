#!env stsh
#-sync:<ref>sourceRef to:<ref>targetRef
source ← sourceRef asScheme.
target ← targetRef asScheme.

(target |= source) update.

runLoop run.

#!/usr/bin/env st
# Verify the reference framework works correctly
# Run from the Resources directory

framework:ReferenceSTClass load.
obj := class:ReferenceSTClass new.

result1 := obj answerFortyTwo.
stdout println:'answerFortyTwo returned: ' , result1 stringValue.
result1 = 42 ifTrue:{
    stdout println:'PASS: answerFortyTwo'.
} ifFalse:{
    stdout println:'FAIL: answerFortyTwo expected 42'.
}.

result2 := obj addFive:10.
stdout println:'addFive:10 returned: ' , result2 stringValue.
result2 = 15 ifTrue:{
    stdout println:'PASS: addFive:'.
} ifFalse:{
    stdout println:'FAIL: addFive: expected 15'.
}.

stdout println:'Reference framework verification complete.'.

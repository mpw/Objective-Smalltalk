#!env raspish
1 to:10000 do: { gpio:17 ← true. gpio:17 ← false. }

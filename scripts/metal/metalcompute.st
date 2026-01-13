#!env st
framework:ObjectiveMetal load 
device ← #OMTLDevice{}.
adder  ←  device adder.
lhs ← #MPWRealArray[ 20, 10, 30 ].
rhs ← #MPWRealArray[ 1, 4, 5 ].

adder prepareDataLhs: lhs rhs: rhs.
adder sendComputeCommand
stdline ! adder result.

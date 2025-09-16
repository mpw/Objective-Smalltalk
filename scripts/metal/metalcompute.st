#!env st
framework:ObjectiveMetal load 
adder  ← #MetalAdder{} 
adder prepareData
adder sendComputeCommand

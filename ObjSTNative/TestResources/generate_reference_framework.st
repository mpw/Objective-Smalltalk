#!/usr/bin/env st
# Generate reference framework for characterization tests
# Run this script once, verify the framework works, then commit it

framework:ObjSTNative load.

# Compile a simple ST class
compiler := STNativeCompiler compiler.
source := 'class ReferenceSTClass : NSObject { -<int>answerFortyTwo { 42. } -<int>addFive:x { x + 5. } }'.
theClass := compiler compile:source.
objectData := compiler compileClassToMachoO:theClass.

# Write object file
objectPath := '/tmp/ReferenceSTClass.o'.
objectData writeToFile:objectPath atomically:true.
stdout println:'Object file written to: ' , objectPath.

# Create framework directory structure
frameworkDir := '/tmp/ReferenceSTClass.framework'.
fm := NSFileManager defaultManager.
fm removeItemAtPath:frameworkDir error:nil.
fm createDirectoryAtPath:frameworkDir withIntermediateDirectories:true attributes:nil error:nil.

# Link with external linker using shell
ldCommand := 'ld -dylib -arch arm64 -platform_version macos 11.0.0 14.0 -syslibroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -o /tmp/ReferenceSTClass.framework/ReferenceSTClass /tmp/ReferenceSTClass.o -lSystem -F/Library/Frameworks -framework Foundation -framework ObjectiveSmalltalk -framework MPWFoundation -install_name @rpath/ReferenceSTClass.framework/ReferenceSTClass'.

stdout println:'Running linker...'.
scheme:shell run:ldCommand.

# Sign the framework
stdout println:'Signing...'.
scheme:shell run:'codesign -f -s - /tmp/ReferenceSTClass.framework/ReferenceSTClass'.

stdout println:'Reference framework generated at: /tmp/ReferenceSTClass.framework'.
stdout println:'Verify it works with: st verify_reference_framework.st'.
stdout println:'Then copy to ObjSTNative/Resources/'.

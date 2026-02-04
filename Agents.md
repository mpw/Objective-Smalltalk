# ObjectiveSmalltalk Notes for AI Agents

## Building and Testing

### Building
Use xcodebuild with Release configuration and the shared build directory:
```bash
xcodebuild -project ObjectiveSmalltalk.xcodeproj -target <TargetName> \
    CONFIGURATION_BUILD_DIR=/Users/marcel/programming/Build/Release/ build
```

Example for ObjSTNative:
```bash
xcodebuild -project ObjectiveSmalltalk.xcodeproj -target ObjSTNative \
    CONFIGURATION_BUILD_DIR=/Users/marcel/programming/Build/Release/ build
```

### Running Tests
Use `testlogger` to run tests for a framework:
```bash
testlogger <FrameworkName>
```

Example:
```bash
testlogger ObjSTNative
```

Options:
- `-v` : verbose, show successful results
- `-vv` : very verbose, log test names as they execute
- `-l` : list tests as plist

## General Guidelines

### Prefer Tests Over Throwaway Programs
When exploring or figuring things out, prefer adding a test to the test suite rather than writing an external program that will be discarded. Tests:
- Document the behavior or assumption being verified
- Remain useful for regression testing
- Serve as examples for future reference
- Are already integrated into the project's test infrastructure

## Syntax Differences from Traditional Smalltalk

### Blocks
- Use `{ }` for blocks, NOT `[ ]`
- Example: `collection collect:{ :x | x * 2 }`
- Example: `condition ifTrue:{ 'yes' } ifFalse:{ 'no' }`

### Local Variables
- No `| var |` declarations needed
- Variables are introduced simply by assignment
- Example: `result := 42. result * 2.`

### Message Precedence and Pipe Syntax
- Use `|` (pipe) to control message send precedence
- `data at:'code' | stringValue` means `(data at:'code') stringValue`
- Without pipe: `data at:'code' stringValue` parses as `data at:('code' stringValue)`

### References
- References are created with `ref:` scheme prefix
- Example: `ref:/` creates a reference to root path
- Used for redirects and resource access

### Instance Variables (in schemes/classes)
- Access via `this:varName`
- Assignment: `this:varName := value.`

## Sails Web Framework

### .sited Bundle Structure
```
myapp.sited/
├── Info.json           # {"site":"MySiteScheme"}
├── Sources/
│   └── MySiteScheme.st
└── Resources/
    └── templates.html
```

### Scheme Definition
```
scheme MySiteScheme {
    var bundle.
    var someState.

    -initWithBundle:aBundle {
        this:bundle := aBundle.
        self.
    }

    / {
        get {
            "response" asData.
        }
    }
}
```

### HTTP Methods
- GET requests: handled via route blocks with `get { }`
- POST requests: handled via `-at:ref post:data` method (NOT route blocks)

### Accessing Bundle Resources
- `this:bundle resources at:'Filename.html'` returns NSData
- Convert to string: `this:bundle resources at:'Filename.html' | stringValue`
- The bundle's interpreter: `this:bundle interpreter`

### Evaluating Code
- `interpreter evaluateScriptString:code` evaluates Smalltalk code string

### Returning Responses
- Return NSData for HTTP responses
- Convert string to data: `string dataUsingEncoding:4` (4 = NSUTF8StringEncoding)
- Or: `string asData`

### Redirects
- Return a reference to redirect: `ref:/path`

## Common Patterns

### String/Data Conversion
- NSData to NSString: `data | stringValue` or `(data) stringValue`
- NSString to NSData: `string dataUsingEncoding:4` or `string asData`

### Template Rendering (manual)
```
template := this:bundle resources at:'Template.html' | stringValue.
template := template stringByReplacingOccurrencesOfString:'{placeholder}' withString:value.
template dataUsingEncoding:4.
```

### POST Handler Pattern
```
-at:ref post:data {
    value := data at:'fieldName' | stringValue.
    "process value".
    self renderResponse.
}
```

## Mach-O Dylib Generation (ObjSTNative)

### Segment Alignment Requirements
- Both `__TEXT` and `__LINKEDIT` segments must be **16KB (0x4000) aligned**
- This is critical for `mmap()` to work correctly when loading the dylib
- Misaligned segments cause `mmap errno=22 (EINVAL)` failures

### File Layout Rules
```
┌─────────────────────────────────────┐  offset 0x0
│  Mach-O Header (32 bytes)           │
├─────────────────────────────────────┤
│  Load Commands                      │
│  (reserve space for codesign's      │
│   LC_CODE_SIGNATURE ~48 bytes)      │
├─────────────────────────────────────┤
│  __TEXT,__text section data         │
│  (machine code)                     │
├─────────────────────────────────────┤  __TEXT filesize (16KB aligned)
│  Padding to 16KB boundary           │
├─────────────────────────────────────┤  __LINKEDIT fileoff
│  __LINKEDIT data:                   │
│    - Exports trie                   │
│    - Symbol table (nlist_64)        │
│    - String table                   │
├─────────────────────────────────────┤
│  Code signature (added by codesign) │
└─────────────────────────────────────┘
```

### Critical Layout Constraints
1. `__TEXT filesize` must equal `__LINKEDIT fileoff` (no gaps between segments)
2. `__LINKEDIT vmaddr` must equal `__TEXT vmsize` (contiguous in virtual memory)
3. File size must be 8-byte aligned
4. Header's `sizeofcmds` must NOT include reserved space for LC_CODE_SIGNATURE

### Required Load Commands
Minimum set for a loadable dylib:
- `LC_SEGMENT_64` for `__TEXT` (with `__text` section)
- `LC_SEGMENT_64` for `__LINKEDIT`
- `LC_ID_DYLIB` (dylib identification)
- `LC_UUID` (unique identifier)
- `LC_LOAD_DYLIB` (for libSystem.B.dylib dependency)
- `LC_DYLD_EXPORTS_TRIE` or `LC_DYLD_INFO_ONLY` (export information)
- `LC_SYMTAB` (symbol table)
- `LC_DYSYMTAB` (dynamic symbol table)
- `LC_BUILD_VERSION` (platform/SDK info)

### Exports Trie
- Symbol addresses in exports trie must use actual `vmaddr` of the section
- NOT hardcoded values like 0x1000
- Use `section.addr + offset_within_section`

### Code Signing
- Modern macOS requires code signing for dylibs to load
- Use `codesign -s - path/to/dylib` for ad-hoc signing
- Codesign adds `LC_CODE_SIGNATURE` load command and signature data
- Must reserve ~48 bytes in section offset calculation for this load command

### Implementation Reference
See `MPWMachODylibWriter.m` in ObjSTNative for working implementation.
Tests in `testDylibLayoutAssumptions` and `testGeneratedDylibFollowsLayoutAssumptions`
document and verify these requirements.

## Debugging Approach: Differential Analysis with Characterization Tests

When debugging complex binary format issues (like Mach-O dylib generation), use this systematic approach:

### The Loop
1. **Create a reference** using known-good tools (e.g., ObjSTNative object file + system linker)
2. **Create characterization tests** that examine the reference structure using code (MPWMachOReader), not external tools
3. **Run the same tests** on the generated output
4. **Record findings as EXPECT assertions** - this documents what you learned
5. **If structures match but dlopen fails** → add more structural tests to expose hidden differences
6. **If structures differ** → fix the difference
7. **Repeat** until dlopen succeeds

### Key Principles
- **No ad-hoc external tool usage** - put examination logic in tests so it's repeatable
- **Reference files go in TestResources** - ask user to add to Xcode project
- **Tests document the required structure** - each EXPECT records a constraint
- **Focus the loop** - if dlopen fails, the structural tests aren't comprehensive enough yet

### Example: Message Send Dylib
The `testCharacterizeReferenceMessageSendDylib` and `testCharacterizeGeneratedMessageSendDylib` tests:
1. Generate reference: ObjSTNative object file with message send → system linker → signed dylib
2. Examine with MPWMachOReader: segments, sections, exports, chained fixups structure
3. Record as EXPECTs: segment count, section names, import symbols, segment offsets
4. Compare generated dylib against same expectations
5. Differences found led directly to fixes:
   - `_objc_msgSend$` symbols appearing in exports (interception bug)
   - Segment file offsets being zeroed (array reallocation bug)

### Benefits
- Systematic rather than ad-hoc debugging
- Tests remain as regression protection
- Documents binary format requirements
- Differences between reference and generated point directly to bugs

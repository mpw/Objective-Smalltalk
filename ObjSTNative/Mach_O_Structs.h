//
//  Mach_O_Structs.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 16.09.22.
//

#ifndef Mach_O_Structs_h
#define Mach_O_Structs_h

typedef struct {
    int string_offset;
    unsigned char type,section;
    short pad;
    long address;
} symtab_entry;

typedef struct MethodEntry {
    unsigned long name,type,imp;
} MethodEntry;

typedef struct BaseMethods {
    unsigned int entrysize;
    unsigned int count;
    MethodEntry methods[];
} BaseMethods;

typedef struct Mach_O_Class_RO {
    unsigned int flags;
    unsigned int instanceStart,instanceSize;
    unsigned int reserved;
    unsigned long ivarLayout;
    unsigned long name;
    BaseMethods * methods;
    unsigned long baseProtocols,ivars,weakIvarLayout,baseProperties;
} Mach_O_Class_RO;


typedef struct Mach_O_Class {
    struct Mach_O_Class *isa;
    struct Mach_O_Class *superclass;
    void *cache,*vtable;
} Mach_O_Class;


#endif /* Mach_O_Structs_h */

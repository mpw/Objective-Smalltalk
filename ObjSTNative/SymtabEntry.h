//
//  SymtabEntry.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 16.09.22.
//

#ifndef SymtabEntry_h
#define SymtabEntry_h

typedef struct {
    int string_offset;
    unsigned char type,b;
    short pad;
    long address;
} symtab_entry;



#endif /* SymtabEntry_h */

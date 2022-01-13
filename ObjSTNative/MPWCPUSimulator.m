//
//  MPWCPUSimulator.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 11.01.22.
//

#import "MPWCPUSimulator.h"

typedef enum  {
    ADD=0, SUB=1, MUL=2,  DIV=3,  MOD=4,  CMP=5,
    OR=8,  AND=9, BIC=10, XOR=11, SHL=12, SHA=13, CHK=14,
    
    ADDI=16, SUBI=17, MULI=18, DIVI=19, MODI=20, CMPI=21,
    ORI=24,  ANDI=25, BICI=26, XORI=27, SHLI=28, SHAI=29, CHKI=30,
    
    LDW=32,  LDB=33,  POP=34,
    STW=36,  STB=37,  PSH=38,
    
    BEQ=40, BNE=41, BLT=42, BGE=43, BLE=44, BGT=45,
    BSR=46, JSR=48, RET=49,
    
    RD=50, WRD=51, WRH=52, WRL=53,
    
    STP= 55
} opcode;


@implementation MPWCPUSimulator


-(void)interpret:(int)start
{
    int PC=31;
    bool done=false;
    while ( !done ) {
        unsigned long instruction = M[R[PC]];
        int opcode = (instruction >> 20 ) & 63;
        unsigned int a = (instruction >> 26) & 31;
        unsigned int b = (instruction >> 20) & 31;
        unsigned int c = instruction & 65535;
        int cvalue=c;
        if ( opcode < ADDI ) {
            if ( c >= 0 && c <= PC) {
                cvalue=R[c];
            } else {
                // abort
            }
        }
        switch ( instruction) {
            case ADD:
            case ADDI:
                R[a]=R[b]+cvalue;
                break;
            case SUB:
            case SUBI:
                R[a]=R[b]-cvalue;
                break;
            case STP:
                done=YES;
                break;
        }
    }
}

@end

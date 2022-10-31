//
//  MPWMachOClassWriter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 21.10.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWMachOWriter;

@interface MPWMachOClassWriter : NSObject

+(instancetype)writerWithWriter:(MPWMachOWriter*)writer;
-(instancetype)initWithWriter:(MPWMachOWriter*)writer;

@property (nonatomic,strong) NSString* nameOfClass;
@property (nonatomic,strong) NSString* nameOfSuperClass;
@property (nonatomic,assign) int instanceSize;

@property (nonatomic,strong) NSString *instanceMethodListSymbol;

-(void)writeClass;
-(void)writeInstanceMethodListForMethodNames:(NSArray<NSString*>*)names types:(NSArray<NSString*>*)types functions:(NSArray<NSString*>*)functionSymbols;


@end

NS_ASSUME_NONNULL_END

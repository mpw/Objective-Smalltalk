//
//  STZ3Example.m
//  STZ3
//
//  Created by Marcel Weiher on 12.09.25.
//

#import "STZ3Example.h"
#include <z3.h>

@implementation STZ3Example
{
    Z3_config cfg;
    Z3_context ctx;
    Z3_sort int_sort;
}


-(instancetype)init
{
    if (self=[super init]) {
        cfg = Z3_mk_config();
        ctx = Z3_mk_context(cfg);
        int_sort = Z3_mk_int_sort(ctx);
    }
    return self;;
}

-(Z3_ast)makeConst:(const char*)name
{
    Z3_symbol sym = Z3_mk_string_symbol(ctx, name );
    return Z3_mk_const(ctx, sym, int_sort);
}

-(Z3_ast)makeIntConst:(int)value
{
    return Z3_mk_int(ctx, value, int_sort);
}



-(BOOL)example
{
    Z3_ast x = [self makeConst:"x"];
    Z3_ast y = [self makeConst:"y"];

    
    // x + y == 10
    Z3_ast ten = [self makeIntConst:10];
//    Z3_ast ten = Z3_mk_int(ctx, 10, int_sort);
    Z3_ast x_plus_y = Z3_mk_add(ctx, 2, (Z3_ast[]){x, y});
    Z3_ast constraint1 = Z3_mk_eq(ctx, x_plus_y, ten);
    
    // x > 0
    Z3_ast zero = Z3_mk_int(ctx, 0, int_sort);
    Z3_ast constraint2 = Z3_mk_gt(ctx, x, zero);
    
    // Create solver
    Z3_solver solver = Z3_mk_solver(ctx);
    Z3_solver_inc_ref(ctx, solver);
    Z3_solver_assert(ctx, solver, constraint1);
    Z3_solver_assert(ctx, solver, constraint2);
    
    // Check
    if (Z3_solver_check(ctx, solver) == Z3_L_TRUE) {
        printf("SAT\n");
        Z3_model model = Z3_solver_get_model(ctx, solver);
        Z3_model_inc_ref(ctx, model);
        printf("%s\n", Z3_model_to_string(ctx, model));
    } else {
        printf("UNSAT\n");
    }
    return Z3_solver_check(ctx, solver) ;
}

-(void)dealloc
{
    Z3_del_context(ctx);
    Z3_del_config(cfg);
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STZ3Example(testing) 

+(void)someTest
{
    STZ3Example *example=[self new];
 
	EXPECTTRUE([example example], @"satisfied");
}

+(NSArray*)testSelectors
{
   return @[
			@"someTest",
			];
}

@end

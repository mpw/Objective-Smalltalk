//
//  Z3Solver.m
//  STZ3
//
//  Created by Marcel Weiher on 12.09.25.
//

#import "Z3Solver.h"
#include <z3.h>

@interface Z3Ast : NSObject {}

-(instancetype)initWithAst:(Z3_ast)new_ast;

@end

@implementation Z3Ast
{
    Z3_ast ast;
}

-(instancetype)initWithAst:(Z3_ast)new_ast
{
    if ( self=[super init]) {
        ast=new_ast;
    }
    return self;
}

+(instancetype)ast:(Z3_ast)newAst
{
    return [[[self alloc] initWithAst:newAst] autorelease];
}

-(Z3_ast)ast {  return ast; }

@end

@implementation Z3Solver
{
    Z3_config cfg;
    Z3_context ctx;
    Z3_solver solver;
    Z3_sort int_sort;
}


-(instancetype)init
{
    if (self=[super init]) {
        cfg = Z3_mk_config();
        ctx = Z3_mk_context(cfg);
        solver = Z3_mk_solver(ctx);
        Z3_solver_inc_ref(ctx, solver);
        int_sort = Z3_mk_int_sort(ctx);
    }
    return self;;
}

-(Z3Ast*)makeConst:(NSString*)name
{
    Z3_symbol sym = Z3_mk_string_symbol(ctx, [name UTF8String] );
    return [Z3Ast ast:Z3_mk_const(ctx, sym, int_sort)];
}

-(Z3Ast*)makeIntConst:(int)value
{
    return [Z3Ast ast:Z3_mk_int(ctx, value, int_sort)];
}

-(Z3Ast*)make:(Z3Ast*)lhs plus:(Z3Ast*)rhs
{
    return [Z3Ast ast:Z3_mk_add(ctx, 2, (Z3_ast[]){[lhs ast], [rhs ast] })];
}

-(Z3Ast*)make:(Z3Ast*)lhs eq:(Z3Ast*)rhs
{
    return [Z3Ast ast:Z3_mk_eq(ctx, [lhs ast], [rhs ast] )];
}

-(Z3Ast*)make:(Z3Ast*)lhs gt:(Z3Ast*)rhs
{
    return [Z3Ast ast:Z3_mk_gt(ctx, [lhs ast], [rhs ast] )];
}

-(void)assert:(Z3Ast*)expr
{
    Z3_solver_assert(ctx, solver, [expr ast]);
}


-(BOOL)isSatisfied
{
    return Z3_solver_check(ctx, solver) == Z3_L_TRUE ;
}

-(NSString*)modelDescription
{
    if ( Z3_solver_check(ctx, solver) == Z3_L_TRUE ) {
        Z3_model model = Z3_solver_get_model(ctx, solver);
        Z3_model_inc_ref(ctx, model);
        return @(Z3_model_to_string(ctx, model));
    } else {
        return @"Not satisfied";
    }
 
}

-(void)dealloc
{
    Z3_del_context(ctx);
    Z3_del_config(cfg);
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation Z3Solver(testing) 

+(void)someTest
{
    Z3Solver *example=[self new];
    Z3Ast* x = [example makeConst:@"x"];
    Z3Ast* y = [example makeConst:@"y"];
    
    [example assert:[example make:[example make:x plus:y] eq: [example makeIntConst:50]]];
    [example assert:[example make:x gt: [example makeIntConst:1]]];
    [example assert:[example make:y gt: [example makeIntConst:0]]];
    

    BOOL satisfied = [example isSatisfied];
    NSLog(@"model:\n%@",[example modelDescription]);
 
	EXPECTTRUE(satisfied, @"satisfied");
}

+(NSArray*)testSelectors
{
   return @[
			@"someTest",
			];
}

@end

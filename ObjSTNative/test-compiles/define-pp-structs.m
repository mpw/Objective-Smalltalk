#import <MPWFoundation/MPWFoundation.h>

id get(id self,SEL _cmd) {
	return nil;
}
PropertyPathDefs defs = {
	MPWRESTVerbGET,2, {
	{(id)@"hi/there",(IMP)get,NULL },
	{(id)@"hi/:more",(IMP)get,NULL }
       }

};

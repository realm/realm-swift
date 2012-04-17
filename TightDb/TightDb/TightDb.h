//
//  TightDb.h
//  TightDb
//
//  Created by Thomas Andersen on 16/04/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//



#ifdef TIGHT_IMPL
#undef M_TABLE_DEF_2
#define M_TABLE_DEF_2(ctype1, cname1, ctype2, cname2) \
@implementation TightDb \
@synthesize cname1;\
-(ctype1)get##cname1 \
{\
    NSLog(@"Hello world"); \
    return @"Hello return"; \
}\
@end
#else
#undef M_TABLE_DEF_2
#define M_TABLE_DEF_2(ctype1, cname1, ctype2, cname2) \
@interface TightDb : NSObject \
{ \
   ctype1 cname1; \
   ctype2 cname2; \
}\
@property (nonatomic, strong) ctype1 cname1; \
-(ctype1)get##cname1;\
@end
#endif


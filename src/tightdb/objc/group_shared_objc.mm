//
//  group_shared.mm
//  Tightdb_objc
//
//  Created by Tightdb on 11/14/12.
//  Copyright (c) 2012 Tightdb. All rights reserved.
//
#import <tightdb/group_shared.hpp>

#import <tightdb/objc/group_shared.h>
#import <tightdb/objc/group_priv.h>

@implementation SharedGroup
{
    tightdb::SharedGroup* _sharedGroup;
}

#pragma mark - Init

+(SharedGroup *)groupWithFilename:(NSString *)filename
{
    tightdb::SharedGroup* shared_group;
    try {
        shared_group = new tightdb::SharedGroup([filename UTF8String]);
    }
    catch (...) {
        // FIXME: Diffrent exception types mean different things. More
        // details must be made available. We should proably have
        // special catches for at least these:
        // tightdb::File::OpenError (and various derivatives),
        // tightdb::ResourceAllocError, std::bad_alloc. In general,
        // any core library function or operator that is not declared
        // 'noexcept' must be considered as being able to throw
        // anything derived from std::exception.
        return nil;
    }
    SharedGroup* shared_group2 = [[SharedGroup alloc] init];
    if (shared_group2) {
      shared_group2._sharedGroup = shared_group;
    }
    return shared_group2;
}

-(void)dealloc
{
    delete _sharedGroup;
    _sharedGroup = 0;
}


#pragma mark - Transactions

-(void)readTransaction:(SharedGroupReadTransactionBlock)block
{
    Group* group;
    @try {
        group = [Group groupTightdbGroup:(tightdb::Group *)&_sharedGroup->begin_read() readOnly:YES];
        block(group);
    }@catch (NSException *exception) {
        @throw exception;
    }@finally {
        _sharedGroup->end_read();
        [group clearGroup];
    }
}

-(void)writeTransaction:(SharedGroupWriteTransactionBlock)block
{
    Group* group;
    @try {
        group = [Group groupTightdbGroup:&_sharedGroup->begin_write() readOnly:NO];
        if (block(group))
            _sharedGroup->commit();
        else
            _sharedGroup->rollback();
        [group clearGroup];
    }
    @catch (NSException *exception) {
        _sharedGroup->rollback();
        [group clearGroup];
        @throw exception;
    }
}


@end

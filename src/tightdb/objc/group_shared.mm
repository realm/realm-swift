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
    tightdb::SharedGroup *_sharedGroup;
}

#pragma mark - Init

+(SharedGroup *)groupWithFilename:(NSString *)filename
{
    SharedGroup *group = [[SharedGroup alloc] init];
    if (group) {
        group->_sharedGroup = new tightdb::SharedGroup([filename UTF8String]);
    }
    return group;
}

-(void)dealloc
{
    delete _sharedGroup;
    _sharedGroup = 0;
}


#pragma mark - Transactions

-(void)readTransaction:(SharedGroupReadTransactionBlock)block
{
    Group *group;
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
    Group *group;
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

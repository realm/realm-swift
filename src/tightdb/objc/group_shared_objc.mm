#include <tightdb/group_shared.hpp>

#import <tightdb/objc/group_shared.h>
#import <tightdb/objc/group_priv.h>

#include <tightdb/objc/util.hpp>

using namespace std;


@implementation TightdbSharedGroup
{
    tightdb::SharedGroup* _sharedGroup;
}

+(TightdbSharedGroup *)groupWithFilename:(NSString *)filename
{
    return [self groupWithFilename:filename error:nil];
}

+(TightdbSharedGroup *)groupWithFilename:(NSString *)filename error:(NSError *__autoreleasing *)error
{
    tightdb::SharedGroup* shared_group;
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 shared_group = new tightdb::SharedGroup(tightdb::StringData(ObjcStringAccessor(filename)));
                                 , @"com.tightdb.sharedgroup",
                                 return nil;
                                 );
    TightdbSharedGroup* shared_group2 = [[TightdbSharedGroup alloc] init];
    if (shared_group2) {
      shared_group2->_sharedGroup = shared_group;
    }
    return shared_group2;
}

-(void)dealloc
{
    delete _sharedGroup;
    _sharedGroup = 0;
}

-(BOOL)readTransaction:(TightdbSharedGroupReadTransactionBlock)block
{
    return [self readTransaction:block error:nil];
}
-(BOOL)readTransaction:(TightdbSharedGroupReadTransactionBlock)block error:(NSError *__autoreleasing *)error
{
    TightdbGroup* group;
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 group = [TightdbGroup groupTightdbGroup:(tightdb::Group *)&_sharedGroup->begin_read() readOnly:YES];
                                 block(group);
                                 _sharedGroup->end_read();
                                 [group clearGroup];
                                 , @"com.tightdb.sharedgroup",
                                 _sharedGroup->end_read();
                                 [group clearGroup];
                                 return NO;
                                 );
    return YES;
}

-(BOOL)writeTransaction:(TightdbSharedGroupWriteTransactionBlock)block
{
    return [self writeTransaction:block error:nil];
}
-(BOOL)writeTransaction:(TightdbSharedGroupWriteTransactionBlock)block error:(NSError *__autoreleasing *)error
{
    TightdbGroup* group;
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 group = [TightdbGroup groupTightdbGroup:&_sharedGroup->begin_write() readOnly:NO];
                                 if (block(group))
                                 _sharedGroup->commit();
                                 else
                                 _sharedGroup->rollback();
                                 [group clearGroup];
                                 , @"com.tightdb.sharedgroup",
                                 _sharedGroup->rollback();
                                 [group clearGroup];
                                 return NO;
                                 );
    return YES;
}


@end

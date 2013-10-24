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
    tightdb::SharedGroup* shared_group;
    try {
        shared_group = new tightdb::SharedGroup(tightdb::StringData(ObjcStringAccessor(filename)));
    }
    catch (...) {
        // FIXME: Diffrent exception types mean different things. More
        // details must be made available. We should proably have
        // special catches for at least these:
        // tightdb::File::AccessError (and various derivatives),
        // tightdb::ResourceAllocError, std::bad_alloc. In general,
        // any core library function or operator that is not declared
        // 'noexcept' must be considered as being able to throw
        // anything derived from std::exception.
        return nil;
    }
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


/*-(void)readTransaction:(TightdbSharedGroupReadTransactionBlock)block
{
    TightdbGroup* group;
    @try {
        group = [TightdbGroup groupTightdbGroup:(tightdb::Group *)&_sharedGroup->begin_read() readOnly:YES];
        block(group);
    }
    @catch (NSException *exception) {
        @throw exception;
    }
    @finally {
        _sharedGroup->end_read();
        [group clearGroup];
    }
}*/

-(void)readTransaction:(TightdbSharedGroupReadTransactionBlock)block
{
    TightdbGroup *group;

    try {
        group = [TightdbGroup groupTightdbGroup:(tightdb::Group *)&_sharedGroup->begin_read() readOnly:YES];
    }
    catch (std::exception &ex) {
        // File related problems are not expected after the shared group is created. The file content
        // was already memory mapped when the shared group was created. If begin read_trows, a severe 
        // problem has occcured (such as out of memory).
        _sharedGroup->end_read();
        [group clearGroup];
        NSException *exception = [NSException exceptionWithName:@"tightdb:core_exception"
                                              reason:[NSString stringWithUTF8String:ex.what()]
                                              userInfo:nil];
        [exception raise];
    }

    @try {
        // Assuming a block only throws NSException. No TightDB Obj-C methods used in the block
        // should throw anything but NSException or derivatives. Note: if the client calls other libraries
        // throwing other kinds of exceptions they will leak back to the client code, if he does not
        // catch them within the block.
        block(group);
    }
    @catch (NSException *exception) {
        @throw exception;
    }
    @finally {
        _sharedGroup->end_read();
        [group clearGroup];
    }
}


-(BOOL)writeTransaction(TightdbSharedGroupWriteTransactionBlock)block error:(NSError **error)
{
    TightdbGroup *group;
    try {
        group = [TightdbGroup groupTightdbGroup:&_sharedGroup->begin_write() readOnly:NO];
        
    } catch (std::exception &ex) {
        // As in read transactions, file related problems are not expected after the shared group
        // is created. Therefore, we currently convert and re-throw all core exceptions as NSExceptions.

        // TODO: In the future, more specific exceptions such as network issues (w. replication)
        // may be caught and reported as an NSError.

        _sharedGroup->end_read();
        [group clearGroup];
        NSException *exception = [NSException exceptionWithName:@"tightdb:core_exception"
                                              reason:[NSString stringWithUTF8String:ex.what()]
                                              userInfo:nil];
        [exception raise];
    }

    @try {
        BOOL confirmation = block(group);

        if (confirmation) {


            // Required to avoid leaking core exceptions.
            try {
                _sharedGroup->commit();
            } catch (std::exception &ex) {
                NSException *exception = [NSException exceptionWithName:@"tightdb:core_exception"
                                                      reason:[NSString stringWithUTF8String:ex.what()]
                                                      userInfo:nil];
                [exception raise];
            }


            [group clearGroup];
            return YES;

        } else {
            *error = [NSError errorWithDomain:@"TBD";
                                         code:@"Commit was cancelled by client code"
                                     userInfo:@"TBD"];

            _sharedGroup->rollback();
            [group clearGroup];
            return NO;
        }
    }
    @catch (NSException *exception) {
        _sharedGroup->rollback();
        [group clearGroup];
        @throw exception;
    }
}

/*-(void)writeTransaction:(TightdbSharedGroupWriteTransactionBlock)block
{
    TightdbGroup* group;
    @try {
        group = [TightdbGroup groupTightdbGroup:&_sharedGroup->begin_write() readOnly:NO];
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
}*/


@end

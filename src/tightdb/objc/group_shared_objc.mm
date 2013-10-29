#include <tightdb/group_shared.hpp>

#import <tightdb/objc/group_shared.h>
#import <tightdb/objc/group_priv.h>

#include <tightdb/objc/util.hpp>

using namespace std;


@implementation TightdbSharedGroup
{
    tightdb::SharedGroup* _sharedGroup;
}

+(TightdbSharedGroup *)sharedGroupWithFilename:(NSString *)filename withError:(NSError **)error  // TODO: Confirm __autoreleasing is not needed wiht ARC
{
    tightdb::SharedGroup* shared_group;
    try {
        shared_group = new tightdb::SharedGroup(tightdb::StringData(ObjcStringAccessor(filename)));
    }
    // TODO: capture this in a macro or function, group constructor uses the same pattern.
    catch (tightdb::File::PermissionDenied &ex) {
        if(error) // allow nil as the error argument
            *error = make_tightdb_error(@"com.tightdb.sharedgroup", tdb_err_File_PermissionDenied, [NSString stringWithUTF8String:ex.what()]);
        return nil;

    }
    catch (tightdb::File::Exists &ex) {
        if(error) // allow nil as the error argument
            *error = make_tightdb_error(@"com.tightdb.sharedgroup", tdb_err_File_Exists, [NSString stringWithUTF8String:ex.what()]);
        return nil;

    }
    catch (tightdb::File::AccessError &ex) {
        if(error) // allow nil as the error argument
            *error = make_tightdb_error(@"com.tightdb.sharedgroup", tdb_err_File_AccessError, [NSString stringWithUTF8String:ex.what()]);
        return nil;

    }
    catch (std::exception &ex) {
        if(error) // allow nil as the error argument
            *error = make_tightdb_error(@"com.tightdb.sharedgroup", tdb_err_Fail, [NSString stringWithUTF8String:ex.what()]);
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

-(void)readTransactionWithBlock:(TightdbSharedGroupReadTransactionBlock)block
{
    TightdbGroup *group;
    const tightdb::Group *coreGroup;

    try {
        coreGroup = &_sharedGroup->begin_read();
    } catch (std::exception &ex) {
        NSException *exception = [NSException exceptionWithName:@"tightdb:core_exception"
                                                         reason:[NSString stringWithUTF8String:ex.what()]
                                                       userInfo:[NSMutableDictionary dictionary]];  // IMPORTANT: cannot not be nil !!
        [exception raise];                                                                          
    }

    @try {
        // No TightDB Obj-C methods used in the block
        // should throw anything but NSException or derivatives. Note: if the client calls other libraries
        // throwing other kinds of exceptions they will leak back to the client code, if he does not
        // catch them within the block.
        group = [TightdbGroup groupTightdbGroup:(tightdb::Group *)coreGroup readOnly:YES];  // TODO: const cast
        block(group);

    }
    @catch (NSException *exception) {
        // may be unnessesary to catch and re-throw here
        @throw;
    }
    @finally {
        _sharedGroup->end_read();
        [group clearGroup];
    }
}


-(BOOL)writeTransactionWithError:(NSError **)error withBlock:(TightdbSharedGroupWriteTransactionBlock)block
{

    TightdbGroup *group;
    tightdb::Group *coreGroup;

    try {
        coreGroup = &_sharedGroup->begin_write();
    } catch (std::exception &ex) {
        // File access errors are treated as exceptions here since they should not occur after the shared 
        // group has already beenn successfully opened on the file and memeory mapped. The shared group constructor handles
        // the excepted error related to file access.
        NSException *exception = [NSException exceptionWithName:@"tightdb:core_exception"
                                                         reason:[NSString stringWithUTF8String:ex.what()]
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }
 
    @try {
        group = [TightdbGroup groupTightdbGroup:coreGroup readOnly:NO];

        BOOL confirmation = block(group);
        
        if (confirmation) {


            // Required to avoid leaking of core exceptions.
            try {
                _sharedGroup->commit();
            } catch (std::exception &ex) {
                NSException *exception = [NSException exceptionWithName:@"tightdb:core_exception"
                                                      reason:@""
                                                      userInfo:[NSMutableDictionary dictionary]];
                [exception raise];
            }

            [group clearGroup];
            return YES;

        } else {
            // As of now the only kind of error is when the block decides to rollback.
            // In the future, other kinds may be relevant (network error etc)..
            // It could be discussed if rollback is an error at all. But, if the method is 
            // returning NO it makes sense the user can check the error an see that it
            // was caused by a decision of the block to roll back.

            if(error) // allow nil as the error argument
                *error = make_tightdb_error(@"com.tightdb.sharedgroup", tdb_err_Rollback, @"The block code requested a rollback");

            _sharedGroup->rollback();
            [group clearGroup];
            return NO;
        }
    }
    @catch (NSException *exception) {  
        _sharedGroup->rollback();
        [group clearGroup];
        @throw; // exception

    }
}


@end

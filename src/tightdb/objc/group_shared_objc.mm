#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/group_shared.hpp>

#import <tightdb/objc/group_shared.h>
#import <tightdb/objc/group_priv.h>

#include <tightdb/objc/util.hpp>

using namespace std;


@implementation TightdbSharedGroup
{
    tightdb::util::UniquePtr<tightdb::SharedGroup> m_shared_group;
}

+(TightdbSharedGroup*)groupWithFilename:(NSString*)filename
{
    TightdbSharedGroup* shared_group = [[TightdbSharedGroup alloc] init];
    if (!shared_group)
        return nil;
    try {
        shared_group->m_shared_group.reset(new tightdb::SharedGroup(tightdb::StringData(ObjcStringAccessor(filename))));
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
    return shared_group;
}

-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"TightdbSharedGroup dealloc");
#endif
}


-(void)readTransaction:(TightdbSharedGroupReadTransactionBlock)block
{
    @try {
        const tightdb::Group& group = m_shared_group->begin_read();
        TightdbGroup* group_2 = [TightdbGroup groupWithNativeGroup:const_cast<tightdb::Group*>(&group) isOwned:NO readOnly:YES];
        block(group_2);
    }
    @catch (NSException* exception) {
        @throw exception;
    }
    @finally {
        m_shared_group->end_read();
    }
}

-(void)writeTransaction:(TightdbSharedGroupWriteTransactionBlock)block
{
    @try {
        tightdb::Group& group = m_shared_group->begin_write();
        TightdbGroup* group_2 = [TightdbGroup groupWithNativeGroup:&group isOwned:NO readOnly:NO];
        if (block(group_2)) {
            m_shared_group->commit();
        }
        else {
            m_shared_group->rollback();
        }
    }
    @catch (NSException* exception) {
        m_shared_group->rollback();
        @throw exception;
    }
}


@end

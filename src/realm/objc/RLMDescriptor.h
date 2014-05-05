////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>


@interface RLMDescriptor : NSObject

@property (nonatomic, readonly) NSUInteger columnCount;

// Returns index of new column or NSNotFound if an error occurred.

-(NSUInteger)addColumnWithName:(NSString *)name type:(RLMType)type;

// Returns nil on memory allocation error.

-(RLMDescriptor *)addColumnTable:(NSString *)name;
-(RLMDescriptor *)subdescriptorForColumnWithIndex:(NSUInteger)colIndex;
-(RLMDescriptor *)subdescriptorForColumnWithIndex:(NSUInteger)colIndex error:(NSError *__autoreleasing *)error;

-(RLMType)columnTypeOfColumnWithIndex:(NSUInteger)colIndex;
-(NSString *)nameOfColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)indexOfColumnWithName:(NSString *)name;
@end


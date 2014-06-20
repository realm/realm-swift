////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#pragma mark - Swift class name parsing

// Code adapted from this Swift version: https://gist.github.com/jpsim/1b86d116808cb4e9bc30

typedef NS_ENUM(NSInteger, RLMClassType) {
    RLMClassTypeSwift,
    RLMClassTypeObjectiveC
};

struct RLMParsedClass {
    RLMClassType type;
    NSString *name;
    
    NSString *mangledName;
    NSString *moduleName;
};

inline RLMParsedClass RLMParsedClassFromClass(Class aClass) {
    // Swift mangling details found here: http://www.eswick.com/2014/06/inside-swift
    
    NSString *originalName = NSStringFromClass(aClass);
    
    struct RLMParsedClass parsedClass;
    
    if ([originalName rangeOfString:@"_T"].location != 0) {
        // Not a Swift symbol
        parsedClass.type = RLMClassTypeObjectiveC;
        parsedClass.name = originalName;
        return parsedClass;
    }
    
    parsedClass.type = RLMClassTypeSwift;
    parsedClass.mangledName = originalName;
    
    NSUInteger originalNameLength = originalName.length;
    NSUInteger cursor = 4;
    NSString *substring = [originalName substringWithRange:NSMakeRange(cursor, originalNameLength - cursor)];
    
    // Module
    NSUInteger moduleLength = substring.integerValue;
    NSUInteger moduleLengthLength = [NSString stringWithFormat:@"%lu", (unsigned long)moduleLength].length;
    parsedClass.moduleName = [substring substringWithRange:NSMakeRange(moduleLengthLength, moduleLength)];
    
    // Update cursor and substring
    cursor += moduleLengthLength + moduleLength;
    substring = [originalName substringWithRange:NSMakeRange(cursor, originalNameLength - cursor)];
    
    // Class name
    NSUInteger classLength = substring.integerValue;
    NSUInteger classLengthLength = [NSString stringWithFormat:@"%lu", (unsigned long)classLength].length;
    parsedClass.name = [substring substringWithRange:NSMakeRange(classLengthLength, classLength)];
    
    return parsedClass;
}

#pragma mark - Swift ivar encoding detection

// Code from here (MIT-licensed): https://github.com/johnno1962/XprobePlugin/blob/master/Classes/Xprobe.mm#L1491
//
//  Created by John Holdsworth on 17/05/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//
//  For full licensing term see https://github.com/johnno1962/XprobePlugin
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

struct _swift_class;

struct _swift_type {
    unsigned long flags;
    const char *typeIdent;
};

struct _swift_field {
    unsigned long flags;
    union {
        struct _swift_type *typeInfo;
        Class objcClass;
    };
    void *unknown;
    struct _swift_field *conditional;
    union {
        struct _swift_class *swiftClass;
        struct _swift_field *subType;
    };
};

struct _swift_data {
    unsigned long flags;
    const char *className;
    int fieldcount, flasg2;
    const char *ivarNames;
    struct _swift_field **(*get_field_data)();
};

struct _swift_class {
    union {
        Class meta;
        unsigned long flags;
    };
    Class supr;
    void *buckets, *vtable, *pdata;
    int size, tos, mds, eight;
    struct _swift_data *swiftData;
};

static const char *typeInfoForName( const char *name ) {
    return strdup([[NSString stringWithFormat:@"@\"%s\"", name] UTF8String]);
}

static const char *typeInfoForClass( Class aClass ) {
    return typeInfoForName( class_getName(aClass) );
}

static const char *ivar_getTypeEncodingSwift( Ivar ivar, Class aClass ) {
    struct _swift_class *swiftClass = (__bridge struct _swift_class *)aClass;
    if ( !((unsigned long)swiftClass->pdata & 0x1) )
        return ivar_getTypeEncoding( ivar );
    
    struct _swift_data *swiftData = swiftClass->swiftData;
    const char *nameptr = swiftData->ivarNames;
    const char *name = ivar_getName(ivar);
    int ivarIndex;
    
    for ( ivarIndex=0 ; ivarIndex<swiftData->fieldcount ; ivarIndex++ )
        if ( strcmp(name,nameptr) == 0 )
            break;
        else
            nameptr += strlen(nameptr)+1;
    
    if ( ivarIndex == swiftData->fieldcount )
        return NULL;
    
    struct _swift_field **swiftFields = swiftData->get_field_data();
    struct _swift_field *field = swiftFields[ivarIndex];
    struct _swift_class *ivarClass = field->swiftClass;
    
    // this could probably be tidied up if I knew what was going on...
    if ( field->flags == 0x2 && (field->conditional->flags > 0x2 || (ivarClass && ivarClass->flags>0x2) ) )
        return typeInfoForName(field->typeInfo->typeIdent);
    else if ( field->flags == 0xe )
        return typeInfoForClass(field->objcClass);
    else if ( field->conditional && field->conditional->flags<0xf ) {
        if ( field->conditional->flags == 0xe )
            return typeInfoForClass(field->conditional->objcClass);
        else
            return field->conditional->typeInfo->typeIdent+1;
    }
    else if ( !ivarClass )
        return field->typeInfo->typeIdent+1;
    else if ( ivarClass->flags == 0x1 )
        return field->subType->typeInfo->typeIdent+1;
    else if ( ivarClass->flags == 0xe )
        return typeInfoForClass(field->subType->objcClass);
    else
        return typeInfoForClass((__bridge Class)ivarClass);
}

inline const char *ivar_getRLMTypeEncodingSwift( Ivar ivar, Class aClass ) {
    const char *encoding = ivar_getTypeEncodingSwift(ivar, aClass);
    if (*(encoding) == 'b') {
        return "c";
    }
    return encoding;
}

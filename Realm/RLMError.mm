////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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

#import "RLMError_Private.hpp"

#import "RLMUtil.hpp"

#import <realm/util/basic_system_errors.hpp>

NSString *const RLMErrorDomain                   = @"io.realm";
NSString *const RLMUnknownSystemErrorDomain      = @"io.realm.unknown";

NSString *const RLMErrorCodeKey                  = @"Error Code";
NSString *const RLMErrorCodeNameKey              = @"Error Name";

namespace {
NSInteger translateFileError(realm::ErrorCodes::Error code) {
    using ec = realm::ErrorCodes::Error;
    switch (code) {
        // Local errors
        case ec::AddressSpaceExhausted:                return RLMErrorAddressSpaceExhausted;
        case ec::DeleteOnOpenRealm:                    return RLMErrorAlreadyOpen;
        case ec::FileAlreadyExists:                    return RLMErrorFileExists;
        case ec::FileFormatUpgradeRequired:            return RLMErrorFileFormatUpgradeRequired;
        case ec::FileNotFound:                         return RLMErrorFileNotFound;
        case ec::FileOperationFailed:                  return RLMErrorFileOperationFailed;
        case ec::IncompatibleHistories:                return RLMErrorIncompatibleHistories;
        case ec::IncompatibleLockFile:                 return RLMErrorIncompatibleLockFile;
        case ec::IncompatibleSession:                  return RLMErrorIncompatibleSession;
        case ec::InvalidDatabase:                      return RLMErrorInvalidDatabase;
        case ec::OutOfDiskSpace:                       return RLMErrorOutOfDiskSpace;
        case ec::PermissionDenied:                     return RLMErrorFilePermissionDenied;
        case ec::SchemaMismatch:                       return RLMErrorSchemaMismatch;
        case ec::UnsupportedFileFormatVersion:         return RLMErrorUnsupportedFileFormatVersion;

        default: {
            auto category = realm::ErrorCodes::error_categories(code);
            if (category.test(realm::ErrorCategory::file_access)) {
                return RLMErrorFileAccess;
            }
            return RLMErrorFail;
        }
    }
}

NSString *errorString(realm::ErrorCodes::Error error) {
    return RLMStringViewToNSString(realm::ErrorCodes::error_string(error));
}

NSError *translateSystemError(std::error_code ec, const char *msg) {
    int code = ec.value();
    BOOL isGenericCategoryError = ec.category() == std::generic_category()
                               || ec.category() == realm::util::error::basic_system_error_category();
    NSString *errorDomain = isGenericCategoryError ? NSPOSIXErrorDomain : RLMUnknownSystemErrorDomain;

    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    userInfo[NSLocalizedDescriptionKey] = @(msg);
    return [NSError errorWithDomain:errorDomain code:code userInfo:userInfo.copy];
}
} // anonymous namespace

NSError *makeError(realm::Status const& status) {
    if (status.is_ok()) {
        return nil;
    }
    auto code = translateFileError(status.code());
    return [NSError errorWithDomain:RLMErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: @(status.reason().c_str()),
                                      RLMErrorCodeNameKey: errorString(status.code())}];
}

NSError *makeError(realm::Exception const& exception) {
    NSInteger code = translateFileError(exception.code());
    return [NSError errorWithDomain:RLMErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: @(exception.what()),
                                      RLMErrorCodeNameKey: errorString(exception.code())}];

}

NSError *makeError(realm::FileAccessError const& exception) {
    NSInteger code = translateFileError(exception.code());
    return [NSError errorWithDomain:RLMErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: @(exception.what()),
                                      NSFilePathErrorKey: @(exception.get_path().data()),
                                      RLMErrorCodeNameKey: errorString(exception.code())}];
}

NSError *makeError(std::exception const& exception) {
    return [NSError errorWithDomain:RLMErrorDomain
                               code:RLMErrorFail
                           userInfo:@{NSLocalizedDescriptionKey: @(exception.what())}];
}

NSError *makeError(std::system_error const& exception) {
    return translateSystemError(exception.code(), exception.what());
}

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
#import "RLMSyncSession_Private.hpp"

#import <realm/object-store/sync/app.hpp>
#import <realm/util/basic_system_errors.hpp>
#import <realm/sync/client.hpp>

// NEXT-MAJOR: we should merge these all into a single error domain/error enum
NSString *const RLMErrorDomain                   = @"io.realm";
NSString *const RLMUnknownSystemErrorDomain      = @"io.realm.unknown";
NSString *const RLMSyncErrorDomain               = @"io.realm.sync";
NSString *const RLMSyncAuthErrorDomain           = @"io.realm.sync.auth";
NSString *const RLMAppErrorDomain                = @"io.realm.app";

NSString *const kRLMSyncPathOfRealmBackupCopyKey = @"recovered_realm_location_path";
NSString *const kRLMSyncErrorActionTokenKey      = @"error_action_token";
NSString *const RLMErrorCodeKey                  = @"Error Code";
NSString *const RLMErrorCodeNameKey              = @"Error Name";
NSString *const RLMServerLogURLKey               = @"Server Log URL";
NSString *const RLMCompensatingWriteInfoKey      = @"Compensating Write Info";
NSString *const RLMHTTPStatusCodeKey             = @"HTTP Status Code";
static NSString *const RLMDeprecatedErrorCodeKey = @"Error Code";

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
        case ec::MultipleSyncAgents:                   return RLMErrorMultipleSyncAgents;
        case ec::NoSubscriptionForWrite:               return RLMErrorNoSubscriptionForWrite;
        case ec::OutOfDiskSpace:                       return RLMErrorOutOfDiskSpace;
        case ec::PermissionDenied:                     return RLMErrorFilePermissionDenied;
        case ec::SchemaMismatch:                       return RLMErrorSchemaMismatch;
        case ec::SubscriptionFailed:                   return RLMErrorSubscriptionFailed;
        case ec::UnsupportedFileFormatVersion:         return RLMErrorUnsupportedFileFormatVersion;

        // Sync errors
        case ec::AuthError:                            return RLMSyncErrorClientUserError;
        case ec::SyncPermissionDenied:                 return RLMSyncErrorPermissionDeniedError;
        case ec::SyncCompensatingWrite:                return RLMSyncErrorWriteRejected;
        case ec::SyncConnectFailed:                    return RLMSyncErrorConnectionFailed;
        case ec::TlsHandshakeFailed:                   return RLMSyncErrorTLSHandshakeFailed;
        case ec::SyncConnectTimeout:                   return ETIMEDOUT;

        // App errors
        case ec::APIKeyAlreadyExists:                  return RLMAppErrorAPIKeyAlreadyExists;
        case ec::AccountNameInUse:                     return RLMAppErrorAccountNameInUse;
        case ec::AppUnknownError:                      return RLMAppErrorUnknown;
        case ec::AuthProviderNotFound:                 return RLMAppErrorAuthProviderNotFound;
        case ec::DomainNotAllowed:                     return RLMAppErrorDomainNotAllowed;
        case ec::ExecutionTimeLimitExceeded:           return RLMAppErrorExecutionTimeLimitExceeded;
        case ec::FunctionExecutionError:               return RLMAppErrorFunctionExecutionError;
        case ec::FunctionInvalid:                      return RLMAppErrorFunctionInvalid;
        case ec::FunctionNotFound:                     return RLMAppErrorFunctionNotFound;
        case ec::FunctionSyntaxError:                  return RLMAppErrorFunctionSyntaxError;
        case ec::InvalidPassword:                      return RLMAppErrorInvalidPassword;
        case ec::InvalidSession:                       return RLMAppErrorInvalidSession;
        case ec::MaintenanceInProgress:                return RLMAppErrorMaintenanceInProgress;
        case ec::MissingParameter:                     return RLMAppErrorMissingParameter;
        case ec::MongoDBError:                         return RLMAppErrorMongoDBError;
        case ec::NotCallable:                          return RLMAppErrorNotCallable;
        case ec::ReadSizeLimitExceeded:                return RLMAppErrorReadSizeLimitExceeded;
        case ec::UserAlreadyConfirmed:                 return RLMAppErrorUserAlreadyConfirmed;
        case ec::UserAppDomainMismatch:                return RLMAppErrorUserAppDomainMismatch;
        case ec::UserDisabled:                         return RLMAppErrorUserDisabled;
        case ec::UserNotFound:                         return RLMAppErrorUserNotFound;
        case ec::ValueAlreadyExists:                   return RLMAppErrorValueAlreadyExists;
        case ec::ValueDuplicateName:                   return RLMAppErrorValueDuplicateName;
        case ec::ValueNotFound:                        return RLMAppErrorValueNotFound;

        case ec::AWSError:
        case ec::GCMError:
        case ec::HTTPError:
        case ec::InternalServerError:
        case ec::TwilioError:
            return RLMAppErrorInternalServerError;

        case ec::ArgumentsNotAllowed:
        case ec::BadRequest:
        case ec::InvalidParameter:
            return RLMAppErrorBadRequest;

        default: {
            auto category = realm::ErrorCodes::error_categories(code);
            if (category.test(realm::ErrorCategory::file_access)) {
                return RLMErrorFileAccess;
            }
            if (category.test(realm::ErrorCategory::app_error)) {
                return RLMAppErrorUnknown;
            }
            if (category.test(realm::ErrorCategory::sync_error)) {
                return RLMSyncErrorClientInternalError;
            }
            return RLMErrorFail;
        }
    }
}

NSString *errorDomain(realm::ErrorCodes::Error error) {
    if (error == realm::ErrorCodes::SyncConnectTimeout) {
        return NSPOSIXErrorDomain;
    }
    auto category = realm::ErrorCodes::error_categories(error);
    if (category.test(realm::ErrorCategory::sync_error)) {
        return RLMSyncErrorDomain;
    }
    if (category.test(realm::ErrorCategory::app_error)) {
        return RLMAppErrorDomain;
    }
    return RLMErrorDomain;
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
    // FIXME: remove these in v11
    userInfo[@"Error Code"] = @(code);
    userInfo[@"Category"] = @(ec.category().name());

    return [NSError errorWithDomain:errorDomain code:code userInfo:userInfo.copy];
}
} // anonymous namespace

NSError *makeError(realm::Status const& status) {
    if (status.is_ok()) {
        return nil;
    }
    auto code = translateFileError(status.code());
    return [NSError errorWithDomain:errorDomain(status.code())
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: @(status.reason().c_str()),
                                      RLMDeprecatedErrorCodeKey: @(code),
                                      RLMErrorCodeNameKey: errorString(status.code())}];
}

NSError *makeError(realm::Exception const& exception) {
    NSInteger code = translateFileError(exception.code());
    return [NSError errorWithDomain:errorDomain(exception.code())
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: @(exception.what()),
                                      RLMDeprecatedErrorCodeKey: @(code),
                                      RLMErrorCodeNameKey: errorString(exception.code())}];

}

NSError *makeError(realm::FileAccessError const& exception) {
    NSInteger code = translateFileError(exception.code());
    return [NSError errorWithDomain:errorDomain(exception.code())
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: @(exception.what()),
                                      NSFilePathErrorKey: @(exception.get_path().data()),
                                      RLMDeprecatedErrorCodeKey: @(code),
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

__attribute__((objc_direct_members))
@implementation RLMCompensatingWriteInfo {
    realm::sync::CompensatingWriteErrorInfo _info;
}

- (instancetype)initWithInfo:(realm::sync::CompensatingWriteErrorInfo&&)info {
    if ((self = [super init])) {
        _info = std::move(info);
    }
    return self;
}

- (NSString *)objectType {
    return @(_info.object_name.c_str());
}

- (NSString *)reason {
    return @(_info.reason.c_str());
}

- (id<RLMValue>)primaryKey {
    return RLMMixedToObjc(_info.primary_key);
}
@end

NSError *makeError(realm::SyncError&& error) {
    auto& status = error.status;
    if (status.is_ok()) {
        return nil;
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    userInfo[NSLocalizedDescriptionKey] = RLMStringViewToNSString(error.simple_message);
    if (!error.logURL.empty()) {
        userInfo[RLMServerLogURLKey] = RLMStringViewToNSString(error.logURL);
    }
    if (!error.compensating_writes_info.empty()) {
        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:error.compensating_writes_info.size()];
        for (auto& info : error.compensating_writes_info) {
            [array addObject:[[RLMCompensatingWriteInfo alloc] initWithInfo:std::move(info)]];
        }
        userInfo[RLMCompensatingWriteInfoKey] = [array copy];
    }
    for (auto& pair : error.user_info) {
        if (pair.first == realm::SyncError::c_original_file_path_key) {
            userInfo[kRLMSyncErrorActionTokenKey] =
                [[RLMSyncErrorActionToken alloc] initWithOriginalPath:pair.second];
        }
        else if (pair.first == realm::SyncError::c_recovery_file_path_key) {
            userInfo[kRLMSyncPathOfRealmBackupCopyKey] = @(pair.second.c_str());
        }
    }

    int errorCode = RLMSyncErrorClientInternalError;
    NSString *errorDomain = RLMSyncErrorDomain;
    using enum realm::ErrorCodes::Error;
    auto code = error.status.code();
    bool isSyncError = realm::ErrorCodes::error_categories(code).test(realm::ErrorCategory::sync_error);
    switch (code) {
        case SyncPermissionDenied:
            errorCode = RLMSyncErrorPermissionDeniedError;
            break;
        case AuthError:
            errorCode = RLMSyncErrorClientUserError;
            break;
        case SyncCompensatingWrite:
            errorCode = RLMSyncErrorWriteRejected;
            break;
        case SyncConnectFailed:
            errorCode = RLMSyncErrorConnectionFailed;
            break;
        case SyncConnectTimeout:
            errorCode = ETIMEDOUT;
            errorDomain = NSPOSIXErrorDomain;
            break;

        default:
            if (error.is_client_reset_requested())
                errorCode = RLMSyncErrorClientResetError;
            else if (isSyncError)
                errorCode = RLMSyncErrorClientSessionError;
            else if (!error.is_fatal)
                return nil;
            break;
    }

    return [NSError errorWithDomain:errorDomain code:errorCode userInfo:userInfo.copy];
}

NSError *makeError(realm::app::AppError const& appError) {
    auto& status = appError.to_status();
    if (status.is_ok()) {
        return nil;
    }

    // Core uses the same error code for both sync and app auth errors, but we
    // have separate ones
    auto code = translateFileError(status.code());
    auto domain = errorDomain(status.code());
    if (domain == RLMSyncErrorDomain && code == RLMSyncErrorClientUserError) {
        domain = RLMAppErrorDomain;
        code = RLMAppErrorAuthError;
    }
    return [NSError errorWithDomain:domain code:code
                           userInfo:@{NSLocalizedDescriptionKey: @(status.reason().c_str()),
                                      RLMDeprecatedErrorCodeKey: @(code),
                                      RLMErrorCodeNameKey: errorString(status.code()),
                                      RLMServerLogURLKey: @(appError.link_to_server_logs.c_str())}];
}

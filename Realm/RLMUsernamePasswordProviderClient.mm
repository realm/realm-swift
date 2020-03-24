////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

#import "RLMUsernamePasswordProviderClient.h"
#import "RLMApp_Private.hpp"

@implementation RLMUsernamePasswordProviderClient

static NSError* AppErrorToNSError(const realm::app::AppError& appError) {
    return [[NSError alloc] initWithDomain:@(appError.error_code.category().name())
                                      code:appError.error_code.value()
                                  userInfo:@{
                                      @(appError.error_code.category().name()) : @(appError.error_code.message().data())
                                  }];
}

- (void)registerEmail:(NSString *)email
             password:(NSString *)password
    completionHandler:(RLMOptionalErrorBlock)completionHandler {
    self.app._realmApp.provider_client<realm::app::App::UsernamePasswordProviderClient>().
    register_email(email.UTF8String, password.UTF8String, ^(Optional<realm::app::AppError> error) {
        if (error && error->error_code) {
            return completionHandler(AppErrorToNSError(*error));
        }
        completionHandler(nil);
    });
}

- (void)confirmUser:(NSString *)token
            tokenId:(NSString *)tokenId
  completionHandler:(RLMOptionalErrorBlock)completionHandler {
    self.app._realmApp.provider_client<realm::app::App::UsernamePasswordProviderClient>().
    confirm_user(token.UTF8String, tokenId.UTF8String, ^(Optional<realm::app::AppError> error) {
        if (error && error->error_code) {
            return completionHandler(AppErrorToNSError(*error));
        }
        completionHandler(nil);
    });
}

- (void)resendConfirmationEmail:(NSString *)email
              completionHandler:(RLMOptionalErrorBlock)completionHandler {
    self.app._realmApp.provider_client<realm::app::App::UsernamePasswordProviderClient>().
    resend_confirmation_email(email.UTF8String, ^(Optional<realm::app::AppError> error) {
        if (error && error->error_code) {
            return completionHandler(AppErrorToNSError(*error));
        }
        completionHandler(nil);
    });
}

- (void)sendResetPasswordEmail:(NSString *)email
             completionHandler:(RLMOptionalErrorBlock)completionHandler {
    self.app._realmApp.provider_client<realm::app::App::UsernamePasswordProviderClient>().
    send_reset_password_email(email.UTF8String, ^(Optional<realm::app::AppError> error) {
        if (error && error->error_code) {
            return completionHandler(AppErrorToNSError(*error));
        }
        completionHandler(nil);
    });
}

- (void)resetPassword:(NSString *)password
                token:(NSString *)token
              tokenId:(NSString *)tokenId
    completionHandler:(RLMOptionalErrorBlock)completionHandler {
    self.app._realmApp.provider_client<realm::app::App::UsernamePasswordProviderClient>().
    reset_password(password.UTF8String, token.UTF8String, tokenId.UTF8String, ^(Optional<realm::app::AppError> error) {
        if (error && error->error_code) {
            return completionHandler(AppErrorToNSError(*error));
        }
        completionHandler(nil);
    });
}

- (void)callResetPasswordFunction:(NSString *)email
                         password:(NSString *)password
                             args:(NSString *)args
                completionHandler:(RLMOptionalErrorBlock)completionHandler {
    
    if (!args.length) {
        args = @"{}";
    }
    self.app._realmApp.provider_client<realm::app::App::UsernamePasswordProviderClient>().
    call_reset_password_function(email.UTF8String, password.UTF8String, args.UTF8String, ^(Optional<realm::app::AppError> error) {
        if (error && error->error_code) {
            return completionHandler(AppErrorToNSError(*error));
        }
        completionHandler(nil);
    });
}

@end

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

#import "RLMEmailPasswordAuth.h"

#import "RLMApp_Private.hpp"
#import "RLMBSON_Private.hpp"
#import "RLMProviderClient_Private.hpp"

#import <realm/object-store/sync/app.hpp>

@implementation RLMEmailPasswordAuth

- (realm::app::App::UsernamePasswordProviderClient)client {
    return self.app._realmApp->provider_client<realm::app::App::UsernamePasswordProviderClient>();
}

- (void)registerUserWithEmail:(NSString *)email
                     password:(NSString *)password
                   completion:(RLMEmailPasswordAuthOptionalErrorBlock)completion {
    self.client.register_email(email.UTF8String, password.UTF8String, RLMWrapCompletion(completion));
}

- (void)confirmUser:(NSString *)token
            tokenId:(NSString *)tokenId
         completion:(RLMEmailPasswordAuthOptionalErrorBlock)completion {
    self.client.confirm_user(token.UTF8String, tokenId.UTF8String, RLMWrapCompletion(completion));
}

- (void)retryCustomConfirmation:(NSString *)email
                     completion:(RLMEmailPasswordAuthOptionalErrorBlock)completion {
    self.client.retry_custom_confirmation(email.UTF8String, RLMWrapCompletion(completion));
}

- (void)resendConfirmationEmail:(NSString *)email
                     completion:(RLMEmailPasswordAuthOptionalErrorBlock)completion {
    self.client.resend_confirmation_email(email.UTF8String, RLMWrapCompletion(completion));
}

- (void)sendResetPasswordEmail:(NSString *)email
                    completion:(RLMEmailPasswordAuthOptionalErrorBlock)completion {
    self.client.send_reset_password_email(email.UTF8String, RLMWrapCompletion(completion));
}

- (void)resetPasswordTo:(NSString *)password
                  token:(NSString *)token
                tokenId:(NSString *)tokenId
             completion:(RLMEmailPasswordAuthOptionalErrorBlock)completion {
    self.client.reset_password(password.UTF8String, token.UTF8String, tokenId.UTF8String,
                               RLMWrapCompletion(completion));
}

- (void)callResetPasswordFunction:(NSString *)email
                         password:(NSString *)password
                             args:(NSArray<id<RLMBSON>> *)args
                       completion:(RLMEmailPasswordAuthOptionalErrorBlock)completion {
    self.client.call_reset_password_function(email.UTF8String,
                                             password.UTF8String,
                                             static_cast<realm::bson::BsonArray>(RLMConvertRLMBSONToBson(args)),
                                             RLMWrapCompletion(completion));
}

@end

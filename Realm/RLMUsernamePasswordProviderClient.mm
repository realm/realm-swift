//
//  RLMUsernamePasswordProviderClient.m
//  Realm
//
//  Created by Lee Maguire on 24/03/2020.
//  Copyright © 2020 Realm. All rights reserved.
//

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
              tokenId:(NSString *)password
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
                            token:(NSString *)password
                          tokenId:(NSString *)args
                completionHandler:(RLMOptionalErrorBlock)completionHandler {
    self.app._realmApp.provider_client<realm::app::App::UsernamePasswordProviderClient>().
    call_reset_password_function(email.UTF8String, password.UTF8String, args.UTF8String, ^(Optional<realm::app::AppError> error) {
        if (error && error->error_code) {
            return completionHandler(AppErrorToNSError(*error));
        }
        completionHandler(nil);
    });
}

@end

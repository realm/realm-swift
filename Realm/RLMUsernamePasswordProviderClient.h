//
//  RLMUsernamePasswordProviderClient.h
//  Realm
//
//  Created by Lee Maguire on 24/03/2020.
//  Copyright © 2020 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RLMProviderClient.h"

NS_ASSUME_NONNULL_BEGIN

/**
  A client for the username/password authentication provider which
  can be used to obtain a credential for logging in,
  and to perform requests specifically related to the username/password provider.
*/
@interface RLMUsernamePasswordProviderClient : RLMProviderClient

/// A block type used to report an error
typedef void(^RLMOptionalErrorBlock)(NSError * _Nullable);

/**
 Registers a new email identity with the username/password provider,
 and sends a confirmation email to the provided address.

 @param email The email address of the user to register.
 @param password The password that the user created for the new username/password identity.
 @param completionHandler A callback to be invoked once the call is complete.
*/

- (void)registerEmail:(NSString *)email
              tokenId:(NSString *)password
    completionHandler:(RLMOptionalErrorBlock)completionHandler;

/**
 Confirms an email identity with the username/password provider.

 @param token The confirmation token that was emailed to the user.
 @param tokenId The confirmation token id that was emailed to the user.
 @param completionHandler A callback to be invoked once the call is complete.
*/
- (void)confirmUser:(NSString *)token
            tokenId:(NSString *)tokenId
  completionHandler:(RLMOptionalErrorBlock)completionHandler;

/**
 Re-sends a confirmation email to a user that has registered but
 not yet confirmed their email address.

 @param email The email address of the user to re-send a confirmation for.
 @param completionHandler A callback to be invoked once the call is complete.
*/
- (void)resendConfirmationEmail:(NSString *)email
              completionHandler:(RLMOptionalErrorBlock)completionHandler;

/**
 Sends a password reset email to the given email address.

 @param email The email address of the user to send a password reset email for.
 @param completionHandler A callback to be invoked once the call is complete.
*/
- (void)sendResetPasswordEmail:(NSString *)email
             completionHandler:(RLMOptionalErrorBlock)completionHandler;

/**
 Resets the password of an email identity using the
 password reset token emailed to a user.

 @param password The desired new password.
 @param token The password reset token that was emailed to the user.
 @param tokenId The password reset token id that was emailed to the user.
 @param completionHandler A callback to be invoked once the call is complete.
*/
- (void)resetPassword:(NSString *)password
                token:(NSString *)token
              tokenId:(NSString *)tokenId
    completionHandler:(RLMOptionalErrorBlock)completionHandler;

/**
 Resets the password of an email identity using the
 password reset function set up in the application.
 
 TODO: Add an overloaded version of this method that takes
 TODO: raw, non-serialized args.
 
 @param email  The email address of the user.
 @param password The desired new password.
 @param args A pre-serialized list of arguments. Must be a JSON array.
 @param completionHandler A callback to be invoked once the call is complete.
*/
- (void)callResetPasswordFunction:(NSString *)email
                            token:(NSString *)password
                          tokenId:(NSString *)args
                completionHandler:(RLMOptionalErrorBlock)completionHandler;

@end

NS_ASSUME_NONNULL_END


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

#import "LabelViewController.h"

#import <Realm/Realm.h>
#import <Security/Security.h>

// Model definition
@interface StringObject : RLMObject
@property NSString *stringProp;
@end

@implementation StringObject
// Nothing needed
@end

@interface LabelViewController ()
@property (nonatomic, strong) UITextView *textView;
@end

@implementation LabelViewController
// Create a view to display output in
- (void)loadView {
    CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
    UIView *contentView = [[UIView alloc] initWithFrame:applicationFrame];
    contentView.backgroundColor = [UIColor whiteColor];
    self.view = contentView;

    self.textView = [[UITextView alloc] initWithFrame:applicationFrame];
    [self.view addSubview:self.textView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Use an autorelease pool to close the Realm at the end of the block, so
    // that we can try to reopen it with different keys
    @autoreleasepool {
        RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
        configuration.encryptionKey = [self getKey];
        RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration
                                                     error:nil];

        // Add an object
        [realm beginWriteTransaction];
        StringObject *obj = [[StringObject alloc] init];
        obj.stringProp = @"abcd";
        [realm addObject:obj];
        [realm commitWriteTransaction];
    }

    // Opening with wrong key fails since it decrypts to the wrong thing
    @autoreleasepool {
        uint8_t buffer[64];
        SecRandomCopyBytes(kSecRandomDefault, 64, buffer);

        NSError *error;
        RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
        configuration.encryptionKey = [[NSData alloc] initWithBytes:buffer length:sizeof(buffer)];
        [RLMRealm realmWithConfiguration:configuration
                                   error:&error];
        [self log:@"Open with wrong key: %@", error];
    }

    // Opening wihout supplying a key at all fails
    @autoreleasepool {
        NSError *error;
        [RLMRealm realmWithConfiguration:[RLMRealmConfiguration defaultConfiguration] error:&error];
        [self log:@"Open with no key: %@", error];
    }

    // Reopening with the correct key works and can read the data
    @autoreleasepool {
        RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
        configuration.encryptionKey = [self getKey];
        RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration
                                                     error:nil];

        [self log:@"Saved object: %@", [[[StringObject allObjectsInRealm:realm] firstObject] stringProp]];
    }
}

// Log a message to the screen since we can't just use NSLog() with no debugger attached
- (void)log:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    self.textView.text = [[self.textView.text
                           stringByAppendingString:str]
                           stringByAppendingString:@"\n\n"];
}

- (NSData *)getKey {
    // Identifier for our keychain entry - should be unique for your application
    static const uint8_t kKeychainIdentifier[] = "io.Realm.EncryptionExampleKey";
    NSData *tag = [[NSData alloc] initWithBytesNoCopy:(void *)kKeychainIdentifier
                                               length:sizeof(kKeychainIdentifier)
                                         freeWhenDone:NO];

    // First check in the keychain for an existing key
    NSDictionary *query = @{(__bridge id)kSecClass: (__bridge id)kSecClassKey,
                            (__bridge id)kSecAttrApplicationTag: tag,
                            (__bridge id)kSecAttrKeySizeInBits: @512,
                            (__bridge id)kSecReturnData: @YES};

    CFTypeRef dataRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataRef);
    if (status == errSecSuccess) {
        return (__bridge NSData *)dataRef;
    }

    // No pre-existing key from this application, so generate a new one
    uint8_t buffer[64];
    SecRandomCopyBytes(kSecRandomDefault, 64, buffer);
    NSData *keyData = [[NSData alloc] initWithBytes:buffer length:sizeof(buffer)];

    // Store the key in the keychain
    query = @{(__bridge id)kSecClass: (__bridge id)kSecClassKey,
              (__bridge id)kSecAttrApplicationTag: tag,
              (__bridge id)kSecAttrKeySizeInBits: @512,
              (__bridge id)kSecValueData: keyData};

    status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    NSAssert(status == errSecSuccess, @"Failed to insert new key in the keychain");

    return keyData;
}
@end

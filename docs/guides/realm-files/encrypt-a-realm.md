# Encrypt a Realm - Swift SDK
## Overview
You can encrypt the realm file on disk with AES-256 +
SHA-2 by supplying a 64-byte encryption key when opening a
realm.

Realm transparently encrypts and decrypts data with standard
[AES-256 encryption](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) using the
first 256 bits of the given 512-bit encryption key. Realm
uses the other 256 bits of the 512-bit encryption key to validate
integrity using a [hash-based message authentication code
(HMAC)](https://en.wikipedia.org/wiki/HMAC).

> Warning:
> Do not use cryptographically-weak hashes for realm encryption keys.
For optimal security, we recommend generating random rather than derived
encryption keys.
>

> Note:
> You must encrypt a realm the first time you open it.
If you try to open an existing unencrypted realm using a configuration
that contains an encryption key, Realm throws an error.
>

## Considerations
The following are key impacts to consider when encrypting a realm.

### Storing & Reusing Keys
You **must** pass the same encryption key every time you open the encrypted realm.
If you don't provide a key or specify the wrong key for an encrypted
realm, the Realm SDK throws an error.

Apps should store the encryption key in the Keychain so that other apps
cannot read the key.

### Performance Impact
Reads and writes on encrypted realms can be up to 10% slower than unencrypted realms.

### Accessing an Encrypted Realm from Multiple Processes
> Version changed: 10.38.0

Starting with Realm Swift SDK version 10.38.0, Realm supports opening
the same encrypted realm in multiple processes.

If your app uses Realm Swift SDK version 10.37.2 or earlier, attempting to
open an encrypted realm from multiple processes throws this error:
`Encrypted interprocess sharing is currently unsupported.`

Apps using earlier SDK versions have two options to work with realms in
multiple processes:

- Use an unencrypted realm.
- Store data that you want to encrypt as `NSData` properties on realm
objects. Then, you can encrypt and decrypt individual fields.

One possible tool to encrypt and decrypt fields is [Apple's
CryptoKit framework](https://developer.apple.com/documentation/cryptokit). You can use [Swift
Crypto](https://github.com/apple/swift-crypto) to simplify app
development with CryptoKit.

## Example
The following code demonstrates how to generate an encryption key and
open an encrypted realm:

#### Objective-C

```objectivec
// Generate a random encryption key
NSMutableData *key = [NSMutableData dataWithLength:64];
(void)SecRandomCopyBytes(kSecRandomDefault, key.length, (uint8_t *)key.mutableBytes);

// Open the encrypted Realm file
RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
config.encryptionKey = key;

NSError *error = nil;
RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
if (!realm) {
    // If the encryption key is wrong, `error` will say that it's an invalid database
    NSLog(@"Error opening realm: %@", error);
} else {
    // Use the realm as normal...
}

```

#### Swift

```swift
// Generate a random encryption key
var key = Data(count: 64)
_ = key.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) in
    SecRandomCopyBytes(kSecRandomDefault, 64, pointer.baseAddress!) }

// Configure for an encrypted realm
var config = Realm.Configuration(encryptionKey: key)

do {
    // Open the encrypted realm
    let realm = try Realm(configuration: config)
    // ... use the realm as normal ...
} catch let error as NSError {
    // If the encryption key is wrong, `error` will say that it's an invalid database
    fatalError("Error opening realm: \(error.localizedDescription)")
}

```

The following Swift example demonstrates how to store and retrieve a
generated key from the Keychain:

```swift
// Retrieve the existing encryption key for the app if it exists or create a new one
func getKey() -> Data {
    // Identifier for our keychain entry - should be unique for your application
    let keychainIdentifier = "io.Realm.EncryptionExampleKey"
    let keychainIdentifierData = keychainIdentifier.data(using: String.Encoding.utf8, allowLossyConversion: false)!

    // First check in the keychain for an existing key
    var query: [NSString: AnyObject] = [
        kSecClass: kSecClassKey,
        kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
        kSecAttrKeySizeInBits: 512 as AnyObject,
        kSecReturnData: true as AnyObject
    ]

    // To avoid Swift optimization bug, should use withUnsafeMutablePointer() function to retrieve the keychain item
    // See also: http://stackoverflow.com/questions/24145838/querying-ios-keychain-using-swift/27721328#27721328
    var dataTypeRef: AnyObject?
    var status = withUnsafeMutablePointer(to: &dataTypeRef) { SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0)) }
    if status == errSecSuccess {
        // swiftlint:disable:next force_cast
        return dataTypeRef as! Data
    }

    // No pre-existing key from this application, so generate a new one
    // Generate a random encryption key
    var key = Data(count: 64)
    key.withUnsafeMutableBytes({ (pointer: UnsafeMutableRawBufferPointer) in
        let result = SecRandomCopyBytes(kSecRandomDefault, 64, pointer.baseAddress!)
        assert(result == 0, "Failed to get random bytes")
    })

    // Store the key in the keychain
    query = [
        kSecClass: kSecClassKey,
        kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
        kSecAttrKeySizeInBits: 512 as AnyObject,
        kSecValueData: key as AnyObject
    ]

    status = SecItemAdd(query as CFDictionary, nil)
    assert(status == errSecSuccess, "Failed to insert the new key in the keychain")

    return key
}

// ...
// Use the getKey() function to get the stored encryption key or create a new one
var config = Realm.Configuration(encryptionKey: getKey())

do {
    // Open the realm with the configuration
    let realm = try Realm(configuration: config)

    // Use the realm as normal

} catch let error as NSError {
    // If the encryption key is wrong, `error` will say that it's an invalid database
    fatalError("Error opening realm: \(error)")
}

```

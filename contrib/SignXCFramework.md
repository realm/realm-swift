## Signing the XCFramework

By Apple's requirements, we should sign our release
  binaries so Xcode can validate it was signed by the same developer on every new version. 

Follow these steps to update the signing certificate in case of change or after the current used certificate has been revoke.

1. Create an Apple Distribution or Apple Development certificate from XCode's Settings/Accounts menu or from Apple's developer portal.
2. Export the given certificate with a distintic password, edit github's secret variable `P12_PASSWORD` with the new password. https://help.apple.com/xcode/mac/current/#/dev154b28f09
3. Generate a Base64 string from the exported certificate using
   ```
   base64 -i BUILD_CERTIFICATE.p12 | pbcopy
   ```
4. Edit github's secret variable `DEVELOPMENT_CERTIFICATE_BASE64` with the copied value.
5. Edit the current github's secret variable `SIGNING_IDENTITY` to the new identity associated to the exported certificate.


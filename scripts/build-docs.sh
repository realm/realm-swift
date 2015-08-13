#!/bin/sh
jazzy="$(which jazzy)"
PATH=/usr/local/bin:/usr/bin:/bin:/usr/libexec

if [ -z "${SRCROOT}" ]; then
    SRCROOT="$(pwd)"
fi

realm_version_file="${SRCROOT}/Realm/Realm-Info.plist"
realm_version="$(PlistBuddy -c "Print :CFBundleVersion" "$realm_version_file")"

appledoc \
    --project-name Realm \
    --project-company "Realm" \
    --output "${SRCROOT}/docs" \
    -v ${realm_version} \
    --create-html \
    --no-create-docset \
    --no-repeat-first-par \
    --no-warn-missing-arg \
    --no-warn-invalid-crossref \
    --no-warn-undocumented-object \
    --no-warn-undocumented-member \
    --ignore "Realm/RLMRealm_Dynamic.h" \
    --ignore "Realm/RLMArrayAccessor.h" \
    --ignore "Realm/RLMArrayAccessor.mm" \
    --ignore "Realm/RLMQueryUtil.h" \
    --ignore "Realm/RLMUtil.h" \
    --ignore "Realm/RLMRealm_Dynamic.h" \
    --ignore "Realm/Realm-Bridging-Header.h" \
    --ignore "Realm/Tests" \
    --template "${SRCROOT}/docs/templates/objc" \
    --exit-threshold 1 \
    Realm

mkdir -p ${SRCROOT}/docs/output
rm -rf ${SRCROOT}/docs/output/${realm_version}
mv ${SRCROOT}/docs/html ${SRCROOT}/docs/output/${realm_version}

${jazzy} \
  --author Realm \
  --author_url "https://realm.io" \
  --clean \
  --github_url https://github.com/realm/realm-cocoa \
  --github-file-prefix https://github.com/realm/realm-cocoa/tree/v${realm_version} \
  --module RealmSwift \
  --module-version ${realm_version} \
  --output "${SRCROOT}/docs/swift_output" \
  --root-url https://realm.io/docs/swift/${realm_version}/api/ \
  --xcodebuild-arguments "-project,${SRCROOT}/Realm.xcodeproj,-scheme,RealmSwift,-dry-run" \
  --template-directory "${SRCROOT}/docs/templates/swift" \

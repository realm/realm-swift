#!/bin/sh
PATH=/usr/local/bin:/usr/bin:/bin:/usr/libexec

if [ -z "${SRCROOT}" ]; then
    SRCROOT="$(pwd)"
fi

realm_version_file="${SRCROOT}/Realm/Realm-Info.plist"
realm_version="$(PlistBuddy -c "Print :CFBundleVersion" "$realm_version_file")"

appledoc \
    --project-name Realm \
    --project-company "Realm" \
    --output ${SRCROOT}/docs \
    -v ${realm_version} \
    --create-html \
    --no-create-docset \
    --no-repeat-first-par \
    --no-warn-missing-arg \
    --no-warn-invalid-crossref \
    --no-warn-undocumented-object \
    --no-warn-undocumented-member \
    --ignore "Realm/RLMArrayAccessor.h" \
    --ignore "Realm/RLMArrayAccessor.mm" \
    --ignore "Realm/RLMProperty.h" \
    --ignore "Realm/RLMProperty.m" \
    --ignore "Realm/RLMObjectSchema.h" \
    --ignore "Realm/RLMSchema.h" \
    --ignore "Realm/RLMQueryUtil.h" \
    --ignore "Realm/RLMUtil.h" \
    --ignore "Realm/Tests/QueryTests.m" \
    --ignore "Realm/Tests/TransactionTests.m" \
    --ignore "Realm/Tests/ObjectTests.m" \
    --template ${SRCROOT}/docs/templates \
    --exit-threshold 1 \
    Realm

sed -i '' -e '/RLMPropertyType/d' ${SRCROOT}/docs/html/index.html
sed -i '' -e '/RLMPropertyType/d' ${SRCROOT}/docs/html/hierarchy.html

mkdir -p ${SRCROOT}/docs/output
rm -rf ${SRCROOT}/docs/output/${realm_version}
mv ${SRCROOT}/docs/html ${SRCROOT}/docs/output/${realm_version}

appledoc \
    --project-name Realm \
    --project-company "Realm" \
    --output ${SRCROOT}/docs/output/${realm_version}/ \
    -v "${realm_version}" \
    --no-create-html \
    --create-docset \
    --publish-docset \
    --docset-feed-url "http://realm.io/docs/ios/${realm_version}/api/realm.atom" \
    --docset-package-url "http://realm.io/docs/ios/${realm_version}/api/realm" \
    --docset-package-filename "realm" \
    --docset-atom-filename "realm.atom" \
    --docset-bundle-filename "realm.docset" \
    --company-id "io.realm" \
    --no-repeat-first-par \
    --no-warn-missing-arg \
    --no-warn-invalid-crossref \
    --no-warn-undocumented-object \
    --no-warn-undocumented-member \
    --ignore "Realm/RLMArrayAccessor.h" \
    --ignore "Realm/RLMArrayAccessor.mm" \
    --ignore "Realm/RLMProperty.h" \
    --ignore "Realm/RLMProperty.m" \
    --ignore "Realm/RLMObjectSchema.h" \
    --ignore "Realm/RLMSchema.h" \
    --ignore "Realm/RLMQueryUtil.h" \
    --ignore "Realm/RLMUtil.h" \
    --ignore "Realm/Tests/QueryTests.m" \
    --ignore "Realm/Tests/TransactionTests.m" \
    --ignore "Realm/Tests/ObjectTests.m" \
    --template ${SRCROOT}/docs/templates \
    --exit-threshold 1 \
    Realm

# Compress the docset
(
    cd ${SRCROOT}/docs/output/${realm_version}/
    tar --exclude='.DS_Store' -cvzf realm-docset.tgz realm.docset || exit 1
    rm -rf realm.docset || exit 1
)

cat >${SRCROOT}/docs/output/${realm_version}/realm.xml <<EOF
<entry>
    <version>${realm_version}</version>
    <sha1>$(shasum -b docs/output/${realm_version}/realm-docset.tgz | cut -c 1-40)</sha1>
    <url>http://static.realm.io/docs/ios/${realm_version}/api/realm-docset.tgz</url>
</entry>
EOF

mv ${SRCROOT}/docs/output/${realm_version}/publish/* ${SRCROOT}/docs/output/${realm_version}/
rm -rf ${SRCROOT}/docs/output/${realm_version}/publish/

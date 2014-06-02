realm_version_file="${SRCROOT}/Realm/Realm-Info.plist"
realm_version="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$realm_version_file")"

appledoc    --project-name Realm \
    --project-company "Realm" \
    --include docs/source/realm.png \
    --output docs \
    -v `sh build.sh get-version` \
    --create-html \
    --no-create-docset \
    --no-repeat-first-par \
    --no-warn-missing-arg \
    --no-warn-invalid-crossref \
    --no-warn-undocumented-object \
    --no-warn-undocumented-member \
    --ignore "Realm/RLMConstants.h" \
    --ignore "Realm/RLMArrayAccessor.h" \
    --ignore "Realm/RLMArrayAccessor.mm" \
    --ignore "Realm/RLMProperty.h" \
    --ignore "Realm/RLMProperty.m" \
    --ignore "Realm/RLMObjectSchema.h" \
    --ignore "Realm/RLMSchema.h" \
    --ignore "Realm/RLMQueryUtil.h" \
    --ignore "Realm/RLMUtil.h" \
    --ignore "Realm/Tests/QueryTests.m" \
    --ignore "Realm/Tests/*" \
    --index-desc docs/source/index.md \
    --template docs/templates \
    --exit-threshold 1 \
    Realm

mkdir -p ${SRCROOT}/docs/output
rm -rf ${SRCROOT}/docs/output/$(sh build.sh get-version)
mv ${SRCROOT}/docs/html ${SRCROOT}/docs/output/$(sh build.sh get-version)

appledoc    --project-name Realm \
    --project-company "Realm" \
    --include ${SRCROOT}/docs/source/realm.png \
    --output ${SRCROOT}/docs/output/$(sh build.sh get-version)/ \
    -v "${realm_version}" \
    --no-create-html \
    --create-docset \
    --publish-docset \
    --docset-feed-url "http://realm.io/docs/ios/$(sh build.sh get-version)/realm.atom" \
    --docset-package-url "http://realm.io/docs/ios/$(sh build.sh get-version)/realm" \
    --docset-package-filename "realm" \
    --docset-atom-filename "realm.atom" \
    --docset-bundle-filename "realm.docset" \
    --company-id "io.realm" \
    --no-repeat-first-par \
    --no-warn-missing-arg \
    --no-warn-invalid-crossref \
    --no-warn-undocumented-object \
    --no-warn-undocumented-member \
    --ignore "Realm/RLMConstants.h" \
    --ignore "Realm/RLMArrayAccessor.h" \
    --ignore "Realm/RLMArrayAccessor.mm" \
    --ignore "Realm/RLMProperty.h" \
    --ignore "Realm/RLMProperty.m" \
    --ignore "Realm/RLMObjectSchema.h" \
    --ignore "Realm/RLMSchema.h" \
    --ignore "Realm/RLMQueryUtil.h" \
    --ignore "Realm/RLMUtil.h" \
    --ignore "Realm/Tests/QueryTests.m" \
    --ignore "Realm/Tests/*" \
    --index-desc ${SRCROOT}/docs/source/index.md \
    --template ${SRCROOT}/docs/templates \
    --exit-threshold 1 \
    Realm

(
    cd ${SRCROOT}/docs/output/${realm_version}/
    tar --exclude='.DS_Store' -cvzf realm.tgz realm.docset
    )
cat >${SRCROOT}/docs/output/$(sh build.sh get-version)/realm.xml <<EOF
<entry>
    <version>${realm_version}</version>
    <sha1>$(sha1sum -b docs/output/${realm_version}/realm.tgz | cut -c 1-40)</sha1>
    <url>http://static.realm.io/docs/ios/${realm_version}/realm.tgz</url>
</entry>
EOF

mv ${SRCROOT}/docs/output/${realm_version}/publish/* ${SRCROOT}/docs/output/${realm_version}/
rm -rf ${SRCROOT}/docs/output/${realm_version}/publish/
rm -rf ${SRCROOT}/docs/output/${realm_version}/realm.docset



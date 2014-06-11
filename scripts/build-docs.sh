realm_version_file="Realm/Realm-Info.plist"
realm_version="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$realm_version_file")"

appledoc \
    --project-name Realm \
    --project-company "Realm" \
    --output docs \
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
    --template docs/templates \
    --exit-threshold 1 \
    Realm

sed -i '' -e '/RLMPropertyType/d' docs/html/index.html
sed -i '' -e '/RLMSortOrder/d' docs/html/index.html
sed -i '' -e '/RLMPropertyType/d' docs/html/hierarchy.html
sed -i '' -e '/RLMSortOrder/d' docs/html/hierarchy.html

mkdir -p docs/output
rm -rf docs/output/${realm_version}
mv docs/html docs/output/${realm_version}

appledoc \
    --project-name Realm \
    --project-company "Realm" \
    --output docs/output/${realm_version}/ \
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
    --template docs/templates \
    --exit-threshold 1 \
    Realm

( cd docs/output/${realm_version}/ && tar --exclude='.DS_Store' -cvzf realm.tgz realm.docset )
cat >docs/output/${realm_version}/realm.xml <<EOF
<entry>
    <version>${realm_version}</version>
    <sha1>$(shasum -b docs/output/${realm_version}/realm.tgz | cut -c 1-40)</sha1>
    <url>http://static.realm.io/docs/ios/${realm_version}/api/realm.tgz</url>
</entry>
EOF

mv docs/output/${realm_version}/publish/* docs/output/${realm_version}/
rm -rf docs/output/${realm_version}/publish/

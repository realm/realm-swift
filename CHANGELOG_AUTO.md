# Change Log

## [Unreleased](https://github.com/realm/realm-cocoa/tree/HEAD)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.92.3...HEAD)

**Closed issues:**

- Realm update with multi thread [\#1951](https://github.com/realm/realm-cocoa/issues/1951)

- Public source dynamic API [\#1950](https://github.com/realm/realm-cocoa/issues/1950)

- Realm v0.92.3 Bug: RLMException in RLMCheckThread Function [\#1947](https://github.com/realm/realm-cocoa/issues/1947)

- Cannot open encrypted realm with debugger attached after updating to 0.92.3 [\#1946](https://github.com/realm/realm-cocoa/issues/1946)

**Merged pull requests:**

- \[Browser\] Sort classes alphabetically [\#1963](https://github.com/realm/realm-cocoa/pull/1963) ([segiddins](https://github.com/segiddins))

- typo [\#1929](https://github.com/realm/realm-cocoa/pull/1929) ([ShingoFukuyama](https://github.com/ShingoFukuyama))

## [v0.92.3](https://github.com/realm/realm-cocoa/tree/v0.92.3) (2015-05-13)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.92.2...v0.92.3)

**Implemented enhancements:**

- \[RealmSwift\] List missing `invalidated` property [\#1919](https://github.com/realm/realm-cocoa/issues/1919)

**Fixed bugs:**

- http://static.realm.io/downloads/cocoa/latest links to older version [\#1931](https://github.com/realm/realm-cocoa/issues/1931)

- Iterating over List<T\> where T has a property of type List<\> crashes [\#1906](https://github.com/realm/realm-cocoa/issues/1906)

- Realm comparison operators yield incorrect RLMResults [\#1905](https://github.com/realm/realm-cocoa/issues/1905)

- Different return for min, max, sum, average in RealmSwift [\#1902](https://github.com/realm/realm-cocoa/issues/1902)

- Query in swift throws exception [\#1901](https://github.com/realm/realm-cocoa/issues/1901)

- Query with 'OR' condition doesn't always work in relationship [\#1863](https://github.com/realm/realm-cocoa/issues/1863)

**Closed issues:**

- Error in Realm version check? [\#1932](https://github.com/realm/realm-cocoa/issues/1932)

- \[RealmSwift\] Errors in Swift-\>ObjC Generated Header for Realm Objects with List<\> Properties [\#1925](https://github.com/realm/realm-cocoa/issues/1925)

- How to use a model object in working threads situation \(read only\) [\#1922](https://github.com/realm/realm-cocoa/issues/1922)

- Mutiple realms/threads with RLMObject subclass instance methods writing to its own realm [\#1915](https://github.com/realm/realm-cocoa/issues/1915)

- Crash on filtering Results [\#1909](https://github.com/realm/realm-cocoa/issues/1909)

- Subscripting `Results` with a range [\#1904](https://github.com/realm/realm-cocoa/issues/1904)

- Database upgrade from 0.91.3 to 0.92.2 results in corrupted database [\#1903](https://github.com/realm/realm-cocoa/issues/1903)

- Using Carthage -- Realm.framework depends on RealmSwift.framework?? [\#1900](https://github.com/realm/realm-cocoa/issues/1900)

- Swift Bash script fails when Target's app filename contains a space [\#1899](https://github.com/realm/realm-cocoa/issues/1899)

- Application crashed due to error Assertion failed: size\_t\(m\_top.get\(2\) / 2\)<=m\_alloc.get\_baseline\(\) [\#1895](https://github.com/realm/realm-cocoa/issues/1895)

- containsString: unrecognized selector sent to iOS 7 [\#1894](https://github.com/realm/realm-cocoa/issues/1894)

- Question about a line: [\#1892](https://github.com/realm/realm-cocoa/issues/1892)

- RealmSwift - Invalid Dash or Xcode docset feed [\#1890](https://github.com/realm/realm-cocoa/issues/1890)

- ANY  \(bb.id1 = '1' AND bb.id2 = '2'\)  error [\#1889](https://github.com/realm/realm-cocoa/issues/1889)

- RLMAccessor.h and RLMArray\_Private.hpp not found \(RealmSwift\) [\#1879](https://github.com/realm/realm-cocoa/issues/1879)

- Realm sometimes crashes when writing if device is locked. [\#1874](https://github.com/realm/realm-cocoa/issues/1874)

- 'RLMArray\_Private.hpp' file not found in CocoaPods Install RealmSwift [\#1859](https://github.com/realm/realm-cocoa/issues/1859)

**Merged pull requests:**

- \[RLMUpdateChecker\] Link to changelog at the newest versions tag [\#1934](https://github.com/realm/realm-cocoa/pull/1934) ([segiddins](https://github.com/segiddins))

- Update to core 0.89.3 [\#1933](https://github.com/realm/realm-cocoa/pull/1933) ([tgoyne](https://github.com/tgoyne))

- Revert "Add a helper type alias for \_\_unsafe\_unretained" [\#1927](https://github.com/realm/realm-cocoa/pull/1927) ([tgoyne](https://github.com/tgoyne))

- \[List\] Add invalidated property [\#1920](https://github.com/realm/realm-cocoa/pull/1920) ([segiddins](https://github.com/segiddins))

- Fix enumerating through standalone lists whose objects have list prop… [\#1912](https://github.com/realm/realm-cocoa/pull/1912) ([segiddins](https://github.com/segiddins))

- Update the type check used for aggregate operators to work correctly … [\#1911](https://github.com/realm/realm-cocoa/pull/1911) ([bdash](https://github.com/bdash))

- \[Results\] Return nil for average\(\_:\) when count == 0 [\#1908](https://github.com/realm/realm-cocoa/pull/1908) ([segiddins](https://github.com/segiddins))

- Use rangeOfString: instead containsString: [\#1896](https://github.com/realm/realm-cocoa/pull/1896) ([kishikawakatsumi](https://github.com/kishikawakatsumi))

- \[Docs\] Use the correct doc URL. Fixes \#1890. [\#1891](https://github.com/realm/realm-cocoa/pull/1891) ([jpsim](https://github.com/jpsim))

- New browser icon [\#1869](https://github.com/realm/realm-cocoa/pull/1869) ([mrh-is](https://github.com/mrh-is))

## [v0.92.2](https://github.com/realm/realm-cocoa/tree/v0.92.2) (2015-05-08)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.92.1...v0.92.2)

**Implemented enhancements:**

- Improve error message try to sort on multi-level keypaths [\#1861](https://github.com/realm/realm-cocoa/issues/1861)

- Using duplicate property definitions in models should throw a more descriptive exception message [\#1844](https://github.com/realm/realm-cocoa/issues/1844)

- Better crash logging caused by invalid fields [\#1827](https://github.com/realm/realm-cocoa/issues/1827)

- Build and run through all possible installation methods on CI [\#1395](https://github.com/realm/realm-cocoa/issues/1395)

- Support object reuse/linking by primary key in createOrUpdate methods - remove RLMValidatedDictionary and RLMValidatedArray [\#1362](https://github.com/realm/realm-cocoa/issues/1362)

- Tables should be removable during migration when removing an object type [\#1177](https://github.com/realm/realm-cocoa/issues/1177)

**Fixed bugs:**

- List accessors aren't properly initialized in Swift fast enumeration [\#1876](https://github.com/realm/realm-cocoa/issues/1876)

- LLDB hangs when debugging an application that is using an encrypted Realm. [\#1625](https://github.com/realm/realm-cocoa/issues/1625)

**Closed issues:**

- error Error itms-90035 [\#1887](https://github.com/realm/realm-cocoa/issues/1887)

- "Could not build Objc module" using RealmSwift with Swift-only source [\#1884](https://github.com/realm/realm-cocoa/issues/1884)

- Swift: List is missing reduce and map [\#1883](https://github.com/realm/realm-cocoa/issues/1883)

- Unable to build using RealmSwift 0.92.1 cocoapod [\#1881](https://github.com/realm/realm-cocoa/issues/1881)

- Accessing to-many relationship throws exception in Swift 0.92.1 [\#1880](https://github.com/realm/realm-cocoa/issues/1880)

- Incorrect conversion from Realm core string representation to NSString [\#1877](https://github.com/realm/realm-cocoa/issues/1877)

- in -Swift.h ,"Type name requires a specifier or qualifier" [\#1873](https://github.com/realm/realm-cocoa/issues/1873)

- Error installing RealmSwift with Cocoapods 0.37.1 [\#1870](https://github.com/realm/realm-cocoa/issues/1870)

- Unable to submit to AppStore due to strip-frameworks.sh signature [\#1865](https://github.com/realm/realm-cocoa/issues/1865)

- 'RLMResults' does not have a member named 'generate' [\#1862](https://github.com/realm/realm-cocoa/issues/1862)

- Deal with multiple users [\#1857](https://github.com/realm/realm-cocoa/issues/1857)

- dyld: Library not loaded [\#1850](https://github.com/realm/realm-cocoa/issues/1850)

- RLMRealm fails in XCTests [\#1839](https://github.com/realm/realm-cocoa/issues/1839)

**Merged pull requests:**

- \[ObjectSchemaInitialization\] Allow declaring swift list properties as… [\#1888](https://github.com/realm/realm-cocoa/pull/1888) ([segiddins](https://github.com/segiddins))

- \[RLMCollection\] Ensure swift list accessors are initialized [\#1882](https://github.com/realm/realm-cocoa/pull/1882) ([segiddins](https://github.com/segiddins))

- Improve the exception messages when sorting on an invalid column name [\#1872](https://github.com/realm/realm-cocoa/pull/1872) ([bdash](https://github.com/bdash))

- Improve the exception messages when a property name used in a predicate is not found [\#1871](https://github.com/realm/realm-cocoa/pull/1871) ([bdash](https://github.com/bdash))

- \[Tests\] Make it possible and easy to test exception messages [\#1868](https://github.com/realm/realm-cocoa/pull/1868) ([segiddins](https://github.com/segiddins))

- Have +\[RLMObjectSchema schemaForObjectClass:\] throw an exception when… [\#1867](https://github.com/realm/realm-cocoa/pull/1867) ([bdash](https://github.com/bdash))

- \[Scripts\] Make strip-frameworks.sh not executable [\#1866](https://github.com/realm/realm-cocoa/pull/1866) ([segiddins](https://github.com/segiddins))

- When a type error is rasied, include information about the problemati… [\#1856](https://github.com/realm/realm-cocoa/pull/1856) ([bdash](https://github.com/bdash))

- \[RLMObjectStore\] Allow properly updating linked objects with primary keys [\#1833](https://github.com/realm/realm-cocoa/pull/1833) ([segiddins](https://github.com/segiddins))

- \[RLMObjectStore\] Delete tables that are no longer relevant during a migration. [\#1399](https://github.com/realm/realm-cocoa/pull/1399) ([segiddins](https://github.com/segiddins))

## [v0.92.1](https://github.com/realm/realm-cocoa/tree/v0.92.1) (2015-05-06)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.92.0...v0.92.1)

**Implemented enhancements:**

- Support Carthage prebuilt framework [\#1595](https://github.com/realm/realm-cocoa/issues/1595)

- Make inWriteTransaction public [\#1541](https://github.com/realm/realm-cocoa/issues/1541)

- Support object equality in ANY queries [\#1424](https://github.com/realm/realm-cocoa/issues/1424)

**Closed issues:**

- RealmSwift installation instructions cause Signed Resource modified error [\#1854](https://github.com/realm/realm-cocoa/issues/1854)

- http://realm.io/docs/swift/latest/ the manual setup is missing Copy Files phase [\#1848](https://github.com/realm/realm-cocoa/issues/1848)

- Multiple deleteObject calls within a transaction remove only half of the objects \(0.92.0 and earlier\) [\#1846](https://github.com/realm/realm-cocoa/issues/1846)

- make the push\_cocoapods Jenkins job work on any CI machine [\#1263](https://github.com/realm/realm-cocoa/issues/1263)

**Merged pull requests:**

- \[strip-frameworks.sh\] Force code re-signing after stripping architect… [\#1855](https://github.com/realm/realm-cocoa/pull/1855) ([segiddins](https://github.com/segiddins))

- Disable debugging encrypted realms [\#1853](https://github.com/realm/realm-cocoa/pull/1853) ([bdash](https://github.com/bdash))

- Avoid force unwrapping in the Swift examples [\#1852](https://github.com/realm/realm-cocoa/pull/1852) ([jpsim](https://github.com/jpsim))

- Generate unique object IDs for objects in the RealmSwift Xcode project. [\#1851](https://github.com/realm/realm-cocoa/pull/1851) ([bdash](https://github.com/bdash))

- \[Swift\] import Foundation to make jazzy generate the proper USRs [\#1842](https://github.com/realm/realm-cocoa/pull/1842) ([jpsim](https://github.com/jpsim))

- \[Podspec\] update podspec for 0.92.0 [\#1840](https://github.com/realm/realm-cocoa/pull/1840) ([jpsim](https://github.com/jpsim))

- \[RLMRealm\] Make inWriteTransaction public [\#1832](https://github.com/realm/realm-cocoa/pull/1832) ([segiddins](https://github.com/segiddins))

- RealmSwift.podspec [\#1774](https://github.com/realm/realm-cocoa/pull/1774) ([mrackwitz](https://github.com/mrackwitz))

## [v0.92.0](https://github.com/realm/realm-cocoa/tree/v0.92.0) (2015-05-05)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.91.5...v0.92.0)

**Implemented enhancements:**

- Support specifying objectSchema/classes to be stored in a Realm [\#1506](https://github.com/realm/realm-cocoa/issues/1506)

- Support key-path sorting [\#1199](https://github.com/realm/realm-cocoa/issues/1199)

- New API to support wrapping NSDocument [\#1066](https://github.com/realm/realm-cocoa/issues/1066)

- Expose framework version number [\#1057](https://github.com/realm/realm-cocoa/issues/1057)

- Map keys based on provided dictionary [\#1012](https://github.com/realm/realm-cocoa/issues/1012)

- Missing limit and offset feature [\#947](https://github.com/realm/realm-cocoa/issues/947)

**Fixed bugs:**

- Upgrading from 0.91.1 -\> 0.91.2 generates a lot of crashes [\#1797](https://github.com/realm/realm-cocoa/issues/1797)

- Crashing in \[RLMMigration verifyPrimaryKeyUniqueness\] [\#1620](https://github.com/realm/realm-cocoa/issues/1620)

- RLMArray accessors should be of type RLMObject when using the dynamic interface [\#1331](https://github.com/realm/realm-cocoa/issues/1331)

- Sign Realm Browser.app [\#1202](https://github.com/realm/realm-cocoa/issues/1202)

- Querying fails with TRUEPREDICATE [\#1153](https://github.com/realm/realm-cocoa/issues/1153)

- Realm should not use excessive space when writing data [\#1034](https://github.com/realm/realm-cocoa/issues/1034)

**Closed issues:**

- All query on array \(any workarounds?\)  [\#1835](https://github.com/realm/realm-cocoa/issues/1835)

- Fix Cobertura reports for all members [\#1831](https://github.com/realm/realm-cocoa/issues/1831)

- Disable Automatic Version Checking [\#1825](https://github.com/realm/realm-cocoa/issues/1825)

- How to get \[realm createOrUpdate\] change set? [\#1824](https://github.com/realm/realm-cocoa/issues/1824)

- FR: BOOL property on RLMRealm for inWriteTransaction [\#1817](https://github.com/realm/realm-cocoa/issues/1817)

- Test issue, please disregard [\#1815](https://github.com/realm/realm-cocoa/issues/1815)

- Query subclasses from parent class? [\#1814](https://github.com/realm/realm-cocoa/issues/1814)

- How to call init\(forPrimaryKey:\) in Swift [\#1813](https://github.com/realm/realm-cocoa/issues/1813)

- Freeze if you save nil property in not main thread [\#1812](https://github.com/realm/realm-cocoa/issues/1812)

- createOrUpdate on partial objects causes nested objects to reset [\#1806](https://github.com/realm/realm-cocoa/issues/1806)

- add validation of input parameters to \[realm deleteObject: [\#1799](https://github.com/realm/realm-cocoa/issues/1799)

- How to use defaultPropertyValues while using response data from server ? [\#1768](https://github.com/realm/realm-cocoa/issues/1768)

- Not sure what is happening with beginWriteTransaction inside of didFinishSpeechUtterance [\#1766](https://github.com/realm/realm-cocoa/issues/1766)

- Uncaught exception because NSNumber sent unrecognised selector [\#1759](https://github.com/realm/realm-cocoa/issues/1759)

- Add string to addNotificationBlock method. [\#1756](https://github.com/realm/realm-cocoa/issues/1756)

- Allow error handling when realm is accessed with the wrong encryption key [\#1750](https://github.com/realm/realm-cocoa/issues/1750)

- Encrypted Realm crashes when opening [\#1746](https://github.com/realm/realm-cocoa/issues/1746)

- EXC\_BAD\_ACCESS crash when using NSOutlineView [\#1734](https://github.com/realm/realm-cocoa/issues/1734)

- RLMArray init memory leak [\#1714](https://github.com/realm/realm-cocoa/issues/1714)

- Rename initWithObject/createWithObject to withValue [\#1585](https://github.com/realm/realm-cocoa/issues/1585)

- Latest stable release of realm \(0.90.5\) crashes on release version of app [\#1503](https://github.com/realm/realm-cocoa/issues/1503)

- Support custom RLMObject initializers in Swift [\#1101](https://github.com/realm/realm-cocoa/issues/1101)

- Use of camelCased properties importing from JSON [\#1063](https://github.com/realm/realm-cocoa/issues/1063)

**Merged pull requests:**

- Handle constant predicates, and AND predicates with no subpredicates [\#1834](https://github.com/realm/realm-cocoa/pull/1834) ([bdash](https://github.com/bdash))

- Add a helper type alias for \_\_unsafe\_unretained [\#1829](https://github.com/realm/realm-cocoa/pull/1829) ([tgoyne](https://github.com/tgoyne))

- Package Realm Swift [\#1826](https://github.com/realm/realm-cocoa/pull/1826) ([jpsim](https://github.com/jpsim))

- Test that, in migrations, arrays yield DynamicObjects [\#1816](https://github.com/realm/realm-cocoa/pull/1816) ([segiddins](https://github.com/segiddins))

- Change withObject: to withValue: [\#1811](https://github.com/realm/realm-cocoa/pull/1811) ([segiddins](https://github.com/segiddins))

- Eliminate some redundant work during migrations [\#1802](https://github.com/realm/realm-cocoa/pull/1802) ([tgoyne](https://github.com/tgoyne))

## [v0.91.5](https://github.com/realm/realm-cocoa/tree/v0.91.5) (2015-04-28)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.91.4...v0.91.5)

**Closed issues:**

- RLMIsObjectValidForProperty returning NO for a valid object [\#1804](https://github.com/realm/realm-cocoa/issues/1804)

- Compile error with Realm Core Null v1 BETA [\#1801](https://github.com/realm/realm-cocoa/issues/1801)

**Merged pull requests:**

- Update to core 0.89.1 [\#1807](https://github.com/realm/realm-cocoa/pull/1807) ([tgoyne](https://github.com/tgoyne))

## [v0.91.4](https://github.com/realm/realm-cocoa/tree/v0.91.4) (2015-04-27)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.91.3...v0.91.4)

**Implemented enhancements:**

- Support sorting standalone RLMArrays [\#1794](https://github.com/realm/realm-cocoa/issues/1794)

- Swift: Create Int property when Int8 is used in a Swift model [\#1329](https://github.com/realm/realm-cocoa/issues/1329)

**Fixed bugs:**

- row accessors can be deallocated on the incorrect thread [\#1684](https://github.com/realm/realm-cocoa/issues/1684)

- Fix templates installation [\#1366](https://github.com/realm/realm-cocoa/issues/1366)

**Closed issues:**

- RLMResults sortedArrayUsingComparator behavior [\#1796](https://github.com/realm/realm-cocoa/issues/1796)

- Testing whether a RLMArray contains a value using indexOf [\#1795](https://github.com/realm/realm-cocoa/issues/1795)

- Subclassing does not work [\#1787](https://github.com/realm/realm-cocoa/issues/1787)

- Don't make a table for RLMDynamicObject / DynamicObject / MigrationObject [\#1783](https://github.com/realm/realm-cocoa/issues/1783)

- + \[RLMRealm resetRealmState\] is not available? [\#1781](https://github.com/realm/realm-cocoa/issues/1781)

- Seg fault when accepting an array of a generic type [\#1780](https://github.com/realm/realm-cocoa/issues/1780)

- New version log notification  [\#1777](https://github.com/realm/realm-cocoa/issues/1777)

- Cannot use RLMArray with custom protocols [\#1773](https://github.com/realm/realm-cocoa/issues/1773)

- Cannot access elements of RLMResults [\#1764](https://github.com/realm/realm-cocoa/issues/1764)

- Make an enum for accessor codes [\#1763](https://github.com/realm/realm-cocoa/issues/1763)

- Error installing Realm with CocoaPods [\#1683](https://github.com/realm/realm-cocoa/issues/1683)

- Swift support for Cocoapods 0.36 [\#1279](https://github.com/realm/realm-cocoa/issues/1279)

**Merged pull requests:**

- Remove unused REALM\_SWIFT compiler flag [\#1791](https://github.com/realm/realm-cocoa/pull/1791) ([jpsim](https://github.com/jpsim))

- use full logo URL in README [\#1789](https://github.com/realm/realm-cocoa/pull/1789) ([jpsim](https://github.com/jpsim))

- Ignore dynamic objects from the sharedSchema [\#1788](https://github.com/realm/realm-cocoa/pull/1788) ([segiddins](https://github.com/segiddins))

- \[XcodePlugIn\] Update UUIDs and only install file templates [\#1786](https://github.com/realm/realm-cocoa/pull/1786) ([jpsim](https://github.com/jpsim))

- Updated readme to be similar to contact page [\#1785](https://github.com/realm/realm-cocoa/pull/1785) ([yoshyosh](https://github.com/yoshyosh))

- \[Docs\] re-enable jazzy in build-docs.sh because it now supports Swift 1.2 [\#1784](https://github.com/realm/realm-cocoa/pull/1784) ([jpsim](https://github.com/jpsim))

- Generate test coverage files for Realm.xcodeproj [\#1782](https://github.com/realm/realm-cocoa/pull/1782) ([jpsim](https://github.com/jpsim))

- Added `-\[RLMRealm compact\]` [\#1778](https://github.com/realm/realm-cocoa/pull/1778) ([jpsim](https://github.com/jpsim))

- Add missing `RLMArray\#replaceObjectAtIndex:withObject` for standalone array [\#1776](https://github.com/realm/realm-cocoa/pull/1776) ([kishikawakatsumi](https://github.com/kishikawakatsumi))

- Add missing `RLMRealm\#addOrUpdateObjectsFromArray:` test [\#1775](https://github.com/realm/realm-cocoa/pull/1775) ([kishikawakatsumi](https://github.com/kishikawakatsumi))

- Package dynamic iOS framework [\#1772](https://github.com/realm/realm-cocoa/pull/1772) ([jpsim](https://github.com/jpsim))

- \[RealmSwift\] Swift 1.2 Compatability [\#1753](https://github.com/realm/realm-cocoa/pull/1753) ([segiddins](https://github.com/segiddins))

- Allow Int8 object properties defined in Swift [\#1740](https://github.com/realm/realm-cocoa/pull/1740) ([segiddins](https://github.com/segiddins))

- Don't call migration blocks when first initializing a Realm file [\#1739](https://github.com/realm/realm-cocoa/pull/1739) ([tgoyne](https://github.com/tgoyne))

- \[ObjectBase\] Throw an exception when an attached accessor is deallocated... [\#1727](https://github.com/realm/realm-cocoa/pull/1727) ([segiddins](https://github.com/segiddins))

- Properly support KVC during migrations [\#1713](https://github.com/realm/realm-cocoa/pull/1713) ([segiddins](https://github.com/segiddins))

## [v0.91.3](https://github.com/realm/realm-cocoa/tree/v0.91.3) (2015-04-17)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.91.2...v0.91.3)

**Fixed bugs:**

- Indexing is broken [\#1735](https://github.com/realm/realm-cocoa/issues/1735)

**Closed issues:**

- Extra argument 'objectClassName' in call [\#1765](https://github.com/realm/realm-cocoa/issues/1765)

- Idea: makeObjectsPerformSelector: [\#1760](https://github.com/realm/realm-cocoa/issues/1760)

**Merged pull requests:**

- Restore initWithObjectClassName to the public headers [\#1767](https://github.com/realm/realm-cocoa/pull/1767) ([tgoyne](https://github.com/tgoyne))

## [v0.91.2](https://github.com/realm/realm-cocoa/tree/v0.91.2) (2015-04-17)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.91.1...v0.91.2)

**Implemented enhancements:**

- Reference cycle in one of the examples [\#1658](https://github.com/realm/realm-cocoa/issues/1658)

- Use new nullable and nonnull annotations in public interface [\#1618](https://github.com/realm/realm-cocoa/issues/1618)

- New Swift APIs [\#1238](https://github.com/realm/realm-cocoa/issues/1238)

- Support setValue:forKey: and valueForKey: on RLMCollection [\#1172](https://github.com/realm/realm-cocoa/issues/1172)

**Fixed bugs:**

- Browser crashes opening uninitialized Realm [\#1752](https://github.com/realm/realm-cocoa/issues/1752)

- isEqualToObject: between RLMObject that has persisted and non-RLMObject object causes a crash [\#1605](https://github.com/realm/realm-cocoa/issues/1605)

- Swift: Nested JSON Objects [\#1386](https://github.com/realm/realm-cocoa/issues/1386)

- Fix Realm-dynamic-simulator [\#1327](https://github.com/realm/realm-cocoa/issues/1327)

- RLMArray and RLMResults count property should be Int [\#1219](https://github.com/realm/realm-cocoa/issues/1219)

**Closed issues:**

- Why memory usage is growing, increasing from 17M to 40M. [\#1749](https://github.com/realm/realm-cocoa/issues/1749)

- Realm not persisting changes made to RLMObjects from RLMResults [\#1748](https://github.com/realm/realm-cocoa/issues/1748)

- Realm treats my NSString field as an int [\#1745](https://github.com/realm/realm-cocoa/issues/1745)

- Parsing improvements [\#1742](https://github.com/realm/realm-cocoa/issues/1742)

- Is there a better way for relational queries ? [\#1741](https://github.com/realm/realm-cocoa/issues/1741)

- Question about in memory Realm  [\#1738](https://github.com/realm/realm-cocoa/issues/1738)

- \(IOS\) Still no Relation Query? [\#1736](https://github.com/realm/realm-cocoa/issues/1736)

- deleteObject doesn't work  [\#1732](https://github.com/realm/realm-cocoa/issues/1732)

- Compiling problem [\#1731](https://github.com/realm/realm-cocoa/issues/1731)

- Issues with ObjectMapper [\#1726](https://github.com/realm/realm-cocoa/issues/1726)

- Add subclassed object to RLMArray property [\#1718](https://github.com/realm/realm-cocoa/issues/1718)

- RLMObject.objectsWhere is returning non-optional RLMResults [\#1698](https://github.com/realm/realm-cocoa/issues/1698)

- Dealing with exceptions in Realm [\#1697](https://github.com/realm/realm-cocoa/issues/1697)

- Indexing for non-string fields [\#1691](https://github.com/realm/realm-cocoa/issues/1691)

- How to construct the query for this case?  [\#1685](https://github.com/realm/realm-cocoa/issues/1685)

- Realm Swift API [\#1682](https://github.com/realm/realm-cocoa/issues/1682)

- Default property value not working for NSData [\#1678](https://github.com/realm/realm-cocoa/issues/1678)

- Realm internal state gets corrupted when trying to add NSNull into the database [\#1677](https://github.com/realm/realm-cocoa/issues/1677)

- Update Carthage, it's using an outdated version of core [\#1664](https://github.com/realm/realm-cocoa/issues/1664)

- Realm crashes on addOrUpdateObject, but only in some environments [\#1663](https://github.com/realm/realm-cocoa/issues/1663)

- Assertion failed: \_impl::TableFriend::is\_link\_type\(ColumnType\(type\)\) [\#1662](https://github.com/realm/realm-cocoa/issues/1662)

- Associated object via json not saving? [\#1654](https://github.com/realm/realm-cocoa/issues/1654)

- Loss of information when objects are retrieved from a realm [\#1653](https://github.com/realm/realm-cocoa/issues/1653)

- Allow filter when pushing a dictionary into createOrUpdateInRealm [\#1641](https://github.com/realm/realm-cocoa/issues/1641)

- Is objectsWhere no longer available? [\#1636](https://github.com/realm/realm-cocoa/issues/1636)

- \[Doc\] RLMObject.init\(forPrimaryKey:String\) is not in the documentation [\#1635](https://github.com/realm/realm-cocoa/issues/1635)

- 'Realm accessed from incorrect thread' error in prepareForSegue; Swift [\#1634](https://github.com/realm/realm-cocoa/issues/1634)

- Unable to query database using double precision [\#1633](https://github.com/realm/realm-cocoa/issues/1633)

- transactionWithBlock: never ends  [\#1621](https://github.com/realm/realm-cocoa/issues/1621)

- RLMException when calling callback closure [\#1609](https://github.com/realm/realm-cocoa/issues/1609)

- App crashes on read when using writeCopyToPath: to compact encrypted realm [\#1589](https://github.com/realm/realm-cocoa/issues/1589)

- App crash when deleteObjects [\#1564](https://github.com/realm/realm-cocoa/issues/1564)

- Assertion failed: backlink\_ndx != not\_found [\#1553](https://github.com/realm/realm-cocoa/issues/1553)

- -\[RLMArray insertOrUpdateObject:atIndex:\] [\#1521](https://github.com/realm/realm-cocoa/issues/1521)

- 'Version of Realm file on disk is higher than current schema version' [\#1474](https://github.com/realm/realm-cocoa/issues/1474)

- Update release process to zip repo [\#1404](https://github.com/realm/realm-cocoa/issues/1404)

- Updating with nested dictionary breaks RLMArray and RLMObject connections [\#1401](https://github.com/realm/realm-cocoa/issues/1401)

- Support in RLMArray for basic types \(int, strings, etc\) [\#1312](https://github.com/realm/realm-cocoa/issues/1312)

**Merged pull requests:**

- Add and remove indexes from existing columns during migrations [\#1755](https://github.com/realm/realm-cocoa/pull/1755) ([tgoyne](https://github.com/tgoyne))

- \[RLMRealm\] Return an error when attempting to open a read-only uninitial... [\#1754](https://github.com/realm/realm-cocoa/pull/1754) ([segiddins](https://github.com/segiddins))

- Update to core 0.90.0 [\#1751](https://github.com/realm/realm-cocoa/pull/1751) ([tgoyne](https://github.com/tgoyne))

- Omit .self suffix on types where not needed [\#1743](https://github.com/realm/realm-cocoa/pull/1743) ([mrackwitz](https://github.com/mrackwitz))

- Fix failing `test-package-release` command on case sensitive filesystem [\#1729](https://github.com/realm/realm-cocoa/pull/1729) ([kishikawakatsumi](https://github.com/kishikawakatsumi))

- \[List\] Implement description with max depth [\#1721](https://github.com/realm/realm-cocoa/pull/1721) ([segiddins](https://github.com/segiddins))

- \[List\]\[Results\] Use NSFastGenerator for generate\(\) [\#1720](https://github.com/realm/realm-cocoa/pull/1720) ([segiddins](https://github.com/segiddins))

- Wrap the measured blocks for perf tests in autorelease pools [\#1719](https://github.com/realm/realm-cocoa/pull/1719) ([tgoyne](https://github.com/tgoyne))

- Swiftify descriptions for RealmSwift types [\#1717](https://github.com/realm/realm-cocoa/pull/1717) ([segiddins](https://github.com/segiddins))

- Clean up watch extension example project [\#1716](https://github.com/realm/realm-cocoa/pull/1716) ([kishikawakatsumi](https://github.com/kishikawakatsumi))

- Add tests for RLMArray delete methods [\#1715](https://github.com/realm/realm-cocoa/pull/1715) ([kishikawakatsumi](https://github.com/kishikawakatsumi))

- \[ObjectCreationTests\] Add a case for testing create with NSNull links an... [\#1712](https://github.com/realm/realm-cocoa/pull/1712) ([segiddins](https://github.com/segiddins))

- Avoid using private implementation details in the Swift tests [\#1711](https://github.com/realm/realm-cocoa/pull/1711) ([tgoyne](https://github.com/tgoyne))

- \[Realm\] Allow copy when calling Realm.create\(\) [\#1710](https://github.com/realm/realm-cocoa/pull/1710) ([segiddins](https://github.com/segiddins))

- Fix typos in doc comments [\#1700](https://github.com/realm/realm-cocoa/pull/1700) ([mrackwitz](https://github.com/mrackwitz))

- Forcibly deallocate leaked RLMRealms in Swift tests [\#1694](https://github.com/realm/realm-cocoa/pull/1694) ([tgoyne](https://github.com/tgoyne))

- Fix cannot retrieve keychain item in release build. [\#1687](https://github.com/realm/realm-cocoa/pull/1687) ([kishikawakatsumi](https://github.com/kishikawakatsumi))

- Invoke test methods correctly [\#1680](https://github.com/realm/realm-cocoa/pull/1680) ([tgoyne](https://github.com/tgoyne))

- Update changelog for \#1676 [\#1679](https://github.com/realm/realm-cocoa/pull/1679) ([jpsim](https://github.com/jpsim))

- Allow Realm to be used within an app extension [\#1676](https://github.com/realm/realm-cocoa/pull/1676) ([pizthewiz](https://github.com/pizthewiz))

- \[RealmSwift\] hide unfortunately public declarations that should be private [\#1675](https://github.com/realm/realm-cocoa/pull/1675) ([jpsim](https://github.com/jpsim))

- Test subscripting [\#1674](https://github.com/realm/realm-cocoa/pull/1674) ([alazier](https://github.com/alazier))

- \[build.sh\] Run jazzy to generate RealmSwift docs [\#1673](https://github.com/realm/realm-cocoa/pull/1673) ([segiddins](https://github.com/segiddins))

- Re-add check for objects of wrong type in indexOfObject [\#1668](https://github.com/realm/realm-cocoa/pull/1668) ([alazier](https://github.com/alazier))

- pr fixes [\#1667](https://github.com/realm/realm-cocoa/pull/1667) ([jpsim](https://github.com/jpsim))

- Swift PR Fixes [\#1665](https://github.com/realm/realm-cocoa/pull/1665) ([segiddins](https://github.com/segiddins))

- \[RealmExamples\] remove reference cycle in examples [\#1660](https://github.com/realm/realm-cocoa/pull/1660) ([jpsim](https://github.com/jpsim))

- make MigrationObjects optional [\#1657](https://github.com/realm/realm-cocoa/pull/1657) ([alazier](https://github.com/alazier))

- \[Realm\] Test that when cancelling inside a write block, the count of obj... [\#1651](https://github.com/realm/realm-cocoa/pull/1651) ([segiddins](https://github.com/segiddins))

- \[List\] Test that doing unsupported things with standalone lists throws a... [\#1650](https://github.com/realm/realm-cocoa/pull/1650) ([segiddins](https://github.com/segiddins))

- move over old tests, test float/double [\#1648](https://github.com/realm/realm-cocoa/pull/1648) ([alazier](https://github.com/alazier))

- List.remove -\> List.removeAtIndex to be consistent with Swift.Array [\#1647](https://github.com/realm/realm-cocoa/pull/1647) ([alazier](https://github.com/alazier))

- \[RLMUtil\] Restore default value merging for Swift subclasses of RLMObject [\#1646](https://github.com/realm/realm-cocoa/pull/1646) ([segiddins](https://github.com/segiddins))

- Update packaging scripts for new Swift APIs [\#1645](https://github.com/realm/realm-cocoa/pull/1645) ([jpsim](https://github.com/jpsim))

- Make Object, ObjectSchema, Property, and Schema conform to Printable [\#1644](https://github.com/realm/realm-cocoa/pull/1644) ([segiddins](https://github.com/segiddins))

- \[PropertyTests\] Revert unintentional changes [\#1642](https://github.com/realm/realm-cocoa/pull/1642) ([segiddins](https://github.com/segiddins))

- Micro typo in the word receive in 2 places [\#1640](https://github.com/realm/realm-cocoa/pull/1640) ([natanrolnik](https://github.com/natanrolnik))

- New Swift apis [\#1639](https://github.com/realm/realm-cocoa/pull/1639) ([alazier](https://github.com/alazier))

- remove MigrationObject and other swift dependencies from objc code [\#1637](https://github.com/realm/realm-cocoa/pull/1637) ([alazier](https://github.com/alazier))

- change install name after building [\#1632](https://github.com/realm/realm-cocoa/pull/1632) ([alazier](https://github.com/alazier))

- Move subscripting out of RLMObjectBase [\#1631](https://github.com/realm/realm-cocoa/pull/1631) ([segiddins](https://github.com/segiddins))

- Change Object.init\(object:\) to Object.init\(value:\) [\#1630](https://github.com/realm/realm-cocoa/pull/1630) ([alazier](https://github.com/alazier))

- Updated documentation to reflect recently renamed method name. [\#1626](https://github.com/realm/realm-cocoa/pull/1626) ([TimOliver](https://github.com/TimOliver))

- \[Browser\] Display seconds for dates [\#1622](https://github.com/realm/realm-cocoa/pull/1622) ([jpsim](https://github.com/jpsim))

- Set up RealmSwift device tests [\#1619](https://github.com/realm/realm-cocoa/pull/1619) ([segiddins](https://github.com/segiddins))

- re-add old swift api examples [\#1617](https://github.com/realm/realm-cocoa/pull/1617) ([alazier](https://github.com/alazier))

- object creation tests [\#1616](https://github.com/realm/realm-cocoa/pull/1616) ([segiddins](https://github.com/segiddins))

- Make RLMObjectBase methods private [\#1606](https://github.com/realm/realm-cocoa/pull/1606) ([alazier](https://github.com/alazier))

- \[RLMObjectSchema\] +dynamicSchemaForRealm: now respects search indexes [\#1590](https://github.com/realm/realm-cocoa/pull/1590) ([jpsim](https://github.com/jpsim))

- \[RLMCollection\] Implement custom KVC support [\#1536](https://github.com/realm/realm-cocoa/pull/1536) ([segiddins](https://github.com/segiddins))

## [v0.91.1](https://github.com/realm/realm-cocoa/tree/v0.91.1) (2015-03-12)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.91.0...v0.91.1)

**Implemented enhancements:**

- Realm Browser auto-refresh [\#1169](https://github.com/realm/realm-cocoa/issues/1169)

**Closed issues:**

- Allow for non default, non optional properties in Swift [\#1615](https://github.com/realm/realm-cocoa/issues/1615)

- Allow for optionals in Swift [\#1614](https://github.com/realm/realm-cocoa/issues/1614)

- Equivalent “completion handler” from MagicalRecord to Realm.io [\#1610](https://github.com/realm/realm-cocoa/issues/1610)

- Crashes with Realm 0.91.0 [\#1608](https://github.com/realm/realm-cocoa/issues/1608)

- Get swift device tests working [\#1607](https://github.com/realm/realm-cocoa/issues/1607)

- Consider making setDefaultRealmPath\(\) persist across app launches [\#1599](https://github.com/realm/realm-cocoa/issues/1599)

- Swift documentation for ordering result is incorrect [\#1596](https://github.com/realm/realm-cocoa/issues/1596)

**Merged pull requests:**

- Fix a crash in CFRunLoopSourceInvalidate [\#1612](https://github.com/realm/realm-cocoa/pull/1612) ([tgoyne](https://github.com/tgoyne))

- Fixes for swift ci [\#1598](https://github.com/realm/realm-cocoa/pull/1598) ([alazier](https://github.com/alazier))

- \[RealmBrowser\] Reload after external commits have been made [\#1592](https://github.com/realm/realm-cocoa/pull/1592) ([segiddins](https://github.com/segiddins))

## [v0.91.0](https://github.com/realm/realm-cocoa/tree/v0.91.0) (2015-03-10)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.90.6...v0.91.0)

**Implemented enhancements:**

- transaction exception message when removing object from realm [\#1579](https://github.com/realm/realm-cocoa/issues/1579)

- Add isInvalidated to RLMArray [\#1492](https://github.com/realm/realm-cocoa/issues/1492)

**Fixed bugs:**

- Throw an exception when declaring a nested RLMObject subclass in Swift [\#1577](https://github.com/realm/realm-cocoa/issues/1577)

- isEqual: between Realm object and non-Realm object causes a crash [\#1547](https://github.com/realm/realm-cocoa/issues/1547)

- Creating an object property of type RLMObject should throw [\#1465](https://github.com/realm/realm-cocoa/issues/1465)

- RLMResults contains doubled objects [\#1443](https://github.com/realm/realm-cocoa/issues/1443)

- Interprocess: Support accessing realms from multiple processes [\#824](https://github.com/realm/realm-cocoa/issues/824)

**Closed issues:**

- Result of sort is different from the standard way of Cocoa. [\#1578](https://github.com/realm/realm-cocoa/issues/1578)

- Add createOrUpdateFromArray method to RLMObject [\#1574](https://github.com/realm/realm-cocoa/issues/1574)

- Upsert function? [\#1573](https://github.com/realm/realm-cocoa/issues/1573)

- RLMRealm init\(path:\) fails with defaultRealmPath\(\) [\#1568](https://github.com/realm/realm-cocoa/issues/1568)

- Encrypted interprocess sharing is currently unsupported [\#1567](https://github.com/realm/realm-cocoa/issues/1567)

- deleteObjects does not delete objects when when giving NSArray to \[realm deleteObjects:\] [\#1566](https://github.com/realm/realm-cocoa/issues/1566)

- App and WatckKit App Extension share objects [\#1565](https://github.com/realm/realm-cocoa/issues/1565)

- Iteration skips one item [\#1561](https://github.com/realm/realm-cocoa/issues/1561)

- Minimum OS X system requirements? [\#1557](https://github.com/realm/realm-cocoa/issues/1557)

- Crash while accessing RLMObject in iOS Location Multitasking Mode [\#1552](https://github.com/realm/realm-cocoa/issues/1552)

- Change +attributesForProperty: to indexedProperties [\#1549](https://github.com/realm/realm-cocoa/issues/1549)

- Add removeObjects to RLMArray [\#1543](https://github.com/realm/realm-cocoa/issues/1543)

- Bump version of .Info-Plist to 0.90.6 [\#1542](https://github.com/realm/realm-cocoa/issues/1542)

- Schema Development [\#1540](https://github.com/realm/realm-cocoa/issues/1540)

- Pod integration with the tests target [\#1538](https://github.com/realm/realm-cocoa/issues/1538)

- What has changed in v0.90.6? [\#1535](https://github.com/realm/realm-cocoa/issues/1535)

- Test encryption apis [\#1533](https://github.com/realm/realm-cocoa/issues/1533)

- Migration on parent object changes - assert error [\#1528](https://github.com/realm/realm-cocoa/issues/1528)

- Realm Relationship Returning Empty Results [\#1525](https://github.com/realm/realm-cocoa/issues/1525)

- Undefined symbols for architecture x86\_64 [\#1517](https://github.com/realm/realm-cocoa/issues/1517)

- App crashes on launch with encrypted Realm [\#1516](https://github.com/realm/realm-cocoa/issues/1516)

- Impossible to pass a RLMObject without a primary key between threads. [\#1512](https://github.com/realm/realm-cocoa/issues/1512)

- Descriptions for RLMSchema, RLMObjectSchema, RLMProperty [\#1500](https://github.com/realm/realm-cocoa/issues/1500)

- Realm sometimes crashes when first accessing it [\#1472](https://github.com/realm/realm-cocoa/issues/1472)

- Default value property is not working [\#1421](https://github.com/realm/realm-cocoa/issues/1421)

- Support copying a realm into an in-memory realm [\#1418](https://github.com/realm/realm-cocoa/issues/1418)

- Sporadic results in XCTest [\#1350](https://github.com/realm/realm-cocoa/issues/1350)

**Merged pull requests:**

- \[build.sh\] Silence the output from running the JSONImport output [\#1588](https://github.com/realm/realm-cocoa/pull/1588) ([segiddins](https://github.com/segiddins))

- \[RLMArray\] Fix insertObject:atIndex: test [\#1586](https://github.com/realm/realm-cocoa/pull/1586) ([segiddins](https://github.com/segiddins))

- Update to core 0.88.5 [\#1583](https://github.com/realm/realm-cocoa/pull/1583) ([tgoyne](https://github.com/tgoyne))

- \[Swift\] Throw when RLMObject subclass is nested in \*any\* Swift declaration [\#1581](https://github.com/realm/realm-cocoa/pull/1581) ([jpsim](https://github.com/jpsim))

- Remove unused variable [\#1576](https://github.com/realm/realm-cocoa/pull/1576) ([tgoyne](https://github.com/tgoyne))

- Fix some small test issues [\#1575](https://github.com/realm/realm-cocoa/pull/1575) ([tgoyne](https://github.com/tgoyne))

- \[RLMArray\] Test deleting an RLMArray member updates count and maintains appropriate validation [\#1570](https://github.com/realm/realm-cocoa/pull/1570) ([jpsim](https://github.com/jpsim))

- \[RLMArray\] Add `isInvalidated` to RLMArray. [\#1569](https://github.com/realm/realm-cocoa/pull/1569) ([jpsim](https://github.com/jpsim))

- Add some tests for encryption stuff [\#1562](https://github.com/realm/realm-cocoa/pull/1562) ([tgoyne](https://github.com/tgoyne))

- Fix unsafe uses of \_\_unsafe\_unretained [\#1559](https://github.com/realm/realm-cocoa/pull/1559) ([tgoyne](https://github.com/tgoyne))

- Set the deployment targets to OS X 10.9 / iOS 7.0 for the Project, while... [\#1558](https://github.com/realm/realm-cocoa/pull/1558) ([danielpovlsen](https://github.com/danielpovlsen))

- Fix race conditions in tests [\#1556](https://github.com/realm/realm-cocoa/pull/1556) ([tgoyne](https://github.com/tgoyne))

- Fix small typos [\#1555](https://github.com/realm/realm-cocoa/pull/1555) ([pietbrauer](https://github.com/pietbrauer))

- Set iOS deployment target to 7.0 for the Project; while Targets inherit [\#1554](https://github.com/realm/realm-cocoa/pull/1554) ([danielpovlsen](https://github.com/danielpovlsen))

- Parallelize the pull request test running [\#1551](https://github.com/realm/realm-cocoa/pull/1551) ([tgoyne](https://github.com/tgoyne))

- \[RLMObjectBase\] Don't crash when calling isEqual: against a non-RLMObject... [\#1548](https://github.com/realm/realm-cocoa/pull/1548) ([segiddins](https://github.com/segiddins))

- clean up kvc support for lists [\#1546](https://github.com/realm/realm-cocoa/pull/1546) ([alazier](https://github.com/alazier))

- \[Info.plist\] Update version number to 0.90.6 [\#1544](https://github.com/realm/realm-cocoa/pull/1544) ([segiddins](https://github.com/segiddins))

- Swiftify object customization methods [\#1539](https://github.com/realm/realm-cocoa/pull/1539) ([alazier](https://github.com/alazier))

- Update core version [\#1534](https://github.com/realm/realm-cocoa/pull/1534) ([tgoyne](https://github.com/tgoyne))

- Use a named pipe for interprocess notifications [\#1531](https://github.com/realm/realm-cocoa/pull/1531) ([tgoyne](https://github.com/tgoyne))

- \[RLMObjectBase\] Prefix realm and objectSchema properties [\#1523](https://github.com/realm/realm-cocoa/pull/1523) ([segiddins](https://github.com/segiddins))

- \[RLMProperty\] Disallow creating a property of type RLMObject [\#1515](https://github.com/realm/realm-cocoa/pull/1515) ([segiddins](https://github.com/segiddins))

- Add more useful descriptions for RLMObjectSchema, RLMSchema, and RLMProp... [\#1502](https://github.com/realm/realm-cocoa/pull/1502) ([segiddins](https://github.com/segiddins))

- Add support for interprocess change notifications [\#1381](https://github.com/realm/realm-cocoa/pull/1381) ([tgoyne](https://github.com/tgoyne))

## [v0.90.6](https://github.com/realm/realm-cocoa/tree/v0.90.6) (2015-02-20)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.90.5...v0.90.6)

**Implemented enhancements:**

- Exception message for out of date Realm version should include version numbers and path [\#1475](https://github.com/realm/realm-cocoa/issues/1475)

- Truncate description for NSData properties [\#1439](https://github.com/realm/realm-cocoa/issues/1439)

- Interprocess: shared container sample app [\#1377](https://github.com/realm/realm-cocoa/issues/1377)

**Fixed bugs:**

- \_inWriteTransaction should be set to YES before triggering notificaions in beginWriteTransaction [\#1477](https://github.com/realm/realm-cocoa/issues/1477)

- maxOfProperty on RLMResults sometimes returns +Inf [\#1461](https://github.com/realm/realm-cocoa/issues/1461)

- setSchemaVersion and migrateRealm should throw if Realm is already open [\#1455](https://github.com/realm/realm-cocoa/issues/1455)

**Closed issues:**

- Json support with 'null' value and missing fields [\#1527](https://github.com/realm/realm-cocoa/issues/1527)

- dyld: Symbol not found: \_CFAutorelease in iOS 6 [\#1526](https://github.com/realm/realm-cocoa/issues/1526)

- Realm Locking Main Thread Indefinitely [\#1522](https://github.com/realm/realm-cocoa/issues/1522)

- Error installing Realm cocoapod [\#1520](https://github.com/realm/realm-cocoa/issues/1520)

- No results in RLMRealm after restarting app [\#1511](https://github.com/realm/realm-cocoa/issues/1511)

- Can't mutate a persisted array outside of a write transaction [\#1509](https://github.com/realm/realm-cocoa/issues/1509)

- `objectsWhere` on RLMResults [\#1507](https://github.com/realm/realm-cocoa/issues/1507)

- Fix a typo in the Japanese translation [\#1497](https://github.com/realm/realm-cocoa/issues/1497)

- Realm Browser shows a user wrong counts of rows. [\#1496](https://github.com/realm/realm-cocoa/issues/1496)

- Realm alway stops a a break point when used in an Asynchronous XCTTest [\#1493](https://github.com/realm/realm-cocoa/issues/1493)

- Array of strings error: \[...\] this class is not key value coding-compliant for the key value.' [\#1491](https://github.com/realm/realm-cocoa/issues/1491)

- Ream: full text search [\#1488](https://github.com/realm/realm-cocoa/issues/1488)

- Trying to iterate through RLMResults in swift [\#1487](https://github.com/realm/realm-cocoa/issues/1487)

- sortedResultsUsingProperty cannot work when Property is primaryKey [\#1483](https://github.com/realm/realm-cocoa/issues/1483)

- Unable to declare RLMArray in Swift [\#1471](https://github.com/realm/realm-cocoa/issues/1471)

- Ability to parse a single hardcoded cvs-file into multiple tables with loose relationships. [\#1469](https://github.com/realm/realm-cocoa/issues/1469)

- Realm in different app versions [\#1464](https://github.com/realm/realm-cocoa/issues/1464)

- Extra argument 'forRealmAtPath' in call [\#1463](https://github.com/realm/realm-cocoa/issues/1463)

- Duplicate interface definition for class RLMObject with 0.90.4 [\#1444](https://github.com/realm/realm-cocoa/issues/1444)

- Schema without Objects in Tests [\#1436](https://github.com/realm/realm-cocoa/issues/1436)

- defaultRealm returns nil [\#1435](https://github.com/realm/realm-cocoa/issues/1435)

- Encrypted Realm crashes on 64bit iOS devices when dealing with Shared Group stuff [\#1432](https://github.com/realm/realm-cocoa/issues/1432)

**Merged pull requests:**

- \[Realm.podspec\] Fix platform deployment targets [\#1529](https://github.com/realm/realm-cocoa/pull/1529) ([segiddins](https://github.com/segiddins))

- Avoid an unnecessary write transaction when opening Realms [\#1519](https://github.com/realm/realm-cocoa/pull/1519) ([tgoyne](https://github.com/tgoyne))

- Fix for deleting objects from the wrong realm [\#1513](https://github.com/realm/realm-cocoa/pull/1513) ([alazier](https://github.com/alazier))

- Fix warning in testDataObjectDescription [\#1505](https://github.com/realm/realm-cocoa/pull/1505) ([yuuki1224](https://github.com/yuuki1224))

- \[RealmSwift\] Add test for ignored property default values [\#1484](https://github.com/realm/realm-cocoa/pull/1484) ([segiddins](https://github.com/segiddins))

- set \_inWriteTranscation before triggering notifications in beginWriteTransaction [\#1482](https://github.com/realm/realm-cocoa/pull/1482) ([alazier](https://github.com/alazier))

- \[RLMObjectBase\] Truncate description for NSData properties [\#1481](https://github.com/realm/realm-cocoa/pull/1481) ([segiddins](https://github.com/segiddins))

- \[RLMObject\] Declare re-declared/inherited properties as @dynamic [\#1480](https://github.com/realm/realm-cocoa/pull/1480) ([segiddins](https://github.com/segiddins))

- Add OS X tests for doing things with multiple processes [\#1479](https://github.com/realm/realm-cocoa/pull/1479) ([tgoyne](https://github.com/tgoyne))

- \[RLMObjectStore\] Improve the exception message when attempting to migrat... [\#1478](https://github.com/realm/realm-cocoa/pull/1478) ([segiddins](https://github.com/segiddins))

- \[Browser\] Ignore object schemas with no properties [\#1467](https://github.com/realm/realm-cocoa/pull/1467) ([segiddins](https://github.com/segiddins))

- Another try at fixing ci for swift [\#1462](https://github.com/realm/realm-cocoa/pull/1462) ([alazier](https://github.com/alazier))

- \[Browser\] Use modular imports [\#1459](https://github.com/realm/realm-cocoa/pull/1459) ([segiddins](https://github.com/segiddins))

- Use $TMPDIR instead of direct access to /tmp. [\#1458](https://github.com/realm/realm-cocoa/pull/1458) ([neonichu](https://github.com/neonichu))

- \[RLMRealm\] Throw an exception when trying to set schema version or migra... [\#1456](https://github.com/realm/realm-cocoa/pull/1456) ([segiddins](https://github.com/segiddins))

- Update to core 0.88.1 [\#1452](https://github.com/realm/realm-cocoa/pull/1452) ([tgoyne](https://github.com/tgoyne))

- Add assertThrows to RealmSwift tests [\#1451](https://github.com/realm/realm-cocoa/pull/1451) ([segiddins](https://github.com/segiddins))

- illustrator logo [\#1442](https://github.com/realm/realm-cocoa/pull/1442) ([yoshyosh](https://github.com/yoshyosh))

- Add an example app that uses extensions [\#1420](https://github.com/realm/realm-cocoa/pull/1420) ([segiddins](https://github.com/segiddins))

## [v0.90.5](https://github.com/realm/realm-cocoa/tree/v0.90.5) (2015-02-04)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.90.4...v0.90.5)

**Implemented enhancements:**

- Using single code path for creating exceptions/Add library version to user info [\#1372](https://github.com/realm/realm-cocoa/issues/1372)

- Replace object attributes with single method to specify indexed columns [\#935](https://github.com/realm/realm-cocoa/issues/935)

**Fixed bugs:**

- Crash when device is locked [\#1260](https://github.com/realm/realm-cocoa/issues/1260)

**Closed issues:**

- Carthage builds both "iOS" and "iOS 8" targets to same output file [\#1447](https://github.com/realm/realm-cocoa/issues/1447)

- A little bit confused about the threading model [\#1445](https://github.com/realm/realm-cocoa/issues/1445)

- Missing comma in Cocoa migration docs [\#1433](https://github.com/realm/realm-cocoa/issues/1433)

- Centralize exception creation in a single function [\#1374](https://github.com/realm/realm-cocoa/issues/1374)

- Auto-refreshing realms and notifications possible race condition [\#1357](https://github.com/realm/realm-cocoa/issues/1357)

**Merged pull requests:**

- \[RLMUtil\] Only try to import RLMVersion.h if REALM\_VERSION is undefined. [\#1446](https://github.com/realm/realm-cocoa/pull/1446) ([segiddins](https://github.com/segiddins))

- Changed realm logo to a small one of better quality [\#1441](https://github.com/realm/realm-cocoa/pull/1441) ([yoshyosh](https://github.com/yoshyosh))

- Replace attributes by property indexed [\#1440](https://github.com/realm/realm-cocoa/pull/1440) ([mrackwitz](https://github.com/mrackwitz))

- Cherry-Pick of Changes to Realm.framework [\#1438](https://github.com/realm/realm-cocoa/pull/1438) ([mrackwitz](https://github.com/mrackwitz))

- renamed reference to wrong method in ref-doc [\#1437](https://github.com/realm/realm-cocoa/pull/1437) ([bmunkholm](https://github.com/bmunkholm))

- \[RLMProperty\] Re-add isEqualToProperty: [\#1434](https://github.com/realm/realm-cocoa/pull/1434) ([segiddins](https://github.com/segiddins))

- Centralize exception creation [\#1423](https://github.com/realm/realm-cocoa/pull/1423) ([segiddins](https://github.com/segiddins))

## [v0.90.4](https://github.com/realm/realm-cocoa/tree/v0.90.4) (2015-01-29)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.90.3...v0.90.4)

**Closed issues:**

- Update setSchemaVersion:withMigrationBlock: with forRealmAtPath docs [\#1430](https://github.com/realm/realm-cocoa/issues/1430)

**Merged pull requests:**

- Fix for invalid property comparison and reuse during column reorder and migrations [\#1431](https://github.com/realm/realm-cocoa/pull/1431) ([alazier](https://github.com/alazier))

- Added logo to readme [\#1422](https://github.com/realm/realm-cocoa/pull/1422) ([yoshyosh](https://github.com/yoshyosh))

- \[Documentation\] Document the swift interface [\#1356](https://github.com/realm/realm-cocoa/pull/1356) ([segiddins](https://github.com/segiddins))

## [v0.90.3](https://github.com/realm/realm-cocoa/tree/v0.90.3) (2015-01-27)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.90.2...v0.90.3)

**Fixed bugs:**

- Passing a realm-backed RLMObject to createOrUpdate should throw an exception [\#1409](https://github.com/realm/realm-cocoa/issues/1409)

**Closed issues:**

- sortedResultsUsingProperty with non stored properties [\#1411](https://github.com/realm/realm-cocoa/issues/1411)

- Can't seem to use Realm in an embedded framework [\#1408](https://github.com/realm/realm-cocoa/issues/1408)

- Realm's dynamic framework isn't copied into the Build directory when using Carthage [\#1398](https://github.com/realm/realm-cocoa/issues/1398)

- Corrupted Database [\#1212](https://github.com/realm/realm-cocoa/issues/1212)

**Merged pull requests:**

- Improvements to RLMObject create\* methods when argument is an RLMObject [\#1415](https://github.com/realm/realm-cocoa/pull/1415) ([jpsim](https://github.com/jpsim))

- Throw an exception when adding an invalidated or deleted object as a link [\#1414](https://github.com/realm/realm-cocoa/pull/1414) ([jpsim](https://github.com/jpsim))

- Fix accessor creation when the first Realm opened is read-only [\#1412](https://github.com/realm/realm-cocoa/pull/1412) ([tgoyne](https://github.com/tgoyne))

- Support List<Object\> properties in swift migrations [\#1407](https://github.com/realm/realm-cocoa/pull/1407) ([alazier](https://github.com/alazier))

- Removed readme beta logo and replaced with h1 realm [\#1403](https://github.com/realm/realm-cocoa/pull/1403) ([yoshyosh](https://github.com/yoshyosh))

## [v0.90.2](https://github.com/realm/realm-cocoa/tree/v0.90.2) (2015-01-23)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.90.1...v0.90.2)

**Closed issues:**

- Realm/RLMPlatform.h file not found in ver.0.90.1 [\#1400](https://github.com/realm/realm-cocoa/issues/1400)

**Merged pull requests:**

- \[Podspec\] Add missing RLMPlatform to public\_header\_files [\#1402](https://github.com/realm/realm-cocoa/pull/1402) ([mrackwitz](https://github.com/mrackwitz))

## [v0.90.1](https://github.com/realm/realm-cocoa/tree/v0.90.1) (2015-01-22)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.90.0...v0.90.1)

**Implemented enhancements:**

- Add missing declarations in Swift interface [\#1383](https://github.com/realm/realm-cocoa/issues/1383)

**Closed issues:**

- Crash after updating to 0.90.0 [\#1394](https://github.com/realm/realm-cocoa/issues/1394)

- "RLMObject" Model auto create? [\#1390](https://github.com/realm/realm-cocoa/issues/1390)

- RLMAccessor.h:20:9: 'RLMObjectStore.hpp' file not found - podspec issue [\#1388](https://github.com/realm/realm-cocoa/issues/1388)

- 'No value or default value specified for property' error with defaultPropertyValues implemented [\#1371](https://github.com/realm/realm-cocoa/issues/1371)

- Crash on dealloc in detach\(\) [\#1105](https://github.com/realm/realm-cocoa/issues/1105)

**Merged pull requests:**

- Fix grouped queries on allObjects [\#1396](https://github.com/realm/realm-cocoa/pull/1396) ([tgoyne](https://github.com/tgoyne))

- Add more files to private\_header\_files [\#1393](https://github.com/realm/realm-cocoa/pull/1393) ([tgoyne](https://github.com/tgoyne))

- Refactor the Realm cache and inter-thread change notifications [\#1392](https://github.com/realm/realm-cocoa/pull/1392) ([tgoyne](https://github.com/tgoyne))

- Don't include RLMObject/RealmSwift.Object in the object schema [\#1391](https://github.com/realm/realm-cocoa/pull/1391) ([tgoyne](https://github.com/tgoyne))

- Added missing declarations from Realm.swift [\#1382](https://github.com/realm/realm-cocoa/pull/1382) ([jpsim](https://github.com/jpsim))

## [v0.90.0](https://github.com/realm/realm-cocoa/tree/v0.90.0) (2015-01-21)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.89.2...v0.90.0)

**Implemented enhancements:**

- Display all errors in the Realm Browser [\#1354](https://github.com/realm/realm-cocoa/issues/1354)

- Support per-Realm migration blocks and schema versions per Realm [\#1336](https://github.com/realm/realm-cocoa/issues/1336)

- Update docs Re. Installation [\#1314](https://github.com/realm/realm-cocoa/issues/1314)

- Add mechanism to check if a migration is needed at a given path [\#1310](https://github.com/realm/realm-cocoa/issues/1310)

- Support dynamic defaults in defaultPropertyValues [\#1251](https://github.com/realm/realm-cocoa/issues/1251)

- allObjects should return RLMArray backed by a Table [\#1178](https://github.com/realm/realm-cocoa/issues/1178)

**Fixed bugs:**

- crash when deleteAllObjects in the block called by dispatch\_barrier\_async [\#1359](https://github.com/realm/realm-cocoa/issues/1359)

- EXC\_BAD\_ACCESS after sort of empty RLMArray in tightdb::LinkView::get\_sorted\_view [\#1255](https://github.com/realm/realm-cocoa/issues/1255)

**Closed issues:**

- Include property name in the exception "Inserting invalid object for RLMPropertyTypeAny property" [\#1369](https://github.com/realm/realm-cocoa/issues/1369)

- Is it possible to create unique pair in realm? [\#1360](https://github.com/realm/realm-cocoa/issues/1360)

- Properly support failed migrations [\#1348](https://github.com/realm/realm-cocoa/issues/1348)

- RLMObject subclasses should inherit parents defaultValues [\#1341](https://github.com/realm/realm-cocoa/issues/1341)

- RLMObject persisted in 2nd Realm requires migration before either is open [\#1334](https://github.com/realm/realm-cocoa/issues/1334)

- RLMResults for the IN operator aren't sorted as expected [\#1325](https://github.com/realm/realm-cocoa/issues/1325)

- Sort a column in browser? [\#1321](https://github.com/realm/realm-cocoa/issues/1321)

- Realm Browser hangs on startup [\#1320](https://github.com/realm/realm-cocoa/issues/1320)

- primary key caused to crash [\#1319](https://github.com/realm/realm-cocoa/issues/1319)

- RLMResults returns deleted objects [\#1317](https://github.com/realm/realm-cocoa/issues/1317)

- Add mechanism to remove all cached Realms [\#1316](https://github.com/realm/realm-cocoa/issues/1316)

- Assertion failed: row\_ndx < size\(\) [\#1315](https://github.com/realm/realm-cocoa/issues/1315)

- Can Realm migration perform a type transformation? [\#1311](https://github.com/realm/realm-cocoa/issues/1311)

- Rename api methods which take encryption keys [\#1307](https://github.com/realm/realm-cocoa/issues/1307)

- Duplicate interface definition for class 'RLMResults', compile error when installing Realm via CocoaPods [\#1303](https://github.com/realm/realm-cocoa/issues/1303)

- No Such Module 'Realm' in Swift Project [\#1302](https://github.com/realm/realm-cocoa/issues/1302)

- Support fast retrieval of all distinct values for a RLMObject key path.  [\#1297](https://github.com/realm/realm-cocoa/issues/1297)

- error: could not build Objective-C module 'Realm' [\#1280](https://github.com/realm/realm-cocoa/issues/1280)

- Ability to check if an RLMObject is being accessed from the correct thread [\#1273](https://github.com/realm/realm-cocoa/issues/1273)

- realm crashed when adding object to realm [\#1227](https://github.com/realm/realm-cocoa/issues/1227)

**Merged pull requests:**

- Add support for comparing string columns in queries [\#1376](https://github.com/realm/realm-cocoa/pull/1376) ([tgoyne](https://github.com/tgoyne))

- \[RLMAccessor\] Improve the exception message when trying to set a property with an object of the incorrect type. [\#1375](https://github.com/realm/realm-cocoa/pull/1375) ([segiddins](https://github.com/segiddins))

- Update to core version 0.88.0 [\#1373](https://github.com/realm/realm-cocoa/pull/1373) ([tgoyne](https://github.com/tgoyne))

- Updated Swift docs by fixing typos and explicitly marking internal declations [\#1367](https://github.com/realm/realm-cocoa/pull/1367) ([jpsim](https://github.com/jpsim))

- \[Browser\] Present errors to the user [\#1365](https://github.com/realm/realm-cocoa/pull/1365) ([segiddins](https://github.com/segiddins))

- Add "export compliance" section and ToC in LICENSE [\#1363](https://github.com/realm/realm-cocoa/pull/1363) ([jpsim](https://github.com/jpsim))

- Fix removing primary keys [\#1361](https://github.com/realm/realm-cocoa/pull/1361) ([tgoyne](https://github.com/tgoyne))

- \[Podspec\] Fix private header definition for using frameworks with CocoaPods [\#1358](https://github.com/realm/realm-cocoa/pull/1358) ([mrackwitz](https://github.com/mrackwitz))

- Allow per Realm schema versions and migration [\#1355](https://github.com/realm/realm-cocoa/pull/1355) ([alazier](https://github.com/alazier))

- Use a Table-backed RLMResults for allObjects [\#1353](https://github.com/realm/realm-cocoa/pull/1353) ([tgoyne](https://github.com/tgoyne))

- Improve error reporting for incompatible lock files [\#1352](https://github.com/realm/realm-cocoa/pull/1352) ([tgoyne](https://github.com/tgoyne))

- Update to core 0.87.5 [\#1351](https://github.com/realm/realm-cocoa/pull/1351) ([tgoyne](https://github.com/tgoyne))

- Fix dynamic framework distribution [\#1349](https://github.com/realm/realm-cocoa/pull/1349) ([jpsim](https://github.com/jpsim))

- fix build.sh clean [\#1347](https://github.com/realm/realm-cocoa/pull/1347) ([jpsim](https://github.com/jpsim))

- Allow indexing ints and index int primary keys [\#1346](https://github.com/realm/realm-cocoa/pull/1346) ([tgoyne](https://github.com/tgoyne))

- Remove the NSData size checks [\#1345](https://github.com/realm/realm-cocoa/pull/1345) ([tgoyne](https://github.com/tgoyne))

- \[Examples/Obj-C\] Fixed date format and set time zone offset such that the JSON strings are now parsed correctly. [\#1343](https://github.com/realm/realm-cocoa/pull/1343) ([danielpovlsen](https://github.com/danielpovlsen))

- \[Realm\] Default NSErrorPointer parameters to nil [\#1338](https://github.com/realm/realm-cocoa/pull/1338) ([segiddins](https://github.com/segiddins))

- Bring Swift public interface to parity with Objective-C [\#1337](https://github.com/realm/realm-cocoa/pull/1337) ([segiddins](https://github.com/segiddins))

- Update iOS examples for the Swift API [\#1333](https://github.com/realm/realm-cocoa/pull/1333) ([segiddins](https://github.com/segiddins))

- Clean up header inclusions [\#1330](https://github.com/realm/realm-cocoa/pull/1330) ([tgoyne](https://github.com/tgoyne))

- Fix json import example [\#1323](https://github.com/realm/realm-cocoa/pull/1323) ([simonask](https://github.com/simonask))

- Add method to expose schema version - Code clean up [\#1318](https://github.com/realm/realm-cocoa/pull/1318) ([alazier](https://github.com/alazier))

- Eliminate duplicated copies of the header files [\#1309](https://github.com/realm/realm-cocoa/pull/1309) ([tgoyne](https://github.com/tgoyne))

- Rename methods for encrypted realms [\#1308](https://github.com/realm/realm-cocoa/pull/1308) ([tgoyne](https://github.com/tgoyne))

- \[RLMRealm\] Fix alignment inside catch statement [\#1306](https://github.com/realm/realm-cocoa/pull/1306) ([segiddins](https://github.com/segiddins))

- \[build.sh\] Remove CocoaPods include directories before creating them [\#1305](https://github.com/realm/realm-cocoa/pull/1305) ([segiddins](https://github.com/segiddins))

- \[Browser\] Disable column reordering [\#1304](https://github.com/realm/realm-cocoa/pull/1304) ([segiddins](https://github.com/segiddins))

- Actually encrypt the write logs [\#1301](https://github.com/realm/realm-cocoa/pull/1301) ([tgoyne](https://github.com/tgoyne))

- Add writeEncryptedCopyToPath:key:error: [\#1299](https://github.com/realm/realm-cocoa/pull/1299) ([tgoyne](https://github.com/tgoyne))

- Fix some realm lifetime issues [\#1298](https://github.com/realm/realm-cocoa/pull/1298) ([tgoyne](https://github.com/tgoyne))

- Add a check for the count changing during RLMResults fast enumeration [\#1296](https://github.com/realm/realm-cocoa/pull/1296) ([tgoyne](https://github.com/tgoyne))

- Roll back changes made when an exception is thrown during a migration. [\#1293](https://github.com/realm/realm-cocoa/pull/1293) ([tgoyne](https://github.com/tgoyne))

- Additions/Refactor of Realm.framework to support new swift apis [\#1284](https://github.com/realm/realm-cocoa/pull/1284) ([alazier](https://github.com/alazier))

- Roll back the write transaction on schema init if nothing changed [\#1281](https://github.com/realm/realm-cocoa/pull/1281) ([tgoyne](https://github.com/tgoyne))

## [v0.89.2](https://github.com/realm/realm-cocoa/tree/v0.89.2) (2015-01-02)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.89.1...v0.89.2)

**Fixed bugs:**

- Realm Browser Generates Broken UTF-16 Source Code [\#1271](https://github.com/realm/realm-cocoa/issues/1271)

- Realm Browser Not Working [\#1266](https://github.com/realm/realm-cocoa/issues/1266)

**Closed issues:**

- Podspec with framework [\#1290](https://github.com/realm/realm-cocoa/issues/1290)

- data order be changed after deleteObject [\#1289](https://github.com/realm/realm-cocoa/issues/1289)

- Unable to query NSDate properties  [\#1288](https://github.com/realm/realm-cocoa/issues/1288)

- How to delete classes in realm file? [\#1283](https://github.com/realm/realm-cocoa/issues/1283)

- Compile error 'Could not build Objective-C module Realm' [\#1275](https://github.com/realm/realm-cocoa/issues/1275)

- Support for querying objects by class name [\#1274](https://github.com/realm/realm-cocoa/issues/1274)

- Reloading Realm Browser [\#1269](https://github.com/realm/realm-cocoa/issues/1269)

- Change subscript index type to Int  [\#1261](https://github.com/realm/realm-cocoa/issues/1261)

- Realm Add Data twice  [\#1215](https://github.com/realm/realm-cocoa/issues/1215)

**Merged pull requests:**

- Update to core 0.87.04 [\#1292](https://github.com/realm/realm-cocoa/pull/1292) ([tgoyne](https://github.com/tgoyne))

- update README to point to latest setup instructions, reflect current API & tell people to email help@realm.io [\#1282](https://github.com/realm/realm-cocoa/pull/1282) ([jpsim](https://github.com/jpsim))

- Fix for browser on mavericks [\#1268](https://github.com/realm/realm-cocoa/pull/1268) ([alazier](https://github.com/alazier))

- Fix an assertion failure in -\[RLMRealm invalidate\] when the Realm is not in read mode [\#1264](https://github.com/realm/realm-cocoa/pull/1264) ([tgoyne](https://github.com/tgoyne))

- \[RLMRealm docs\] Added doc overview to RLMRealm \(fixes \#1198\) [\#1246](https://github.com/realm/realm-cocoa/pull/1246) ([jpsim](https://github.com/jpsim))

## [v0.89.1](https://github.com/realm/realm-cocoa/tree/v0.89.1) (2014-12-22)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.89.0...v0.89.1)

**Implemented enhancements:**

- Can I have two or more Realm files and have relationships between them? [\#1224](https://github.com/realm/realm-cocoa/issues/1224)

**Fixed bugs:**

- Apps built with the dynamic framework can't be submitted to App store [\#1163](https://github.com/realm/realm-cocoa/issues/1163)

**Closed issues:**

- Unable to setup inverse relationship using backlink on persisted properties [\#1259](https://github.com/realm/realm-cocoa/issues/1259)

- Unable to setup inverse relationship [\#1258](https://github.com/realm/realm-cocoa/issues/1258)

- Unable to setup inverse relationship [\#1257](https://github.com/realm/realm-cocoa/issues/1257)

- Dynamic modifier on Swift property leaves property observer uncalled [\#1254](https://github.com/realm/realm-cocoa/issues/1254)

- After deleting all objects, unable to write again [\#1252](https://github.com/realm/realm-cocoa/issues/1252)

- Memory Error [\#1250](https://github.com/realm/realm-cocoa/issues/1250)

- 'RLMException', reason: 'No property matching primary key - but I am not using primary key [\#1249](https://github.com/realm/realm-cocoa/issues/1249)

- How to transfer large dataset to Realm [\#1248](https://github.com/realm/realm-cocoa/issues/1248)

- Realm which installed by CocoaPods couldn't add any object in test target [\#1247](https://github.com/realm/realm-cocoa/issues/1247)

- @Ignore equivalent in realm-cocoa [\#1245](https://github.com/realm/realm-cocoa/issues/1245)

- Release v0.89.0 [\#1241](https://github.com/realm/realm-cocoa/issues/1241)

- Realm Browser locks up after trying to browse third level nested object [\#1239](https://github.com/realm/realm-cocoa/issues/1239)

**Merged pull requests:**

- Update core version [\#1262](https://github.com/realm/realm-cocoa/pull/1262) ([tgoyne](https://github.com/tgoyne))

- split dynamic framework into separate device/simulator frameworks [\#1253](https://github.com/realm/realm-cocoa/pull/1253) ([jpsim](https://github.com/jpsim))

- Clarified exception message when opening a realm with insufficient permissions [\#1235](https://github.com/realm/realm-cocoa/pull/1235) ([jpsim](https://github.com/jpsim))

## [v0.89.0](https://github.com/realm/realm-cocoa/tree/v0.89.0) (2014-12-18)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.88.0...v0.89.0)

**Implemented enhancements:**

- Apache Cordova \(phonegap\) plugin [\#1165](https://github.com/realm/realm-cocoa/issues/1165)

- Encryption support [\#949](https://github.com/realm/realm-cocoa/issues/949)

**Fixed bugs:**

- Icons broken in AppleDocs on the website [\#1189](https://github.com/realm/realm-cocoa/issues/1189)

**Closed issues:**

- primaryKey and relationships [\#1244](https://github.com/realm/realm-cocoa/issues/1244)

- Document binary/string size limit of 16MB [\#1237](https://github.com/realm/realm-cocoa/issues/1237)

- An Object which is KVC compliant doesn't necessarily respondsToSelector:"property" [\#1236](https://github.com/realm/realm-cocoa/issues/1236)

- Cannnot get object from RLMResult [\#1233](https://github.com/realm/realm-cocoa/issues/1233)

- allObjects not returning elements [\#1232](https://github.com/realm/realm-cocoa/issues/1232)

- Exception raised when using a custom getter name for a property [\#1228](https://github.com/realm/realm-cocoa/issues/1228)

- 'className' method returns the wrong classname for swift subclasses [\#1225](https://github.com/realm/realm-cocoa/issues/1225)

- Is writeCopyToPath's path relative to macbook HD or virtual iOS? [\#1223](https://github.com/realm/realm-cocoa/issues/1223)

- External Storage [\#1218](https://github.com/realm/realm-cocoa/issues/1218)

- Add performance tests to CI [\#1214](https://github.com/realm/realm-cocoa/issues/1214)

- Object with empty fields [\#1213](https://github.com/realm/realm-cocoa/issues/1213)

- Why is this if returning false? [\#1211](https://github.com/realm/realm-cocoa/issues/1211)

- Please help with syntax inside the quotes of Class.objectsWhere\("table = 'row'"\) [\#1210](https://github.com/realm/realm-cocoa/issues/1210)

- How to synchronize Realm data across multiple iOS/Android devices? [\#1208](https://github.com/realm/realm-cocoa/issues/1208)

- Fix unneeded retain/release calls from property getters [\#1201](https://github.com/realm/realm-cocoa/issues/1201)

- Casting RLMObject subclass causing properties to disappear [\#1196](https://github.com/realm/realm-cocoa/issues/1196)

- setDefaultRealm is not available in 0.88 [\#1193](https://github.com/realm/realm-cocoa/issues/1193)

- Compound Key [\#1192](https://github.com/realm/realm-cocoa/issues/1192)

- Invalid value for property during migration  [\#1191](https://github.com/realm/realm-cocoa/issues/1191)

- RLMNotificationToken crashing the app [\#1190](https://github.com/realm/realm-cocoa/issues/1190)

- Cannot link Realm as part of a CocoaPod pod [\#1184](https://github.com/realm/realm-cocoa/issues/1184)

- Incorrect implementation of +\[RLMSchema initialize\] leads to uncatchable exceptions \(crashes\). [\#1180](https://github.com/realm/realm-cocoa/issues/1180)

- crash while loading objects after unsuccessful write [\#1176](https://github.com/realm/realm-cocoa/issues/1176)

- LLDB Support dependency on the plugin [\#1173](https://github.com/realm/realm-cocoa/issues/1173)

- Predicate to filter out IDs not working anymore [\#1171](https://github.com/realm/realm-cocoa/issues/1171)

- Can't debug the Realm Framework [\#1170](https://github.com/realm/realm-cocoa/issues/1170)

- mmap\(\) failed: Cannot allocate memory [\#1159](https://github.com/realm/realm-cocoa/issues/1159)

- Crash with EXC\_BAD\_ACCESS KERN\_INVALID\_ADDRESS while calling .cxx\_destruct [\#1151](https://github.com/realm/realm-cocoa/issues/1151)

- Static analyze have unused bool value [\#1149](https://github.com/realm/realm-cocoa/issues/1149)

- deleteObject in a background thread causing thightdb::\*:get methods [\#1148](https://github.com/realm/realm-cocoa/issues/1148)

- RLMAccessor\_v0\_MyModel unrecognized selector send to instance [\#1141](https://github.com/realm/realm-cocoa/issues/1141)

- +createInRealm:withObject: \(and variants\) discards default Swift property values [\#1138](https://github.com/realm/realm-cocoa/issues/1138)

- `objectsWithPredicate:` works; but `objectsInRealm:withPredicate` causes exception on default realm?  [\#1113](https://github.com/realm/realm-cocoa/issues/1113)

- I can not open TWO Realm database file read and write at the same time.  [\#1099](https://github.com/realm/realm-cocoa/issues/1099)

- Many concurrent accesses lead to crash [\#1096](https://github.com/realm/realm-cocoa/issues/1096)

- Crash when query executed in background [\#1077](https://github.com/realm/realm-cocoa/issues/1077)

- Swift Dynamic Cast Conditional Error [\#1044](https://github.com/realm/realm-cocoa/issues/1044)

- Support for ANY string comparison selections [\#973](https://github.com/realm/realm-cocoa/issues/973)

- Swift didSet and willSet on properties in a RLMObject [\#870](https://github.com/realm/realm-cocoa/issues/870)

- Query support for count and other aggregates [\#862](https://github.com/realm/realm-cocoa/issues/862)

**Merged pull requests:**

- Support initializing RLMObjects using kvc objects without getters [\#1242](https://github.com/realm/realm-cocoa/pull/1242) ([alazier](https://github.com/alazier))

- Fix for classname method when defining swift relationships [\#1231](https://github.com/realm/realm-cocoa/pull/1231) ([alazier](https://github.com/alazier))

- Objects with custom getter names can now be used to initialize other objects [\#1230](https://github.com/realm/realm-cocoa/pull/1230) ([jpsim](https://github.com/jpsim))

- make "ios-debug" produce a fat binary [\#1222](https://github.com/realm/realm-cocoa/pull/1222) ([jpsim](https://github.com/jpsim))

- Commit performance test baseline measurements for CI [\#1221](https://github.com/realm/realm-cocoa/pull/1221) ([segiddins](https://github.com/segiddins))

- Add a performance test for sorting [\#1220](https://github.com/realm/realm-cocoa/pull/1220) ([segiddins](https://github.com/segiddins))

- Moved installation of file templates from privileged script to a new build phase [\#1216](https://github.com/realm/realm-cocoa/pull/1216) ([mttrb](https://github.com/mttrb))

- Rollback on schema validation errors rather than committing [\#1209](https://github.com/realm/realm-cocoa/pull/1209) ([tgoyne](https://github.com/tgoyne))

- Only check for cached RLMRealms when using the shared schema [\#1207](https://github.com/realm/realm-cocoa/pull/1207) ([tgoyne](https://github.com/tgoyne))

- \[RLMProperty\] Ensure the proper class name is shown in the exception mes... [\#1206](https://github.com/realm/realm-cocoa/pull/1206) ([segiddins](https://github.com/segiddins))

- Don't clear the realm cache after performing a migration [\#1203](https://github.com/realm/realm-cocoa/pull/1203) ([tgoyne](https://github.com/tgoyne))

- Fix a memory leak when circularly linked objects are added to a Realm [\#1200](https://github.com/realm/realm-cocoa/pull/1200) ([tgoyne](https://github.com/tgoyne))

- Test "NOT IN" queries [\#1183](https://github.com/realm/realm-cocoa/pull/1183) ([jpsim](https://github.com/jpsim))

- Remove unnecessary dispatch\_once in +initialize [\#1181](https://github.com/realm/realm-cocoa/pull/1181) ([tgoyne](https://github.com/tgoyne))

- update Swift examples for Xcode 6.1.1 [\#1175](https://github.com/realm/realm-cocoa/pull/1175) ([jpsim](https://github.com/jpsim))

- First take at testing the Realm Browser \(just a single test for now\) [\#1174](https://github.com/realm/realm-cocoa/pull/1174) ([jpsim](https://github.com/jpsim))

- Merge native Swift default property values with defaultPropertyValues\(\) [\#1145](https://github.com/realm/realm-cocoa/pull/1145) ([jpsim](https://github.com/jpsim))

- Add support for encrypted Realms [\#1124](https://github.com/realm/realm-cocoa/pull/1124) ([tgoyne](https://github.com/tgoyne))

## [v0.88.0](https://github.com/realm/realm-cocoa/tree/v0.88.0) (2014-12-02)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.87.4...v0.88.0)

**Implemented enhancements:**

- Canceling transaction changes.  [\#692](https://github.com/realm/realm-cocoa/issues/692)

**Closed issues:**

- \[Question\] Queries [\#1158](https://github.com/realm/realm-cocoa/issues/1158)

- Can I modify the property in memory but do not save to disk? [\#1157](https://github.com/realm/realm-cocoa/issues/1157)

- Realm Browser 0.87.4 not displaying data [\#1147](https://github.com/realm/realm-cocoa/issues/1147)

- Executing a migration block returns wrong oldSchemaVersion [\#1140](https://github.com/realm/realm-cocoa/issues/1140)

- Defining RLMObject schema with setObject:ForKeyedSubscript: [\#1139](https://github.com/realm/realm-cocoa/issues/1139)

- allObjectsInRealm behaves strangely [\#1134](https://github.com/realm/realm-cocoa/issues/1134)

- Support returning subclasses in queries [\#1132](https://github.com/realm/realm-cocoa/issues/1132)

- open\(\) failed: Operation not permitted [\#1130](https://github.com/realm/realm-cocoa/issues/1130)

- When Realm goes to 1.0? [\#1129](https://github.com/realm/realm-cocoa/issues/1129)

- Crash on trying to access default Realm [\#1126](https://github.com/realm/realm-cocoa/issues/1126)

- Should `RLMCollection` confront `NSObject` and declare `realm` as an required property? [\#1125](https://github.com/realm/realm-cocoa/issues/1125)

- Supporting Empty or Null Values  [\#1122](https://github.com/realm/realm-cocoa/issues/1122)

- NSCaseInsensitivePredicateOption not supported for queries on linked strings [\#1119](https://github.com/realm/realm-cocoa/issues/1119)

- Crash in tightdb::Array::get\_bptree\_leaf [\#1118](https://github.com/realm/realm-cocoa/issues/1118)

- Unable to deploy to device after upgrading to 0.87.4 [\#1117](https://github.com/realm/realm-cocoa/issues/1117)

- Deleting objects not conforming to a predicate [\#1115](https://github.com/realm/realm-cocoa/issues/1115)

- Class name issue [\#1114](https://github.com/realm/realm-cocoa/issues/1114)

- Push new version to CocoaPods [\#1112](https://github.com/realm/realm-cocoa/issues/1112)

- open\(\) failed: No such file or directory [\#1111](https://github.com/realm/realm-cocoa/issues/1111)

- Do not possible make working on custom threads for Realm [\#1108](https://github.com/realm/realm-cocoa/issues/1108)

- Realm always throws exception on startup after initial run. [\#1082](https://github.com/realm/realm-cocoa/issues/1082)

- Crashed in my project just call \[RLMRealm defaultRealm\] [\#1080](https://github.com/realm/realm-cocoa/issues/1080)

- Is binary version of .realm database incompatible between simulator and device? [\#1073](https://github.com/realm/realm-cocoa/issues/1073)

- Adding Realm.framework into a custom framework [\#1067](https://github.com/realm/realm-cocoa/issues/1067)

- crash on accessing attribute [\#1049](https://github.com/realm/realm-cocoa/issues/1049)

- Is there a good practice for when using Realm in app extensions?  [\#1048](https://github.com/realm/realm-cocoa/issues/1048)

- Error while installing in cocoapods [\#1022](https://github.com/realm/realm-cocoa/issues/1022)

- Lexical or preprocessor issue: 'string' file not found [\#919](https://github.com/realm/realm-cocoa/issues/919)

**Merged pull requests:**

- Only set the RLMResults once in the ios/objc/TableView example [\#1168](https://github.com/realm/realm-cocoa/pull/1168) ([jpsim](https://github.com/jpsim))

- Fix error message when no migration block is specified for old Realms [\#1167](https://github.com/realm/realm-cocoa/pull/1167) ([alazier](https://github.com/alazier))

- \[Podspec\] Add build.sh to preserve\_paths [\#1164](https://github.com/realm/realm-cocoa/pull/1164) ([segiddins](https://github.com/segiddins))

- cancel transaction on RLMRealm dealloc if still in write transaction [\#1161](https://github.com/realm/realm-cocoa/pull/1161) ([jpsim](https://github.com/jpsim))

- Add -\[RLMRealm invalidate\] [\#1156](https://github.com/realm/realm-cocoa/pull/1156) ([tgoyne](https://github.com/tgoyne))

- Fix error message when using the lldb script with Swift [\#1155](https://github.com/realm/realm-cocoa/pull/1155) ([tgoyne](https://github.com/tgoyne))

- Don't log update checker errors [\#1154](https://github.com/realm/realm-cocoa/pull/1154) ([tgoyne](https://github.com/tgoyne))

- Make sure accessor creation is thread safe [\#1146](https://github.com/realm/realm-cocoa/pull/1146) ([alazier](https://github.com/alazier))

- Add method to change the default Realm path [\#1143](https://github.com/realm/realm-cocoa/pull/1143) ([alazier](https://github.com/alazier))

- Fix for incorrect Realm version for newly created Realms [\#1142](https://github.com/realm/realm-cocoa/pull/1142) ([alazier](https://github.com/alazier))

- Copy properties with schema [\#1137](https://github.com/realm/realm-cocoa/pull/1137) ([alazier](https://github.com/alazier))

- Ddd missing properties to RLMCollection protocol [\#1136](https://github.com/realm/realm-cocoa/pull/1136) ([alazier](https://github.com/alazier))

- Generate multiple sets of accessors for different schema [\#1135](https://github.com/realm/realm-cocoa/pull/1135) ([alazier](https://github.com/alazier))

- Enable BEGINSWITH/ENDSWITH/CONTAINS on linked strings [\#1128](https://github.com/realm/realm-cocoa/pull/1128) ([tgoyne](https://github.com/tgoyne))

- Updated core release with bug fixes [\#1127](https://github.com/realm/realm-cocoa/pull/1127) ([alazier](https://github.com/alazier))

- Change `-\[RLMRealm writeCopyToPath:\]` to follow Cocoa's error handling conventions [\#1123](https://github.com/realm/realm-cocoa/pull/1123) ([tonyarnold](https://github.com/tonyarnold))

- added test to confirm that writing to two different realms simultaneously works [\#1121](https://github.com/realm/realm-cocoa/pull/1121) ([jpsim](https://github.com/jpsim))

- added test to confirm that Swift RLMObject properties with no setter defined are ignored by Realm [\#1116](https://github.com/realm/realm-cocoa/pull/1116) ([jpsim](https://github.com/jpsim))

- added "backlink" examples for objc & swift [\#1110](https://github.com/realm/realm-cocoa/pull/1110) ([jpsim](https://github.com/jpsim))

- add sections to table view examples [\#1106](https://github.com/realm/realm-cocoa/pull/1106) ([jpsim](https://github.com/jpsim))

- Fix the RLMVerifyInWriteTransaction error message [\#1098](https://github.com/realm/realm-cocoa/pull/1098) ([tgoyne](https://github.com/tgoyne))

- Add -\[RLMRealm saveCopyToPath:\] [\#1091](https://github.com/realm/realm-cocoa/pull/1091) ([tgoyne](https://github.com/tgoyne))

- Change update checker frequency to once an hour [\#1089](https://github.com/realm/realm-cocoa/pull/1089) ([tgoyne](https://github.com/tgoyne))

- Add lldb debug visualizer [\#1078](https://github.com/realm/realm-cocoa/pull/1078) ([tgoyne](https://github.com/tgoyne))

- Optimize firstObject/lastObject/objectAtIndex at bit [\#1007](https://github.com/realm/realm-cocoa/pull/1007) ([tgoyne](https://github.com/tgoyne))

## [v0.87.4](https://github.com/realm/realm-cocoa/tree/v0.87.4) (2014-11-08)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.87.3...v0.87.4)

## [v0.87.3](https://github.com/realm/realm-cocoa/tree/v0.87.3) (2014-11-08)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.87.1...v0.87.3)

**Implemented enhancements:**

- Inverse Relationships. [\#677](https://github.com/realm/realm-cocoa/issues/677)

**Closed issues:**

- App crashes during migration \(0.87.2\) [\#1102](https://github.com/realm/realm-cocoa/issues/1102)

- Realm v0.87.1 deleteObjects crash [\#1095](https://github.com/realm/realm-cocoa/issues/1095)

- Confusing wording in RLMVerifyInWriteTransaction of RLMObjectStore [\#1094](https://github.com/realm/realm-cocoa/issues/1094)

- Realm deleteObjects throws exception  [\#1093](https://github.com/realm/realm-cocoa/issues/1093)

- forPrimaryKey Empty Object [\#1092](https://github.com/realm/realm-cocoa/issues/1092)

- Unable to define realtionships in model classes [\#1087](https://github.com/realm/realm-cocoa/issues/1087)

- verifyPrimaryKeyUniqueness EXC\_BAD\_Access [\#1085](https://github.com/realm/realm-cocoa/issues/1085)

- createOrUpdateInRealm:withObject: returns an incomplete object [\#1081](https://github.com/realm/realm-cocoa/issues/1081)

- Realm Browser shows nothing [\#1079](https://github.com/realm/realm-cocoa/issues/1079)

- Move/copy objects between realms? [\#1076](https://github.com/realm/realm-cocoa/issues/1076)

- open\(\) not permitted - Access from Keyboard Extension to AppGroup Shared Data [\#1075](https://github.com/realm/realm-cocoa/issues/1075)

- Realm Browser not showing data from 0.87.1 release [\#1068](https://github.com/realm/realm-cocoa/issues/1068)

- What is the best way to get RLMResults from RLMArray? [\#1062](https://github.com/realm/realm-cocoa/issues/1062)

- How to check if RLMObjects exists? [\#1052](https://github.com/realm/realm-cocoa/issues/1052)

- How to perform union/intersect/minus operation on multiple to-many relationships [\#1035](https://github.com/realm/realm-cocoa/issues/1035)

- Assertion failed during migrateDefaultRealmWithBlock [\#1016](https://github.com/realm/realm-cocoa/issues/1016)

- EXC\_BAD\_ACCESS when sorting RLMArray [\#959](https://github.com/realm/realm-cocoa/issues/959)

**Merged pull requests:**

- test examples after they've been packaged [\#1107](https://github.com/realm/realm-cocoa/pull/1107) ([jpsim](https://github.com/jpsim))

- Fix for crash when deleting an object from multiple threads [\#1100](https://github.com/realm/realm-cocoa/pull/1100) ([alazier](https://github.com/alazier))

- Fix for missing search index during migrations [\#1086](https://github.com/realm/realm-cocoa/pull/1086) ([alazier](https://github.com/alazier))

- Updated references to online docs in exceptions [\#1084](https://github.com/realm/realm-cocoa/pull/1084) ([GreatApe](https://github.com/GreatApe))

- Reuse existing persisted objects passed to createInRealm:withObject: [\#1072](https://github.com/realm/realm-cocoa/pull/1072) ([tgoyne](https://github.com/tgoyne))

- Fixes the empty browser issue in yosemite [\#1070](https://github.com/realm/realm-cocoa/pull/1070) ([GreatApe](https://github.com/GreatApe))

- Throw exception in addObjects for non RLMObject [\#1064](https://github.com/realm/realm-cocoa/pull/1064) ([alazier](https://github.com/alazier))

- Basic backlink support [\#1059](https://github.com/realm/realm-cocoa/pull/1059) ([alazier](https://github.com/alazier))

- Slightly better examples testing [\#1058](https://github.com/realm/realm-cocoa/pull/1058) ([tgoyne](https://github.com/tgoyne))

- Add support for building an iOS 8 dynamic framework [\#1027](https://github.com/realm/realm-cocoa/pull/1027) ([tgoyne](https://github.com/tgoyne))

## [v0.87.1](https://github.com/realm/realm-cocoa/tree/v0.87.1) (2014-10-22)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.87.0...v0.87.1)

**Closed issues:**

- Realm Browser 0.87.0 crashes [\#1060](https://github.com/realm/realm-cocoa/issues/1060)

## [v0.87.0](https://github.com/realm/realm-cocoa/tree/v0.87.0) (2014-10-21)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.86.3...v0.87.0)

**Implemented enhancements:**

- Add support for sorting by more than one field [\#749](https://github.com/realm/realm-cocoa/issues/749)

**Fixed bugs:**

- Migrations should allow object deletion [\#1002](https://github.com/realm/realm-cocoa/issues/1002)

- Using Realm from RubyMotion throws "framework not found for architecture i386" error [\#981](https://github.com/realm/realm-cocoa/issues/981)

- Chained queries are overwriting previous query [\#927](https://github.com/realm/realm-cocoa/issues/927)

- Crash when refreshing in background [\#773](https://github.com/realm/realm-cocoa/issues/773)

**Closed issues:**

- Problem with REST API and assignment to a variable called "id" [\#1054](https://github.com/realm/realm-cocoa/issues/1054)

- Exception or assertion needed when modifying Realm Object without modifying corresponding RLM\_ARRAY\_TYPE\(Object\) [\#1051](https://github.com/realm/realm-cocoa/issues/1051)

- Assign RLMArray to an RLMObject's RLMArray property [\#1038](https://github.com/realm/realm-cocoa/issues/1038)

- Nested RLMObject subclasses have their properties inappropriately typed as RLMPropertyTypeAny [\#1036](https://github.com/realm/realm-cocoa/issues/1036)

- Getting weird issue after I app is approved through the app store. [\#1033](https://github.com/realm/realm-cocoa/issues/1033)

- Create or update not updating but deleting [\#1029](https://github.com/realm/realm-cocoa/issues/1029)

- RLMObject with array of strings [\#1028](https://github.com/realm/realm-cocoa/issues/1028)

- nil/NULL or missing value for a property in RLMObject [\#1025](https://github.com/realm/realm-cocoa/issues/1025)

- Swift default value of nil with optional flag not recognized, fails [\#1024](https://github.com/realm/realm-cocoa/issues/1024)

- Exception when querying on a relationship based object. [\#1019](https://github.com/realm/realm-cocoa/issues/1019)

- Can't set object of type 'UASCUser' to property of type '\(null\)'' [\#1003](https://github.com/realm/realm-cocoa/issues/1003)

- Background create objects [\#1001](https://github.com/realm/realm-cocoa/issues/1001)

- dyld: Library not loaded: @rpath/Realm.framework/Versions/A/Realm [\#1000](https://github.com/realm/realm-cocoa/issues/1000)

- Xcode 6.1 GM 2 + Yosemite GM 2 + Swift + Realm 0.86.2 = No such module 'Realm' [\#994](https://github.com/realm/realm-cocoa/issues/994)

- EXC\_BAD\_ACCESS when using in-memory database \(and not when not\) [\#988](https://github.com/realm/realm-cocoa/issues/988)

- Realm not loading when built as a Command Line tool project [\#975](https://github.com/realm/realm-cocoa/issues/975)

- Drop database [\#967](https://github.com/realm/realm-cocoa/issues/967)

- Build error with `.addNotificationBlock\(\)` in Swift – Xcode 6 GM iOS 8 [\#902](https://github.com/realm/realm-cocoa/issues/902)

- iTunes rejection as Swift framework requires iOS 8 minimum deployment target [\#900](https://github.com/realm/realm-cocoa/issues/900)

- Invalid string representation for a Specification cocoapods [\#823](https://github.com/realm/realm-cocoa/issues/823)

**Merged pull requests:**

- Remove RLMSupport.swift from the OS X framework [\#1055](https://github.com/realm/realm-cocoa/pull/1055) ([tgoyne](https://github.com/tgoyne))

- Update for Xcode 6.1 [\#1053](https://github.com/realm/realm-cocoa/pull/1053) ([tgoyne](https://github.com/tgoyne))

- Add checks for nested Swift classes [\#1043](https://github.com/realm/realm-cocoa/pull/1043) ([tgoyne](https://github.com/tgoyne))

- Partial updates when calling createOrUpdate [\#1042](https://github.com/realm/realm-cocoa/pull/1042) ([alazier](https://github.com/alazier))

- \[RubyMotion\] Specify the Realm framework as a framework instead. [\#1041](https://github.com/realm/realm-cocoa/pull/1041) ([jpsim](https://github.com/jpsim))

- Fix crash in RLMSuperSet [\#1040](https://github.com/realm/realm-cocoa/pull/1040) ([tgoyne](https://github.com/tgoyne))

- Re-enable transaction rollback [\#1032](https://github.com/realm/realm-cocoa/pull/1032) ([tgoyne](https://github.com/tgoyne))

- Update to core 0.85.0 [\#1031](https://github.com/realm/realm-cocoa/pull/1031) ([tgoyne](https://github.com/tgoyne))

- Working in-memory Realms [\#1030](https://github.com/realm/realm-cocoa/pull/1030) ([alazier](https://github.com/alazier))

- Auto migration [\#1026](https://github.com/realm/realm-cocoa/pull/1026) ([alazier](https://github.com/alazier))

- Speed up creating RLMRealm instances on background threads [\#1023](https://github.com/realm/realm-cocoa/pull/1023) ([tgoyne](https://github.com/tgoyne))

- Update RLMResults comments [\#1021](https://github.com/realm/realm-cocoa/pull/1021) ([dismory](https://github.com/dismory))

- Add method to clear a Realm [\#1017](https://github.com/realm/realm-cocoa/pull/1017) ([alazier](https://github.com/alazier))

- build browser when running "verify" [\#1014](https://github.com/realm/realm-cocoa/pull/1014) ([jpsim](https://github.com/jpsim))

- Fix errors when rearranging properties in model classes [\#1011](https://github.com/realm/realm-cocoa/pull/1011) ([tgoyne](https://github.com/tgoyne))

- Browser fixes for RLMResults [\#1010](https://github.com/realm/realm-cocoa/pull/1010) ([alazier](https://github.com/alazier))

- Add tests for schema init with inheritance [\#1009](https://github.com/realm/realm-cocoa/pull/1009) ([tgoyne](https://github.com/tgoyne))

- Avoid extra objectSchema lookup [\#1008](https://github.com/realm/realm-cocoa/pull/1008) ([hectr](https://github.com/hectr))

- Make the performance tests a bit more useful [\#1006](https://github.com/realm/realm-cocoa/pull/1006) ([tgoyne](https://github.com/tgoyne))

- Rename addObjectsFromArray to addObjects [\#1004](https://github.com/realm/realm-cocoa/pull/1004) ([alazier](https://github.com/alazier))

- Split RLMArray into RLMArray + RLMResults [\#993](https://github.com/realm/realm-cocoa/pull/993) ([alazier](https://github.com/alazier))

- Implement generic List properties [\#985](https://github.com/realm/realm-cocoa/pull/985) ([tgoyne](https://github.com/tgoyne))

- Implement querying array properties [\#897](https://github.com/realm/realm-cocoa/pull/897) ([tgoyne](https://github.com/tgoyne))

- Enable indexing string primary keys [\#888](https://github.com/realm/realm-cocoa/pull/888) ([tgoyne](https://github.com/tgoyne))

## [v0.86.3](https://github.com/realm/realm-cocoa/tree/v0.86.3) (2014-10-09)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.86.2...v0.86.3)

**Closed issues:**

- Schema reports wrong class for property when using base class [\#996](https://github.com/realm/realm-cocoa/issues/996)

- Best way to get RLMArray of just inserted objects [\#995](https://github.com/realm/realm-cocoa/issues/995)

- Realm not persisting changes to nested relationships [\#990](https://github.com/realm/realm-cocoa/issues/990)

- How do I set a auto increment key in Realm? [\#987](https://github.com/realm/realm-cocoa/issues/987)

- Automated Testing \( Grunt \) [\#984](https://github.com/realm/realm-cocoa/issues/984)

- Should inserting multiple newly created objects in relationship with each other to Realm in one transaction throw an exception? [\#983](https://github.com/realm/realm-cocoa/issues/983)

- Group By / Sections / Distinct Values  [\#982](https://github.com/realm/realm-cocoa/issues/982)

- Swift objectForPrimaryKey doesn't support failable initialization [\#977](https://github.com/realm/realm-cocoa/issues/977)

- Running unit tests using XCTest throws migration exception [\#974](https://github.com/realm/realm-cocoa/issues/974)

- Cannot open Realm Browser [\#970](https://github.com/realm/realm-cocoa/issues/970)

- Can't build app with 0.86.0 [\#969](https://github.com/realm/realm-cocoa/issues/969)

- deleteObject is causing EXC\_BAD\_ACCESS  [\#963](https://github.com/realm/realm-cocoa/issues/963)

**Merged pull requests:**

- Fix another use of className that could cause init order issues [\#999](https://github.com/realm/realm-cocoa/pull/999) ([tgoyne](https://github.com/tgoyne))

- Allow creation of dynamic objects and array mutation with dynamic objects [\#992](https://github.com/realm/realm-cocoa/pull/992) ([alazier](https://github.com/alazier))

- Re-adding an object to its Realm is once again a no-op [\#991](https://github.com/realm/realm-cocoa/pull/991) ([alazier](https://github.com/alazier))

- Add support for != in queries on links [\#986](https://github.com/realm/realm-cocoa/pull/986) ([tgoyne](https://github.com/tgoyne))

- Improve examples packaging [\#980](https://github.com/realm/realm-cocoa/pull/980) ([jpsim](https://github.com/jpsim))

- run device tests on CI [\#979](https://github.com/realm/realm-cocoa/pull/979) ([jpsim](https://github.com/jpsim))

- Implement sorting arrays by multiple columns at once [\#978](https://github.com/realm/realm-cocoa/pull/978) ([tgoyne](https://github.com/tgoyne))

- Update "iOS Device Tests" to work [\#976](https://github.com/realm/realm-cocoa/pull/976) ([jpsim](https://github.com/jpsim))

## [v0.86.2](https://github.com/realm/realm-cocoa/tree/v0.86.2) (2014-10-06)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.86.1...v0.86.2)

**Closed issues:**

- RLMObject-subclass is added to realm if relationship is set. [\#968](https://github.com/realm/realm-cocoa/issues/968)

- \_backArray = nil [\#961](https://github.com/realm/realm-cocoa/issues/961)

- Passing RLMObjects Between Threads [\#946](https://github.com/realm/realm-cocoa/issues/946)

- Unable to link the project with Xcode 6 GM [\#909](https://github.com/realm/realm-cocoa/issues/909)

## [v0.86.1](https://github.com/realm/realm-cocoa/tree/v0.86.1) (2014-10-03)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.86.0...v0.86.1)

**Merged pull requests:**

- Get the accessor class name from the schema rather than the className method [\#966](https://github.com/realm/realm-cocoa/pull/966) ([tgoyne](https://github.com/tgoyne))

- added Swift/RLMSupport.swift to zip release [\#965](https://github.com/realm/realm-cocoa/pull/965) ([jpsim](https://github.com/jpsim))

## [v0.86.0](https://github.com/realm/realm-cocoa/tree/v0.86.0) (2014-10-03)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.85.0...v0.86.0)

**Implemented enhancements:**

- Add support for object refetch [\#754](https://github.com/realm/realm-cocoa/issues/754)

- RLMObject as a parent parent class [\#652](https://github.com/realm/realm-cocoa/issues/652)

**Fixed bugs:**

- XCode6 GM : Can't persist property 'hash' with incompatible type [\#905](https://github.com/realm/realm-cocoa/issues/905)

**Closed issues:**

- Not valid signature [\#960](https://github.com/realm/realm-cocoa/issues/960)

- Cannot init a class object [\#952](https://github.com/realm/realm-cocoa/issues/952)

- Query a many-to-many relationship [\#950](https://github.com/realm/realm-cocoa/issues/950)

- Implementing `updateInDefaultRealmWithObject`? [\#943](https://github.com/realm/realm-cocoa/issues/943)

- NSString to NSInteger [\#939](https://github.com/realm/realm-cocoa/issues/939)

- How do I find my .realm to use with the Realm browser? [\#936](https://github.com/realm/realm-cocoa/issues/936)

- realmWithPath method crashes [\#933](https://github.com/realm/realm-cocoa/issues/933)

- Why my Realm database is so large? [\#931](https://github.com/realm/realm-cocoa/issues/931)

- NSNull and Nil in JSON should be ignored instead of causing an exception to be raised [\#928](https://github.com/realm/realm-cocoa/issues/928)

- Calling `-description` on deleted Realm Object will throw exceptions [\#926](https://github.com/realm/realm-cocoa/issues/926)

- Support of 64bit integer [\#925](https://github.com/realm/realm-cocoa/issues/925)

- Case Insensitive RLMObject.objectsWhere [\#912](https://github.com/realm/realm-cocoa/issues/912)

- Wrong property type `RLMPropertyTypeAny` [\#910](https://github.com/realm/realm-cocoa/issues/910)

- Issue while installing via CocoaPods [\#908](https://github.com/realm/realm-cocoa/issues/908)

- Realm does not support subclassing from RLMObject subclasses [\#906](https://github.com/realm/realm-cocoa/issues/906)

- Server side/backend for realm [\#903](https://github.com/realm/realm-cocoa/issues/903)

- Threading issues with MapKit [\#899](https://github.com/realm/realm-cocoa/issues/899)

- Duplicate definitions when integrating Realm \(0.84.0\) from CocoaPods [\#890](https://github.com/realm/realm-cocoa/issues/890)

- Swift app not finding RLMObject subclasses for a property that's an RLMObject [\#855](https://github.com/realm/realm-cocoa/issues/855)

- Crashes on iPhone 5s iOS 7.1.1  [\#841](https://github.com/realm/realm-cocoa/issues/841)

- crash using RLMArray maxOfPropery after objects are added [\#818](https://github.com/realm/realm-cocoa/issues/818)

**Merged pull requests:**

- Update to core version 0.84.0 [\#962](https://github.com/realm/realm-cocoa/pull/962) ([tgoyne](https://github.com/tgoyne))

- Made a computed convenience property readonly [\#958](https://github.com/realm/realm-cocoa/pull/958) ([GreatApe](https://github.com/GreatApe))

- Add `+\[RLMObject objectWithKey:\]` [\#957](https://github.com/realm/realm-cocoa/pull/957) ([tgoyne](https://github.com/tgoyne))

- Throw an exception on NSData columns larger than can be stored [\#956](https://github.com/realm/realm-cocoa/pull/956) ([tgoyne](https://github.com/tgoyne))

- Fixes for using IN on array properties [\#955](https://github.com/realm/realm-cocoa/pull/955) ([tgoyne](https://github.com/tgoyne))

- small tweaks to changelog [\#954](https://github.com/realm/realm-cocoa/pull/954) ([jpsim](https://github.com/jpsim))

- Fix for transposed error messages [\#953](https://github.com/realm/realm-cocoa/pull/953) ([alazier](https://github.com/alazier))

- Abstraction of the difference between when we are showing an array or a ... [\#951](https://github.com/realm/realm-cocoa/pull/951) ([GreatApe](https://github.com/GreatApe))

- Only run Realm update checker if min required iOS version is \>= iOS 7.0 [\#948](https://github.com/realm/realm-cocoa/pull/948) ([jpsim](https://github.com/jpsim))

- Eliminate a Query deep copy when constructing RLMArrayTableView [\#944](https://github.com/realm/realm-cocoa/pull/944) ([tgoyne](https://github.com/tgoyne))

- Add a test for query chaining [\#942](https://github.com/realm/realm-cocoa/pull/942) ([tgoyne](https://github.com/tgoyne))

- Don't throw an exception when -description is called on a deleted object [\#941](https://github.com/realm/realm-cocoa/pull/941) ([tgoyne](https://github.com/tgoyne))

- Support subclassing RLMObjects [\#940](https://github.com/realm/realm-cocoa/pull/940) ([alazier](https://github.com/alazier))

- improve IN operator predicate coverage [\#937](https://github.com/realm/realm-cocoa/pull/937) ([jpsim](https://github.com/jpsim))

- elaborate docs on RLMPropertyAttributeIndexed [\#934](https://github.com/realm/realm-cocoa/pull/934) ([jpsim](https://github.com/jpsim))

- Fix for NSNull with default values [\#932](https://github.com/realm/realm-cocoa/pull/932) ([alazier](https://github.com/alazier))

- Gk browser navigation workaround [\#929](https://github.com/realm/realm-cocoa/pull/929) ([GreatApe](https://github.com/GreatApe))

- XCode6 support with releasable framework, Remove support for XCode5 [\#924](https://github.com/realm/realm-cocoa/pull/924) ([alazier](https://github.com/alazier))

- Gk browser export models [\#923](https://github.com/realm/realm-cocoa/pull/923) ([GreatApe](https://github.com/GreatApe))

- Plugin now also adds a menu item in the file menu to open the Browser [\#922](https://github.com/realm/realm-cocoa/pull/922) ([GreatApe](https://github.com/GreatApe))

- Fix for nested objects where some do not have primary keys [\#920](https://github.com/realm/realm-cocoa/pull/920) ([alazier](https://github.com/alazier))

- Sort linkviews [\#918](https://github.com/realm/realm-cocoa/pull/918) ([alazier](https://github.com/alazier))

- Get the version in a way that actually works with Xcode 5 [\#917](https://github.com/realm/realm-cocoa/pull/917) ([tgoyne](https://github.com/tgoyne))

- Automatically ignore readonly properties [\#916](https://github.com/realm/realm-cocoa/pull/916) ([tgoyne](https://github.com/tgoyne))

- Shows tooltips with statistics in the column headers [\#915](https://github.com/realm/realm-cocoa/pull/915) ([GreatApe](https://github.com/GreatApe))

- Improve insertion performance a bit [\#914](https://github.com/realm/realm-cocoa/pull/914) ([tgoyne](https://github.com/tgoyne))

- Add the release packaging scripts to build.sh [\#911](https://github.com/realm/realm-cocoa/pull/911) ([tgoyne](https://github.com/tgoyne))

- Fixes so that editing a realm in two different windows works as expected... [\#891](https://github.com/realm/realm-cocoa/pull/891) ([GreatApe](https://github.com/GreatApe))

- Don't allow passing persisted objects to -\[RLMRealm addObject:\] [\#886](https://github.com/realm/realm-cocoa/pull/886) ([tgoyne](https://github.com/tgoyne))

## [v0.85.0](https://github.com/realm/realm-cocoa/tree/v0.85.0) (2014-09-16)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.84.0...v0.85.0)

**Fixed bugs:**

- Two equal RLMObject instances have different hash [\#810](https://github.com/realm/realm-cocoa/issues/810)

- Getting the count on a RLMArray causes EXE\_BAD\_ACCESS [\#789](https://github.com/realm/realm-cocoa/issues/789)

**Closed issues:**

- \[Error compiling -- Realm  \(was 0.84.0\)\] No member named 'make\_unique' in namespace 'std'" for xcode 5.0 [\#907](https://github.com/realm/realm-cocoa/issues/907)

- RLMObject subclasses can't be used as optional properties in swift [\#898](https://github.com/realm/realm-cocoa/issues/898)

- Tracking updated, deleted, and inserted objects/properties [\#874](https://github.com/realm/realm-cocoa/issues/874)

- How to shut down an instance Realm and remove its file from disk properly? [\#863](https://github.com/realm/realm-cocoa/issues/863)

- 'ClassX' is not supported as an RLMObject property. [\#858](https://github.com/realm/realm-cocoa/issues/858)

- add support for arbitrary objects to initWithObject: [\#854](https://github.com/realm/realm-cocoa/issues/854)

- -commitWriteTransaction shouldn't throw when no change was made [\#853](https://github.com/realm/realm-cocoa/issues/853)

- cannot build for OS X [\#849](https://github.com/realm/realm-cocoa/issues/849)

- Schema without Objects in Tests [\#690](https://github.com/realm/realm-cocoa/issues/690)

**Merged pull requests:**

- Rewrite the Swift support to work with iOS 7 [\#901](https://github.com/realm/realm-cocoa/pull/901) ([tgoyne](https://github.com/tgoyne))

- Fix compilation with the Xcode 6 GM [\#896](https://github.com/realm/realm-cocoa/pull/896) ([tgoyne](https://github.com/tgoyne))

- Upgrade core library version 0.82.3 -\> 0.83.0 [\#895](https://github.com/realm/realm-cocoa/pull/895) ([kspangsege](https://github.com/kspangsege))

- Gk browser fix lock icon [\#893](https://github.com/realm/realm-cocoa/pull/893) ([GreatApe](https://github.com/GreatApe))

- Fixes merging artefact, three lines were accidentally duplicated [\#892](https://github.com/realm/realm-cocoa/pull/892) ([GreatApe](https://github.com/GreatApe))

- Upgrade core library version 0.82.2 -\> 0.82.3 [\#887](https://github.com/realm/realm-cocoa/pull/887) ([kspangsege](https://github.com/kspangsege))

- Gk browser Alexander feedback 1 [\#885](https://github.com/realm/realm-cocoa/pull/885) ([GreatApe](https://github.com/GreatApe))

- Make the core version check case-insensitive [\#883](https://github.com/realm/realm-cocoa/pull/883) ([tgoyne](https://github.com/tgoyne))

- clarified docs for minOfProperty: and maxOfProperty: to reflect its support for NSDate properties [\#882](https://github.com/realm/realm-cocoa/pull/882) ([jpsim](https://github.com/jpsim))

- Avoid holding a strong reference to RLMRealms for notifications [\#881](https://github.com/realm/realm-cocoa/pull/881) ([tgoyne](https://github.com/tgoyne))

- Gk browser find realm files [\#880](https://github.com/realm/realm-cocoa/pull/880) ([GreatApe](https://github.com/GreatApe))

- New examples structure and packaging [\#879](https://github.com/realm/realm-cocoa/pull/879) ([jpsim](https://github.com/jpsim))

- Add a basic update checker [\#877](https://github.com/realm/realm-cocoa/pull/877) ([tgoyne](https://github.com/tgoyne))

- Add full support for sized Ints in Swift [\#876](https://github.com/realm/realm-cocoa/pull/876) ([tgoyne](https://github.com/tgoyne))

- Fix for last race condition [\#873](https://github.com/realm/realm-cocoa/pull/873) ([alazier](https://github.com/alazier))

- Fix for posible race conditions in tests [\#872](https://github.com/realm/realm-cocoa/pull/872) ([alazier](https://github.com/alazier))

- Extract duplicated code in setter creation [\#871](https://github.com/realm/realm-cocoa/pull/871) ([tgoyne](https://github.com/tgoyne))

- refactored RLMUpdateQueryWithPredicate to only handle NSPredicates [\#869](https://github.com/realm/realm-cocoa/pull/869) ([jpsim](https://github.com/jpsim))

- Primary key support for int and string columns [\#868](https://github.com/realm/realm-cocoa/pull/868) ([alazier](https://github.com/alazier))

- Build the Swift examples project in c++14 mode [\#867](https://github.com/realm/realm-cocoa/pull/867) ([tgoyne](https://github.com/tgoyne))

- Allow literals to use object with kvc properties [\#866](https://github.com/realm/realm-cocoa/pull/866) ([alazier](https://github.com/alazier))

- Improve attributesForProperty: documentation [\#865](https://github.com/realm/realm-cocoa/pull/865) ([tgoyne](https://github.com/tgoyne))

- Clean-up TableView verification [\#864](https://github.com/realm/realm-cocoa/pull/864) ([alazier](https://github.com/alazier))

- fixed build.sh examples [\#861](https://github.com/realm/realm-cocoa/pull/861) ([jpsim](https://github.com/jpsim))

- Add the name of the class in the missing property value exception [\#860](https://github.com/realm/realm-cocoa/pull/860) ([tgoyne](https://github.com/tgoyne))

- Update to Xcode6-Beta7 [\#859](https://github.com/realm/realm-cocoa/pull/859) ([tgoyne](https://github.com/tgoyne))

- Gk browser columnindex out of bounds fix [\#857](https://github.com/realm/realm-cocoa/pull/857) ([GreatApe](https://github.com/GreatApe))

- Gk browser tooltip fix [\#856](https://github.com/realm/realm-cocoa/pull/856) ([GreatApe](https://github.com/GreatApe))

- Gk browser right click link [\#852](https://github.com/realm/realm-cocoa/pull/852) ([GreatApe](https://github.com/GreatApe))

- Gk browser index in array column [\#851](https://github.com/realm/realm-cocoa/pull/851) ([GreatApe](https://github.com/GreatApe))

- Don't materialize the TableView for a query just to get the count [\#850](https://github.com/realm/realm-cocoa/pull/850) ([tgoyne](https://github.com/tgoyne))

- Implement read-only realms [\#846](https://github.com/realm/realm-cocoa/pull/846) ([tgoyne](https://github.com/tgoyne))

- Gk browser better data generator [\#845](https://github.com/realm/realm-cocoa/pull/845) ([GreatApe](https://github.com/GreatApe))

- Split the notifications into DidChange and RefreshNeeded [\#829](https://github.com/realm/realm-cocoa/pull/829) ([tgoyne](https://github.com/tgoyne))

- Support for Xcode6-Beta6 \(Realm-Xcode6 and RealmSwiftExamples\) [\#814](https://github.com/realm/realm-cocoa/pull/814) ([jpsim](https://github.com/jpsim))

## [v0.84.0](https://github.com/realm/realm-cocoa/tree/v0.84.0) (2014-08-28)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.83.0...v0.84.0)

**Implemented enhancements:**

- Deserializing JSON issue [\#816](https://github.com/realm/realm-cocoa/issues/816)

- Ambiguities in the documentation  [\#781](https://github.com/realm/realm-cocoa/issues/781)

- Add support for IN predicate [\#748](https://github.com/realm/realm-cocoa/issues/748)

**Fixed bugs:**

- Use of underscore notation breaks Realm \(documentation omission\) [\#672](https://github.com/realm/realm-cocoa/issues/672)

- 'RLMException', reason: 'mmap\(\) failed [\#620](https://github.com/realm/realm-cocoa/issues/620)

**Closed issues:**

- Release more often [\#848](https://github.com/realm/realm-cocoa/issues/848)

- 'Unsupported predicate value type', reason: 'Object type any not supported' [\#817](https://github.com/realm/realm-cocoa/issues/817)

- Build fails w/ XCode6 Beta6 [\#813](https://github.com/realm/realm-cocoa/issues/813)

- Properties starting with 'z' cannot be setted [\#809](https://github.com/realm/realm-cocoa/issues/809)

- How to figure out whether an once attached `RLMObject` instance is detached recently or not [\#803](https://github.com/realm/realm-cocoa/issues/803)

- What's "RLMStandalone\_"? [\#800](https://github.com/realm/realm-cocoa/issues/800)

- Using Swift with iOS deployment target 7.0 [\#700](https://github.com/realm/realm-cocoa/issues/700)

- How do I limit fetch result count when using realm? [\#689](https://github.com/realm/realm-cocoa/issues/689)

**Merged pull requests:**

- Upgrade core library version 0.82.1 -\> 0.82.2 [\#847](https://github.com/realm/realm-cocoa/pull/847) ([kspangsege](https://github.com/kspangsege))

- Document RLMRealm lifetimes and related issues [\#844](https://github.com/realm/realm-cocoa/pull/844) ([tgoyne](https://github.com/tgoyne))

- updated CONTRIBUTING.md with guides to filing issues and contributing code [\#843](https://github.com/realm/realm-cocoa/pull/843) ([jpsim](https://github.com/jpsim))

- Actually report failure from build.sh when a test fails [\#842](https://github.com/realm/realm-cocoa/pull/842) ([tgoyne](https://github.com/tgoyne))

- Perform queries on demand [\#839](https://github.com/realm/realm-cocoa/pull/839) ([alazier](https://github.com/alazier))

- Change how Realm in linked into TestHost [\#834](https://github.com/realm/realm-cocoa/pull/834) ([tgoyne](https://github.com/tgoyne))

- Minor docfix: mentioning that array has to be in right order [\#832](https://github.com/realm/realm-cocoa/pull/832) ([astigsen](https://github.com/astigsen))

- Upgrade core library version 0.82.0 -\> 0.82.1 [\#831](https://github.com/realm/realm-cocoa/pull/831) ([kspangsege](https://github.com/kspangsege))

- Improve the RLMRealm documentation a bit [\#828](https://github.com/realm/realm-cocoa/pull/828) ([tgoyne](https://github.com/tgoyne))

- Gk browser save ui coords [\#825](https://github.com/realm/realm-cocoa/pull/825) ([GreatApe](https://github.com/GreatApe))

- Gk browser align classnames [\#821](https://github.com/realm/realm-cocoa/pull/821) ([GreatApe](https://github.com/GreatApe))

- Revert "Updating to XCode 6 beta 6" [\#820](https://github.com/realm/realm-cocoa/pull/820) ([kneth](https://github.com/kneth))

- Updating to XCode 6 beta 6 [\#819](https://github.com/realm/realm-cocoa/pull/819) ([kneth](https://github.com/kneth))

- Don't claim that autorefresh is off by default on background threads [\#815](https://github.com/realm/realm-cocoa/pull/815) ([tgoyne](https://github.com/tgoyne))

- Support setting model properties starting with the letter 'z' [\#812](https://github.com/realm/realm-cocoa/pull/812) ([jpsim](https://github.com/jpsim))

- Assert the token's block is not nil and check it before execution [\#811](https://github.com/realm/realm-cocoa/pull/811) ([dismory](https://github.com/dismory))

- Fix for unexpected notifications when creating background RLMRealms [\#807](https://github.com/realm/realm-cocoa/pull/807) ([alazier](https://github.com/alazier))

- Extract some duplicated query building logic and add support for multi-level link queries [\#806](https://github.com/realm/realm-cocoa/pull/806) ([tgoyne](https://github.com/tgoyne))

- Add isDeleted method to RLMObject [\#805](https://github.com/realm/realm-cocoa/pull/805) ([alazier](https://github.com/alazier))

- Copy `\_notificationHandlers ` in case it is mutated while being enumerated [\#804](https://github.com/realm/realm-cocoa/pull/804) ([dismory](https://github.com/dismory))

- Gk browser launch issues [\#802](https://github.com/realm/realm-cocoa/pull/802) ([GreatApe](https://github.com/GreatApe))

- Handle object cycles in -description. [\#798](https://github.com/realm/realm-cocoa/pull/798) ([tgoyne](https://github.com/tgoyne))

- Don't sync table views while iterating over them [\#797](https://github.com/realm/realm-cocoa/pull/797) ([tgoyne](https://github.com/tgoyne))

- Implement IN and BETWEEN for link queries [\#795](https://github.com/realm/realm-cocoa/pull/795) ([tgoyne](https://github.com/tgoyne))

- Fix sign comparison warnings [\#793](https://github.com/realm/realm-cocoa/pull/793) ([tgoyne](https://github.com/tgoyne))

- Gk browser remove from array [\#792](https://github.com/realm/realm-cocoa/pull/792) ([GreatApe](https://github.com/GreatApe))

- Make functions which do not need to be exported static [\#791](https://github.com/realm/realm-cocoa/pull/791) ([tgoyne](https://github.com/tgoyne))

- Use set -e for build.sh rather than manually checking each exit code [\#790](https://github.com/realm/realm-cocoa/pull/790) ([tgoyne](https://github.com/tgoyne))

- Using “type \*var” instead of “type \* var”. [\#787](https://github.com/realm/realm-cocoa/pull/787) ([kneth](https://github.com/kneth))

- Lower deployment target for Swift samples to iOS 7.1 [\#780](https://github.com/realm/realm-cocoa/pull/780) ([tgoyne](https://github.com/tgoyne))

- Implement the IN operator for predicates [\#778](https://github.com/realm/realm-cocoa/pull/778) ([tgoyne](https://github.com/tgoyne))

- Rework the podspec [\#761](https://github.com/realm/realm-cocoa/pull/761) ([tgoyne](https://github.com/tgoyne))

- The main window is now view based [\#756](https://github.com/realm/realm-cocoa/pull/756) ([GreatApe](https://github.com/GreatApe))

- Object links and minor refactoring [\#736](https://github.com/realm/realm-cocoa/pull/736) ([GreatApe](https://github.com/GreatApe))

- Don't download the core when a local build is present [\#712](https://github.com/realm/realm-cocoa/pull/712) ([tgoyne](https://github.com/tgoyne))

## [v0.83.0](https://github.com/realm/realm-cocoa/tree/v0.83.0) (2014-08-13)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.82.0...v0.83.0)

**Closed issues:**

- Compile errors with Swift with the Xcode 6 beta 5 [\#757](https://github.com/realm/realm-cocoa/issues/757)

- -\[RLMObject initWithObject:\] throws cryptic exception on missing properties [\#752](https://github.com/realm/realm-cocoa/issues/752)

- Realm crashing on iOs 8 beta 5 [\#750](https://github.com/realm/realm-cocoa/issues/750)

- RLMArray in Swift has empty backing array [\#746](https://github.com/realm/realm-cocoa/issues/746)

- New iOS 8 beta 5 changes in Swift [\#733](https://github.com/realm/realm-cocoa/issues/733)

- Use of undeclared identifier 'RLMSwiftSupport' [\#731](https://github.com/realm/realm-cocoa/issues/731)

- Linker error "ld: library not found for -lc++" [\#725](https://github.com/realm/realm-cocoa/issues/725)

**Merged pull requests:**

- Revert "Merge pull request \#770 from realm/al-sort-linkview" [\#783](https://github.com/realm/realm-cocoa/pull/783) ([emanuelez](https://github.com/emanuelez))

- Fix for incorrect macro [\#779](https://github.com/realm/realm-cocoa/pull/779) ([alazier](https://github.com/alazier))

- Explicitly autorelease realms returned from RLMRealm class methods [\#776](https://github.com/realm/realm-cocoa/pull/776) ([tgoyne](https://github.com/tgoyne))

- fixes for compiler warnings in tests [\#775](https://github.com/realm/realm-cocoa/pull/775) ([alazier](https://github.com/alazier))

- Allow 0 and 1 to be used as bools in predicates [\#772](https://github.com/realm/realm-cocoa/pull/772) ([tgoyne](https://github.com/tgoyne))

- Add support for literal ranges to BETWEEN predicates [\#771](https://github.com/realm/realm-cocoa/pull/771) ([tgoyne](https://github.com/tgoyne))

- Support sorting LinkView arrays [\#770](https://github.com/realm/realm-cocoa/pull/770) ([alazier](https://github.com/alazier))

- Reject invalid subclassing of RLMObjects at schema generation time [\#769](https://github.com/realm/realm-cocoa/pull/769) ([tgoyne](https://github.com/tgoyne))

- Add a test for setting default values when initializing from a dictionary with nulls [\#768](https://github.com/realm/realm-cocoa/pull/768) ([tgoyne](https://github.com/tgoyne))

- Fix for long predicate comparisons with large numbers [\#767](https://github.com/realm/realm-cocoa/pull/767) ([alazier](https://github.com/alazier))

- Allow arrays and object properties to be missing when initializing from a dictionary [\#760](https://github.com/realm/realm-cocoa/pull/760) ([tgoyne](https://github.com/tgoyne))

- Throw an exception when objects are used on the wrong thread [\#759](https://github.com/realm/realm-cocoa/pull/759) ([tgoyne](https://github.com/tgoyne))

- Add some performance tests and support for running them on devices [\#758](https://github.com/realm/realm-cocoa/pull/758) ([tgoyne](https://github.com/tgoyne))

- Corrected Xcode Beta version [\#755](https://github.com/realm/realm-cocoa/pull/755) ([bagvendt](https://github.com/bagvendt))

- Improve error message for invalid literals [\#753](https://github.com/realm/realm-cocoa/pull/753) ([alazier](https://github.com/alazier))

- Initialize array properties on standalone Swift RLMObject subclasses [\#751](https://github.com/realm/realm-cocoa/pull/751) ([tgoyne](https://github.com/tgoyne))

- Removing commented out and unused code [\#747](https://github.com/realm/realm-cocoa/pull/747) ([oleks](https://github.com/oleks))

- Support nil object queries [\#745](https://github.com/realm/realm-cocoa/pull/745) ([alazier](https://github.com/alazier))

- More tests for deleting array children [\#744](https://github.com/realm/realm-cocoa/pull/744) ([alazier](https://github.com/alazier))

- Sort the project files [\#743](https://github.com/realm/realm-cocoa/pull/743) ([tgoyne](https://github.com/tgoyne))

- Fix a memory leak when querying tables [\#742](https://github.com/realm/realm-cocoa/pull/742) ([tgoyne](https://github.com/tgoyne))

- Update Swift code for Xcode 6 beta 5 [\#734](https://github.com/realm/realm-cocoa/pull/734) ([tgoyne](https://github.com/tgoyne))

## [v0.82.0](https://github.com/realm/realm-cocoa/tree/v0.82.0) (2014-08-05)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.81.0...v0.82.0)

**Fixed bugs:**

- Missing Realm-Bridging-Header.h using Cocoapods [\#763](https://github.com/realm/realm-cocoa/issues/763)

- RLMArray -description broken for empty arrays [\#673](https://github.com/realm/realm-cocoa/issues/673)

- Relationships Broken in Swift - Xcode 6b4 [\#668](https://github.com/realm/realm-cocoa/issues/668)

**Closed issues:**

- BOOL properties with custom getter [\#732](https://github.com/realm/realm-cocoa/issues/732)

- header 'Realm-Swift.h' not found when archive in swift project [\#726](https://github.com/realm/realm-cocoa/issues/726)

- Swift/Xcode6-Beta4 Archive 'Release' build fails [\#717](https://github.com/realm/realm-cocoa/issues/717)

- null field in JSON without matching property in RLMObject throws exception [\#716](https://github.com/realm/realm-cocoa/issues/716)

- Custom getters [\#699](https://github.com/realm/realm-cocoa/issues/699)

- Integer properties on Swift are handled as 32bits [\#688](https://github.com/realm/realm-cocoa/issues/688)

- When implementing ignoredProperties on Swift, the schema ends up invalid [\#686](https://github.com/realm/realm-cocoa/issues/686)

- Realm-Bridging-Header.h Not Distributed with Pod [\#685](https://github.com/realm/realm-cocoa/issues/685)

- Querying for max value [\#684](https://github.com/realm/realm-cocoa/issues/684)

- Allow not only immediate subclasses of RLMObject [\#683](https://github.com/realm/realm-cocoa/issues/683)

- Minimum iOS requirement? Unable to build w/ iOS7 [\#682](https://github.com/realm/realm-cocoa/issues/682)

- Getting "ld: framework not found Realm" error by using cocoapods [\#667](https://github.com/realm/realm-cocoa/issues/667)

- String comparison in queries fail for strings containing certain characters [\#664](https://github.com/realm/realm-cocoa/issues/664)

- Realm browser open file error [\#655](https://github.com/realm/realm-cocoa/issues/655)

- Swift Project - File not Found "Realm/Realm-Bridging-Header.h"  [\#653](https://github.com/realm/realm-cocoa/issues/653)

- Xcode 6 Beta 4 - Update to swift language [\#638](https://github.com/realm/realm-cocoa/issues/638)

**Merged pull requests:**

- Temporary fix for casting issue in core [\#740](https://github.com/realm/realm-cocoa/pull/740) ([alazier](https://github.com/alazier))

- Update changelog for core version bump [\#739](https://github.com/realm/realm-cocoa/pull/739) ([tgoyne](https://github.com/tgoyne))

- Upgrade core library version 0.80.4 -\> 0.80.5 [\#737](https://github.com/realm/realm-cocoa/pull/737) ([kspangsege](https://github.com/kspangsege))

- Use placeholders in templates and update docs [\#729](https://github.com/realm/realm-cocoa/pull/729) ([cbess](https://github.com/cbess))

- Disable refresh timer for ios - Support disabling autorefresh [\#728](https://github.com/realm/realm-cocoa/pull/728) ([alazier](https://github.com/alazier))

- Fix compilation of the browser [\#727](https://github.com/realm/realm-cocoa/pull/727) ([tgoyne](https://github.com/tgoyne))

- Improve the error message when properties are of an invalid type [\#724](https://github.com/realm/realm-cocoa/pull/724) ([tgoyne](https://github.com/tgoyne))

- Don't add a duplicate copy of libtightdb-ios.a to the framework [\#723](https://github.com/realm/realm-cocoa/pull/723) ([tgoyne](https://github.com/tgoyne))

- Fix memory leak when breaking out of a for-in loop [\#722](https://github.com/realm/realm-cocoa/pull/722) ([tgoyne](https://github.com/tgoyne))

- Don't allow framework for the wrong platform to be used [\#721](https://github.com/realm/realm-cocoa/pull/721) ([alazier](https://github.com/alazier))

- Copy tableviews correctly in arraySortedByProperty: [\#720](https://github.com/realm/realm-cocoa/pull/720) ([tgoyne](https://github.com/tgoyne))

- Move the default realm path on OS X to Application Support [\#719](https://github.com/realm/realm-cocoa/pull/719) ([tgoyne](https://github.com/tgoyne))

- Mark -\[RLMArray init\] and +\[RLMArray new\] as unavailable [\#718](https://github.com/realm/realm-cocoa/pull/718) ([tgoyne](https://github.com/tgoyne))

- Fix for standalone RLMArray creation with array literals [\#715](https://github.com/realm/realm-cocoa/pull/715) ([alazier](https://github.com/alazier))

- Add Swift versions of some RLMArray tests [\#714](https://github.com/realm/realm-cocoa/pull/714) ([tgoyne](https://github.com/tgoyne))

- Some equality tests [\#711](https://github.com/realm/realm-cocoa/pull/711) ([oleks](https://github.com/oleks))

- A couple negative objectForKeyedSubscript tests [\#710](https://github.com/realm/realm-cocoa/pull/710) ([oleks](https://github.com/oleks))

- Minor fix to RLMArray -description. [\#707](https://github.com/realm/realm-cocoa/pull/707) ([alazier](https://github.com/alazier))

- Test case for ignoredProperties on Swift. Issue \#686. [\#706](https://github.com/realm/realm-cocoa/pull/706) ([Reflejo](https://github.com/Reflejo))

- Updated CHANGELOG.md with fix from \#701 [\#704](https://github.com/realm/realm-cocoa/pull/704) ([apalancat](https://github.com/apalancat))

- Implement -\[RLMArray indexOfObjectWhere\] and friends [\#702](https://github.com/realm/realm-cocoa/pull/702) ([tgoyne](https://github.com/tgoyne))

- Use custom getter name when adding object to Realm [\#701](https://github.com/realm/realm-cocoa/pull/701) ([apalancat](https://github.com/apalancat))

- Clarified exception message when using ‘IN’ predicate operator \(unsupported\) [\#697](https://github.com/realm/realm-cocoa/pull/697) ([jpsim](https://github.com/jpsim))

- User property name instead of column alignment for standalone accessors [\#696](https://github.com/realm/realm-cocoa/pull/696) ([alazier](https://github.com/alazier))

- Integers in Swift were down casted to 32 bits integers. Fixed \#688 [\#695](https://github.com/realm/realm-cocoa/pull/695) ([Reflejo](https://github.com/Reflejo))

- Added \[RLMRealm defaultRealmPath\] [\#681](https://github.com/realm/realm-cocoa/pull/681) ([jpsim](https://github.com/jpsim))

- Fixed how Xcode6 iOS framework is combined into a fat framework [\#679](https://github.com/realm/realm-cocoa/pull/679) ([jpsim](https://github.com/jpsim))

- When ignoredProperties is overridden on Swift, the schema ends up invalid [\#678](https://github.com/realm/realm-cocoa/pull/678) ([Reflejo](https://github.com/Reflejo))

- Use of tightdb::TableRef improved in various places [\#676](https://github.com/realm/realm-cocoa/pull/676) ([kspangsege](https://github.com/kspangsege))

- Minor fix to RLMArray -description. [\#675](https://github.com/realm/realm-cocoa/pull/675) ([rogernolan](https://github.com/rogernolan))

- Upgrade to use core library version 0.80.4 [\#674](https://github.com/realm/realm-cocoa/pull/674) ([kspangsege](https://github.com/kspangsege))

- Added quoting of some variables [\#671](https://github.com/realm/realm-cocoa/pull/671) ([exsortis](https://github.com/exsortis))

- Updated Swift Syntax PR for Xcode6-Beta4 [\#663](https://github.com/realm/realm-cocoa/pull/663) ([jpsim](https://github.com/jpsim))

- Using NSNumber properties \(unsupported\) now throws a more informative exception [\#662](https://github.com/realm/realm-cocoa/pull/662) ([jpsim](https://github.com/jpsim))

- convert RLM\_ARRAY\_TYPE documentation to appledoc format [\#661](https://github.com/realm/realm-cocoa/pull/661) ([jpsim](https://github.com/jpsim))

- Improve header docs [\#660](https://github.com/realm/realm-cocoa/pull/660) ([jpsim](https://github.com/jpsim))

- Removed RLMSortOrder [\#659](https://github.com/realm/realm-cocoa/pull/659) ([jpsim](https://github.com/jpsim))

- Use CocoaDocs' Dash/DocsForXcode links [\#658](https://github.com/realm/realm-cocoa/pull/658) ([jpsim](https://github.com/jpsim))

- Support Xcode6-Beta4 [\#657](https://github.com/realm/realm-cocoa/pull/657) ([jpsim](https://github.com/jpsim))

- Allow to build with whatever version of core is in the core folder [\#656](https://github.com/realm/realm-cocoa/pull/656) ([emanuelez](https://github.com/emanuelez))

- Be paranoid and unlink build/bin before creating a new symlink [\#654](https://github.com/realm/realm-cocoa/pull/654) ([emanuelez](https://github.com/emanuelez))

- sh build.sh ios{-debug} now builds a universal framework when XCODE\_VERSION=6 [\#648](https://github.com/realm/realm-cocoa/pull/648) ([jpsim](https://github.com/jpsim))

- Implicit casting to float value in predicates [\#643](https://github.com/realm/realm-cocoa/pull/643) ([kneth](https://github.com/kneth))

## [v0.81.0](https://github.com/realm/realm-cocoa/tree/v0.81.0) (2014-07-22)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.80.0...v0.81.0)

**Fixed bugs:**

- Strings a sliced when storing UTF-8 characters [\#612](https://github.com/realm/realm-cocoa/issues/612)

- Chinese support [\#604](https://github.com/realm/realm-cocoa/issues/604)

**Closed issues:**

- RealmSimpleExample versus RealmEncryptionExample. Missing the correct content for RealmSimpleExample in objc.. [\#625](https://github.com/realm/realm-cocoa/issues/625)

- BLOBs [\#624](https://github.com/realm/realm-cocoa/issues/624)

- Support for change set notifications. [\#622](https://github.com/realm/realm-cocoa/issues/622)

- AddObject after DeleteObject  will not success [\#621](https://github.com/realm/realm-cocoa/issues/621)

- Can't predicate over object with relationship  [\#617](https://github.com/realm/realm-cocoa/issues/617)

- Limit the amount of results returned [\#611](https://github.com/realm/realm-cocoa/issues/611)

- Example for implementing default values? [\#608](https://github.com/realm/realm-cocoa/issues/608)

- Add method to perform passed block in a transaction [\#598](https://github.com/realm/realm-cocoa/issues/598)

- \[Docs\] Provide better solution for "unidentified developer" error [\#597](https://github.com/realm/realm-cocoa/issues/597)

- Setup guide - Xcode 6 Beta 3 bug [\#595](https://github.com/realm/realm-cocoa/issues/595)

**Merged pull requests:**

- Use UTF8 \(byte\)length instead of character length. [\#613](https://github.com/realm/realm-cocoa/pull/613) ([oleks](https://github.com/oleks))

- Realm.podspec now lints for 0.81.0 [\#650](https://github.com/realm/realm-cocoa/pull/650) ([jpsim](https://github.com/jpsim))

- Added back SimpleExample's AppDelegate, which was mistakenly overwritten... [\#649](https://github.com/realm/realm-cocoa/pull/649) ([bmunkholm](https://github.com/bmunkholm))

- Getting ready to version 0.81.0 [\#646](https://github.com/realm/realm-cocoa/pull/646) ([kneth](https://github.com/kneth))

- Fixing a few typos in \#639 [\#644](https://github.com/realm/realm-cocoa/pull/644) ([kneth](https://github.com/kneth))

- fix core symlink CI issue [\#641](https://github.com/realm/realm-cocoa/pull/641) ([jpsim](https://github.com/jpsim))

- Upgrade to use core library version 0.80.3 [\#640](https://github.com/realm/realm-cocoa/pull/640) ([kspangsege](https://github.com/kspangsege))

- Support RLMObject and RLMArray predicates comparing on object identity [\#639](https://github.com/realm/realm-cocoa/pull/639) ([alazier](https://github.com/alazier))

- There are a few implicit casts stopping master from successfully testing/building in Realm.xcodeproj [\#637](https://github.com/realm/realm-cocoa/pull/637) ([jpsim](https://github.com/jpsim))

- Add transaction block helper [\#636](https://github.com/realm/realm-cocoa/pull/636) ([alazier](https://github.com/alazier))

- Basic support for link queries [\#635](https://github.com/realm/realm-cocoa/pull/635) ([kneth](https://github.com/kneth))

- Move build.log into the build folder [\#634](https://github.com/realm/realm-cocoa/pull/634) ([emanuelez](https://github.com/emanuelez))

- Move the bin symlink into the build folder [\#633](https://github.com/realm/realm-cocoa/pull/633) ([emanuelez](https://github.com/emanuelez))

- The core folder is now a symlink to a versioned folder [\#632](https://github.com/realm/realm-cocoa/pull/632) ([emanuelez](https://github.com/emanuelez))

- Add OSX support to the podspec file [\#631](https://github.com/realm/realm-cocoa/pull/631) ([emanuelez](https://github.com/emanuelez))

- Rename RealmVisualEditor to RealmBrowser in a consistent way [\#629](https://github.com/realm/realm-cocoa/pull/629) ([emanuelez](https://github.com/emanuelez))

- Add dynamic test, Fix for setting using object subscripting on standalone objects [\#623](https://github.com/realm/realm-cocoa/pull/623) ([alazier](https://github.com/alazier))

- Improved Unicode support and tests [\#619](https://github.com/realm/realm-cocoa/pull/619) ([jpsim](https://github.com/jpsim))

- Fix keyed subscript access for standalone objects [\#616](https://github.com/realm/realm-cocoa/pull/616) ([alazier](https://github.com/alazier))

- Upgrade to use core library version 0.80.2 [\#615](https://github.com/realm/realm-cocoa/pull/615) ([kspangsege](https://github.com/kspangsege))

- Fix a small regression in examples testing [\#614](https://github.com/realm/realm-cocoa/pull/614) ([emanuelez](https://github.com/emanuelez))

- fixed a few things about docs [\#609](https://github.com/realm/realm-cocoa/pull/609) ([jpsim](https://github.com/jpsim))

- Upgrade to use core library version 0.80.1 [\#607](https://github.com/realm/realm-cocoa/pull/607) ([kspangsege](https://github.com/kspangsege))

- Added RubyMotion example [\#606](https://github.com/realm/realm-cocoa/pull/606) ([jpsim](https://github.com/jpsim))

- File/Class templates are now installed for both iOS/OSX [\#600](https://github.com/realm/realm-cocoa/pull/600) ([jpsim](https://github.com/jpsim))

- Fix for crash when double clicking on a .realm file to launch the Realm Browser [\#596](https://github.com/realm/realm-cocoa/pull/596) ([moored](https://github.com/moored))

- updated objc/swift migration examples to use Realm headers [\#593](https://github.com/realm/realm-cocoa/pull/593) ([jpsim](https://github.com/jpsim))

- Fix the podspec file to point to the framework correctly [\#592](https://github.com/realm/realm-cocoa/pull/592) ([emanuelez](https://github.com/emanuelez))

- Our JSON example cannot compile using Xcode 6 [\#590](https://github.com/realm/realm-cocoa/pull/590) ([kneth](https://github.com/kneth))

- added RealmSwiftExamples.xcodeproj [\#582](https://github.com/realm/realm-cocoa/pull/582) ([jpsim](https://github.com/jpsim))

## [v0.80.0](https://github.com/realm/realm-cocoa/tree/v0.80.0) (2014-07-15)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.22.0...v0.80.0)

**Merged pull requests:**

- SimpleExample: Using the new where instead of withPredicateFormat [\#589](https://github.com/realm/realm-cocoa/pull/589) ([kneth](https://github.com/kneth))

- Make the schemes shared for the objc examples [\#588](https://github.com/realm/realm-cocoa/pull/588) ([emanuelez](https://github.com/emanuelez))

- Adding Realm framework as subproject to JSON example [\#587](https://github.com/realm/realm-cocoa/pull/587) ([kneth](https://github.com/kneth))

- Fix the wrong project name for the ObjC simple example [\#586](https://github.com/realm/realm-cocoa/pull/586) ([emanuelez](https://github.com/emanuelez))

- Removed JSONImportExample from README as it will not be distributed yet. [\#585](https://github.com/realm/realm-cocoa/pull/585) ([bmunkholm](https://github.com/bmunkholm))

- the version is the second argument [\#584](https://github.com/realm/realm-cocoa/pull/584) ([kneth](https://github.com/kneth))

- Added back SimpleExample in README [\#583](https://github.com/realm/realm-cocoa/pull/583) ([bmunkholm](https://github.com/bmunkholm))

- Swift doc examples [\#581](https://github.com/realm/realm-cocoa/pull/581) ([alazier](https://github.com/alazier))

- Fixed code snippets in REST doc [\#580](https://github.com/realm/realm-cocoa/pull/580) ([astigsen](https://github.com/astigsen))

- Fixed code snippets and sp mistakes in migration docs [\#579](https://github.com/realm/realm-cocoa/pull/579) ([astigsen](https://github.com/astigsen))

- Re-add simple example [\#578](https://github.com/realm/realm-cocoa/pull/578) ([jpsim](https://github.com/jpsim))

- Minor fixes to docs to make code snippets actually run [\#577](https://github.com/realm/realm-cocoa/pull/577) ([astigsen](https://github.com/astigsen))

- Re-enabled testRealmIsUpdatedImmediatelyAfterBackgroundUpdate for Xcode5 [\#576](https://github.com/realm/realm-cocoa/pull/576) ([jpsim](https://github.com/jpsim))

- Clear realm cache between swift tests [\#575](https://github.com/realm/realm-cocoa/pull/575) ([alazier](https://github.com/alazier))

- Bumped version of browser to 0.80.0 [\#574](https://github.com/realm/realm-cocoa/pull/574) ([bmunkholm](https://github.com/bmunkholm))

- Updated changelog [\#573](https://github.com/realm/realm-cocoa/pull/573) ([bmunkholm](https://github.com/bmunkholm))

- README updates [\#572](https://github.com/realm/realm-cocoa/pull/572) ([bmunkholm](https://github.com/bmunkholm))

- - Changed usages of `WithPredicateFormat` to `Where` [\#571](https://github.com/realm/realm-cocoa/pull/571) ([jpsim](https://github.com/jpsim))

- Made a number of fixes to examples [\#570](https://github.com/realm/realm-cocoa/pull/570) ([jpsim](https://github.com/jpsim))

- Added RealmJSONImportExample and removed RealmPerformanceExample from build.sh [\#569](https://github.com/realm/realm-cocoa/pull/569) ([jpsim](https://github.com/jpsim))

- Fixing minor issues in the new Rest example [\#568](https://github.com/realm/realm-cocoa/pull/568) ([kneth](https://github.com/kneth))

- removed RealmSimpleExample and RealmSwiftSimpleExample [\#567](https://github.com/realm/realm-cocoa/pull/567) ([jpsim](https://github.com/jpsim))

- Documenting targets [\#566](https://github.com/realm/realm-cocoa/pull/566) ([kneth](https://github.com/kneth))

- Set the DerivedData folder path in the build directory [\#565](https://github.com/realm/realm-cocoa/pull/565) ([emanuelez](https://github.com/emanuelez))

- Removed RealmPerformanceExample until it's been heavily refactored and c... [\#564](https://github.com/realm/realm-cocoa/pull/564) ([bmunkholm](https://github.com/bmunkholm))

- Small fix-ups in Getting Started + README [\#563](https://github.com/realm/realm-cocoa/pull/563) ([oleks](https://github.com/oleks))

- Updating samples [\#562](https://github.com/realm/realm-cocoa/pull/562) ([kneth](https://github.com/kneth))

- Make the dependancy to core explicit and formal. [\#561](https://github.com/realm/realm-cocoa/pull/561) ([emanuelez](https://github.com/emanuelez))

- Rewrote the README [\#560](https://github.com/realm/realm-cocoa/pull/560) ([jpsim](https://github.com/jpsim))

- Add method to batch delete from a Realm [\#559](https://github.com/realm/realm-cocoa/pull/559) ([alazier](https://github.com/alazier))

- Data browser updates [\#558](https://github.com/realm/realm-cocoa/pull/558) ([astigsen](https://github.com/astigsen))

- Support object and array literals when initializing/inserting objects [\#557](https://github.com/realm/realm-cocoa/pull/557) ([alazier](https://github.com/alazier))

- Fixed live updating of query results [\#556](https://github.com/realm/realm-cocoa/pull/556) ([astigsen](https://github.com/astigsen))

- Rename migration methods [\#555](https://github.com/realm/realm-cocoa/pull/555) ([alazier](https://github.com/alazier))

- Optimization for fast enumeration [\#554](https://github.com/realm/realm-cocoa/pull/554) ([alazier](https://github.com/alazier))

- re-enabled Sequence-style RLMArray enumeration [\#552](https://github.com/realm/realm-cocoa/pull/552) ([jpsim](https://github.com/jpsim))

- Fixed issue that was preventing us from using our framework in other Xcode projects with Xcode6-Beta3 [\#551](https://github.com/realm/realm-cocoa/pull/551) ([jpsim](https://github.com/jpsim))

- Specific message for RLMArray properties with no protocol [\#548](https://github.com/realm/realm-cocoa/pull/548) ([alazier](https://github.com/alazier))

- Fixed Swift tests in Xcode6-Beta3 by creating TestFramework and adding RLMTestObjects to it [\#546](https://github.com/realm/realm-cocoa/pull/546) ([jpsim](https://github.com/jpsim))

- fixes for core api changes [\#545](https://github.com/realm/realm-cocoa/pull/545) ([alazier](https://github.com/alazier))

- Improvements to various exception messages [\#544](https://github.com/realm/realm-cocoa/pull/544) ([alazier](https://github.com/alazier))

- Get rid of xcode-select and use the right xcodebuild directly. [\#543](https://github.com/realm/realm-cocoa/pull/543) ([emanuelez](https://github.com/emanuelez))

- Fixed Swift tests [\#542](https://github.com/realm/realm-cocoa/pull/542) ([jpsim](https://github.com/jpsim))

- small bug fixes [\#541](https://github.com/realm/realm-cocoa/pull/541) ([alazier](https://github.com/alazier))

- Fix build issues in examples [\#540](https://github.com/realm/realm-cocoa/pull/540) ([kneth](https://github.com/kneth))

- Fixes some build issues [\#539](https://github.com/realm/realm-cocoa/pull/539) ([alazier](https://github.com/alazier))

- Make build.sh show what it is building [\#538](https://github.com/realm/realm-cocoa/pull/538) ([emanuelez](https://github.com/emanuelez))

- Bug fixes for standalone arrays and indexOfObject: [\#537](https://github.com/realm/realm-cocoa/pull/537) ([alazier](https://github.com/alazier))

- Fix for notification tests  [\#536](https://github.com/realm/realm-cocoa/pull/536) ([alazier](https://github.com/alazier))

- Migration example rewrite [\#535](https://github.com/realm/realm-cocoa/pull/535) ([alazier](https://github.com/alazier))

- Remove public query api from RLMRealm - add realm specific api to RLMObject [\#534](https://github.com/realm/realm-cocoa/pull/534) ([alazier](https://github.com/alazier))

- Added doc on schema migration [\#533](https://github.com/realm/realm-cocoa/pull/533) ([amuramoto](https://github.com/amuramoto))

- Added RealmRestExample example app [\#532](https://github.com/realm/realm-cocoa/pull/532) ([amuramoto](https://github.com/amuramoto))

- Fixed Xcode 6 project's RLMPredicateUtil's target membership to tests instead of framework [\#531](https://github.com/realm/realm-cocoa/pull/531) ([jpsim](https://github.com/jpsim))

- Fix podspec license [\#530](https://github.com/realm/realm-cocoa/pull/530) ([jpsim](https://github.com/jpsim))

- Fix for calling description from the dynamic interface [\#529](https://github.com/realm/realm-cocoa/pull/529) ([alazier](https://github.com/alazier))

- A couple negative comparison tests [\#528](https://github.com/realm/realm-cocoa/pull/528) ([oleks](https://github.com/oleks))

- Testing: compound predicates [\#527](https://github.com/realm/realm-cocoa/pull/527) ([oleks](https://github.com/oleks))

- Testing: keypath location in comparisons [\#526](https://github.com/realm/realm-cocoa/pull/526) ([oleks](https://github.com/oleks))

- Add GA to README [\#525](https://github.com/realm/realm-cocoa/pull/525) ([timanglade](https://github.com/timanglade))

- Performance improvements [\#522](https://github.com/realm/realm-cocoa/pull/522) ([alazier](https://github.com/alazier))

- IndexOfObject for RLMArray [\#521](https://github.com/realm/realm-cocoa/pull/521) ([astigsen](https://github.com/astigsen))

- add migration test [\#519](https://github.com/realm/realm-cocoa/pull/519) ([alazier](https://github.com/alazier))

- Minor updates to docs [\#518](https://github.com/realm/realm-cocoa/pull/518) ([timanglade](https://github.com/timanglade))

- Sidebar improvements for browser [\#517](https://github.com/realm/realm-cocoa/pull/517) ([astigsen](https://github.com/astigsen))

- Testing invalid operators in numeric predicates and some minor refactoring [\#513](https://github.com/realm/realm-cocoa/pull/513) ([oleks](https://github.com/oleks))

- Support Swift-defined models [\#487](https://github.com/realm/realm-cocoa/pull/487) ([jpsim](https://github.com/jpsim))

## [v0.22.0](https://github.com/realm/realm-cocoa/tree/v0.22.0) (2014-07-03)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.21.0...v0.22.0)

**Merged pull requests:**

- Make schemes shared for command line tools [\#524](https://github.com/realm/realm-cocoa/pull/524) ([emanuelez](https://github.com/emanuelez))

- Drop the prefix of RLMPredicateException [\#516](https://github.com/realm/realm-cocoa/pull/516) ([oleks](https://github.com/oleks))

- Add source for iOS guide [\#512](https://github.com/realm/realm-cocoa/pull/512) ([timanglade](https://github.com/timanglade))

- Fix for some issues on the swift branch [\#511](https://github.com/realm/realm-cocoa/pull/511) ([alazier](https://github.com/alazier))

- Make the version handling dynamic [\#509](https://github.com/realm/realm-cocoa/pull/509) ([emanuelez](https://github.com/emanuelez))

- Updated changelog for last few PRs [\#508](https://github.com/realm/realm-cocoa/pull/508) ([alazier](https://github.com/alazier))

- updated Visual Editor with new dynamic realm constructor [\#507](https://github.com/realm/realm-cocoa/pull/507) ([jpsim](https://github.com/jpsim))

- Fix for async tests in xcode6 [\#506](https://github.com/realm/realm-cocoa/pull/506) ([alazier](https://github.com/alazier))

- Workaround for 32 bit issues with DateTime. [\#505](https://github.com/realm/realm-cocoa/pull/505) ([kneth](https://github.com/kneth))

- Revert "Adding support for two-column comparison for Date." [\#504](https://github.com/realm/realm-cocoa/pull/504) ([emanuelez](https://github.com/emanuelez))

- test-debug now respects xcmode [\#503](https://github.com/realm/realm-cocoa/pull/503) ([jpsim](https://github.com/jpsim))

- Fixing absolute path in project configuration. [\#502](https://github.com/realm/realm-cocoa/pull/502) ([zuschlag](https://github.com/zuschlag))

- added comments for error types [\#501](https://github.com/realm/realm-cocoa/pull/501) ([mekjaer](https://github.com/mekjaer))

- Adding support for two-column comparison for Date. [\#500](https://github.com/realm/realm-cocoa/pull/500) ([kneth](https://github.com/kneth))

- Fixing warnings in iOS test cases. [\#499](https://github.com/realm/realm-cocoa/pull/499) ([zuschlag](https://github.com/zuschlag))

- test for unknown type [\#498](https://github.com/realm/realm-cocoa/pull/498) ([mekjaer](https://github.com/mekjaer))

- using protocol instead of macro in swift simple example [\#497](https://github.com/realm/realm-cocoa/pull/497) ([mekjaer](https://github.com/mekjaer))

- property type checks + json test [\#496](https://github.com/realm/realm-cocoa/pull/496) ([mekjaer](https://github.com/mekjaer))

- Add a script to replace the framework search path [\#495](https://github.com/realm/realm-cocoa/pull/495) ([emanuelez](https://github.com/emanuelez))

- A few test fixes [\#494](https://github.com/realm/realm-cocoa/pull/494) ([mekjaer](https://github.com/mekjaer))

- Alternative two-column comparison [\#493](https://github.com/realm/realm-cocoa/pull/493) ([kneth](https://github.com/kneth))

- Add a couple of debug test targets to build.sh [\#492](https://github.com/realm/realm-cocoa/pull/492) ([emanuelez](https://github.com/emanuelez))

- Fix the test-all target for build.sh [\#491](https://github.com/realm/realm-cocoa/pull/491) ([emanuelez](https://github.com/emanuelez))

- disabled test due to changes in core [\#490](https://github.com/realm/realm-cocoa/pull/490) ([mekjaer](https://github.com/mekjaer))

- Log xcpretty builds [\#489](https://github.com/realm/realm-cocoa/pull/489) ([emanuelez](https://github.com/emanuelez))

- added swift simple example [\#488](https://github.com/realm/realm-cocoa/pull/488) ([mekjaer](https://github.com/mekjaer))

- Typo fixes [\#486](https://github.com/realm/realm-cocoa/pull/486) ([amuramoto](https://github.com/amuramoto))

- Throwing an exception when error == nil [\#484](https://github.com/realm/realm-cocoa/pull/484) ([kneth](https://github.com/kneth))

- added Swift example. uses objc model [\#483](https://github.com/realm/realm-cocoa/pull/483) ([jpsim](https://github.com/jpsim))

- invalid path for realm check + test [\#482](https://github.com/realm/realm-cocoa/pull/482) ([mekjaer](https://github.com/mekjaer))

- more tests [\#481](https://github.com/realm/realm-cocoa/pull/481) ([mekjaer](https://github.com/mekjaer))

- Moved all objc examples to examples/objc [\#479](https://github.com/realm/realm-cocoa/pull/479) ([jpsim](https://github.com/jpsim))

- moved private headers to project headers [\#477](https://github.com/realm/realm-cocoa/pull/477) ([jpsim](https://github.com/jpsim))

- check for specific exceptions thrown [\#476](https://github.com/realm/realm-cocoa/pull/476) ([mekjaer](https://github.com/mekjaer))

- Informing the user where the problem is [\#474](https://github.com/realm/realm-cocoa/pull/474) ([kneth](https://github.com/kneth))

- Support junit output on xcpretty if running within Jenkins [\#473](https://github.com/realm/realm-cocoa/pull/473) ([emanuelez](https://github.com/emanuelez))

- added tests for query between [\#472](https://github.com/realm/realm-cocoa/pull/472) ([mekjaer](https://github.com/mekjaer))

- Make build.sh configuration behaviour uniform. [\#471](https://github.com/realm/realm-cocoa/pull/471) ([emanuelez](https://github.com/emanuelez))

- nil is possible value for a RLMObject [\#470](https://github.com/realm/realm-cocoa/pull/470) ([kneth](https://github.com/kneth))

- More test coverage [\#469](https://github.com/realm/realm-cocoa/pull/469) ([mekjaer](https://github.com/mekjaer))

- Remove dependency from the Realm project in the examples [\#468](https://github.com/realm/realm-cocoa/pull/468) ([emanuelez](https://github.com/emanuelez))

- +className now returns the demangled name [\#466](https://github.com/realm/realm-cocoa/pull/466) ([jpsim](https://github.com/jpsim))

- Some predicate tests [\#464](https://github.com/realm/realm-cocoa/pull/464) ([oleks](https://github.com/oleks))

- Added Swift tests [\#458](https://github.com/realm/realm-cocoa/pull/458) ([jpsim](https://github.com/jpsim))

- added license for XCTestCase+AsyncTesting in LICENSE [\#457](https://github.com/realm/realm-cocoa/pull/457) ([mekjaer](https://github.com/mekjaer))

- create standalone RLMObject from array or dictionary [\#456](https://github.com/realm/realm-cocoa/pull/456) ([mekjaer](https://github.com/mekjaer))

- Added Realm-Xcode6.xcodeproj [\#455](https://github.com/realm/realm-cocoa/pull/455) ([jpsim](https://github.com/jpsim))

- updated build.sh [\#454](https://github.com/realm/realm-cocoa/pull/454) ([jpsim](https://github.com/jpsim))

- Refactoring and adding some numeric predicate tests [\#452](https://github.com/realm/realm-cocoa/pull/452) ([oleks](https://github.com/oleks))

- rollback unintended commit + fix in test [\#450](https://github.com/realm/realm-cocoa/pull/450) ([mekjaer](https://github.com/mekjaer))

- small tweak to performance, to equal out comparison [\#449](https://github.com/realm/realm-cocoa/pull/449) ([mekjaer](https://github.com/mekjaer))

- Fixed broken examples [\#448](https://github.com/realm/realm-cocoa/pull/448) ([mekjaer](https://github.com/mekjaer))

- using new query method [\#447](https://github.com/realm/realm-cocoa/pull/447) ([mekjaer](https://github.com/mekjaer))

- Column compare [\#446](https://github.com/realm/realm-cocoa/pull/446) ([kneth](https://github.com/kneth))

- Test iOS Release configuration in simulator [\#445](https://github.com/realm/realm-cocoa/pull/445) ([jpsim](https://github.com/jpsim))

- Removed unused code from RealmTableViewExample [\#444](https://github.com/realm/realm-cocoa/pull/444) ([jpsim](https://github.com/jpsim))

- updated predicate and sorting method signatures [\#443](https://github.com/realm/realm-cocoa/pull/443) ([jpsim](https://github.com/jpsim))

- Renaming schemaForObject on RLMSchema + updating changelog [\#441](https://github.com/realm/realm-cocoa/pull/441) ([zuschlag](https://github.com/zuschlag))

- Updates to license distribution [\#440](https://github.com/realm/realm-cocoa/pull/440) ([jpsim](https://github.com/jpsim))

- Updated where test objects are defined [\#439](https://github.com/realm/realm-cocoa/pull/439) ([jpsim](https://github.com/jpsim))

- Moved RLMNotificationToken to its own h/m files [\#438](https://github.com/realm/realm-cocoa/pull/438) ([jpsim](https://github.com/jpsim))

- fixed a few clang errors \(unused arguments\) [\#435](https://github.com/realm/realm-cocoa/pull/435) ([jpsim](https://github.com/jpsim))

- Updated Realm.podspec [\#434](https://github.com/realm/realm-cocoa/pull/434) ([jpsim](https://github.com/jpsim))

- Use core accessors [\#433](https://github.com/realm/realm-cocoa/pull/433) ([alazier](https://github.com/alazier))

- Apache license proposal [\#430](https://github.com/realm/realm-cocoa/pull/430) ([mekjaer](https://github.com/mekjaer))

- realm in memory now supported [\#429](https://github.com/realm/realm-cocoa/pull/429) ([mekjaer](https://github.com/mekjaer))

- \[WIP\] Script clean up [\#428](https://github.com/realm/realm-cocoa/pull/428) ([kneth](https://github.com/kneth))

- Remove the docket folder after compressing it [\#427](https://github.com/realm/realm-cocoa/pull/427) ([emanuelez](https://github.com/emanuelez))

- typos in exceptions [\#426](https://github.com/realm/realm-cocoa/pull/426) ([mekjaer](https://github.com/mekjaer))

- Copy changelog and info files to iOS framework [\#425](https://github.com/realm/realm-cocoa/pull/425) ([kneth](https://github.com/kneth))

- implemented support for deletion of objects on array [\#423](https://github.com/realm/realm-cocoa/pull/423) ([mekjaer](https://github.com/mekjaer))

- Add header path for coverage tests [\#422](https://github.com/realm/realm-cocoa/pull/422) ([emanuelez](https://github.com/emanuelez))

- Copy the headers in the OSX framework correctly [\#421](https://github.com/realm/realm-cocoa/pull/421) ([emanuelez](https://github.com/emanuelez))

- completely rewrote build.sh [\#416](https://github.com/realm/realm-cocoa/pull/416) ([jpsim](https://github.com/jpsim))

- Fixed an issue in RLMAccessor.mm [\#414](https://github.com/realm/realm-cocoa/pull/414) ([jpsim](https://github.com/jpsim))

- Fixed spelling of 'available' in documentation comments. [\#411](https://github.com/realm/realm-cocoa/pull/411) ([pauldardeau](https://github.com/pauldardeau))

- ported over enumerator test from old-src [\#410](https://github.com/realm/realm-cocoa/pull/410) ([mekjaer](https://github.com/mekjaer))

- Enable code coverage [\#409](https://github.com/realm/realm-cocoa/pull/409) ([emanuelez](https://github.com/emanuelez))

- small fixes [\#408](https://github.com/realm/realm-cocoa/pull/408) ([mekjaer](https://github.com/mekjaer))

- rearrange framework search paths [\#407](https://github.com/realm/realm-cocoa/pull/407) ([mekjaer](https://github.com/mekjaer))

- added path to framework [\#406](https://github.com/realm/realm-cocoa/pull/406) ([mekjaer](https://github.com/mekjaer))

- Realm simple example [\#405](https://github.com/realm/realm-cocoa/pull/405) ([mekjaer](https://github.com/mekjaer))

- added test for RLMPropertyType lining up to tightdb::type [\#404](https://github.com/realm/realm-cocoa/pull/404) ([mekjaer](https://github.com/mekjaer))

- Fix for updating link array accessors [\#403](https://github.com/realm/realm-cocoa/pull/403) ([alazier](https://github.com/alazier))

- Fixed minor typos and missing parameters in api docs. [\#402](https://github.com/realm/realm-cocoa/pull/402) ([astigsen](https://github.com/astigsen))

- Added debug/release config tests [\#401](https://github.com/realm/realm-cocoa/pull/401) ([jpsim](https://github.com/jpsim))

- Update podspec wording for consistency with website [\#400](https://github.com/realm/realm-cocoa/pull/400) ([timanglade](https://github.com/timanglade))

- removed `rm -rf core` since it will never be called [\#399](https://github.com/realm/realm-cocoa/pull/399) ([jpsim](https://github.com/jpsim))

- updated wording on exception thrown when getting a realm from a thread without a runloop [\#398](https://github.com/realm/realm-cocoa/pull/398) ([jpsim](https://github.com/jpsim))

- Cleaned up build system [\#397](https://github.com/realm/realm-cocoa/pull/397) ([jpsim](https://github.com/jpsim))

- Pd misuse tests [\#396](https://github.com/realm/realm-cocoa/pull/396) ([pauldardeau](https://github.com/pauldardeau))

- Creating a better download script. [\#395](https://github.com/realm/realm-cocoa/pull/395) ([kneth](https://github.com/kneth))

- Fixed a number of type mismatch warnings in tests [\#394](https://github.com/realm/realm-cocoa/pull/394) ([jpsim](https://github.com/jpsim))

- \[WIP\] Visual browser and editor. [\#391](https://github.com/realm/realm-cocoa/pull/391) ([zuschlag](https://github.com/zuschlag))

- Upate docs for 0.21.0 [\#390](https://github.com/realm/realm-cocoa/pull/390) ([timanglade](https://github.com/timanglade))

- PR fixes and core download [\#389](https://github.com/realm/realm-cocoa/pull/389) ([alazier](https://github.com/alazier))

- Using libc++ instead of stdlibc++. [\#384](https://github.com/realm/realm-cocoa/pull/384) ([kneth](https://github.com/kneth))

## [v0.21.0](https://github.com/realm/realm-cocoa/tree/v0.21.0) (2014-06-06)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.20.0...v0.21.0)

**Merged pull requests:**

- fix for fast enumeration [\#388](https://github.com/realm/realm-cocoa/pull/388) ([alazier](https://github.com/alazier))

- Fix the build [\#387](https://github.com/realm/realm-cocoa/pull/387) ([alazier](https://github.com/alazier))

- Fix the build problems [\#386](https://github.com/realm/realm-cocoa/pull/386) ([emanuelez](https://github.com/emanuelez))

- LinkView backed and standalone RLMArrays [\#385](https://github.com/realm/realm-cocoa/pull/385) ([alazier](https://github.com/alazier))

- Notification registration [\#382](https://github.com/realm/realm-cocoa/pull/382) ([alazier](https://github.com/alazier))

- Removing Makefiles [\#379](https://github.com/realm/realm-cocoa/pull/379) ([kneth](https://github.com/kneth))

- Further Enhancements to Xcode Build [\#377](https://github.com/realm/realm-cocoa/pull/377) ([timanglade](https://github.com/timanglade))

- added RLMArray -description and tests [\#376](https://github.com/realm/realm-cocoa/pull/376) ([jpsim](https://github.com/jpsim))

- isReadonly property should only use "is" in the custom getter [\#374](https://github.com/realm/realm-cocoa/pull/374) ([jpsim](https://github.com/jpsim))

- Use static library when building osx framework [\#373](https://github.com/realm/realm-cocoa/pull/373) ([alazier](https://github.com/alazier))

- removed old sources. [\#372](https://github.com/realm/realm-cocoa/pull/372) ([bmunkholm](https://github.com/bmunkholm))

- fast enum test case added [\#371](https://github.com/realm/realm-cocoa/pull/371) ([mekjaer](https://github.com/mekjaer))

- tiny cleanup [\#370](https://github.com/realm/realm-cocoa/pull/370) ([mekjaer](https://github.com/mekjaer))

- added alternative init to insert [\#369](https://github.com/realm/realm-cocoa/pull/369) ([mekjaer](https://github.com/mekjaer))

- Simplified .gitignore. Remove binaries in general - we don't want any no matter their location. [\#368](https://github.com/realm/realm-cocoa/pull/368) ([bmunkholm](https://github.com/bmunkholm))

- updated gitignore to ignore realm-core [\#366](https://github.com/realm/realm-cocoa/pull/366) ([jpsim](https://github.com/jpsim))

- Adding Appledoc target [\#365](https://github.com/realm/realm-cocoa/pull/365) ([kneth](https://github.com/kneth))

- Adding target to download binary core [\#364](https://github.com/realm/realm-cocoa/pull/364) ([kneth](https://github.com/kneth))

- performance example port to object bag [\#362](https://github.com/realm/realm-cocoa/pull/362) ([mekjaer](https://github.com/mekjaer))

- Updates to doc comments [\#361](https://github.com/realm/realm-cocoa/pull/361) ([amuramoto](https://github.com/amuramoto))

- Fixed bug that didn't allow docset installation in Dash via the weblink [\#360](https://github.com/realm/realm-cocoa/pull/360) ([jpsim](https://github.com/jpsim))

- Added RLMPropertyAttributeIndexed [\#358](https://github.com/realm/realm-cocoa/pull/358) ([jpsim](https://github.com/jpsim))

- Default implementation for attributesForProperty [\#357](https://github.com/realm/realm-cocoa/pull/357) ([jpsim](https://github.com/jpsim))

- Fixed typo's in RLM\_PREDICATE macro comment [\#355](https://github.com/realm/realm-cocoa/pull/355) ([jpsim](https://github.com/jpsim))

- Added description method to RLMObject [\#354](https://github.com/realm/realm-cocoa/pull/354) ([jpsim](https://github.com/jpsim))

- Added support for ignored properties [\#352](https://github.com/realm/realm-cocoa/pull/352) ([jpsim](https://github.com/jpsim))

- updated podspec to require iOS 7+, add help@realm.io, add twitter url [\#351](https://github.com/realm/realm-cocoa/pull/351) ([jpsim](https://github.com/jpsim))

- removed Realm.xccheckout and added entry to .gitignore [\#350](https://github.com/realm/realm-cocoa/pull/350) ([jpsim](https://github.com/jpsim))

- \[WIP\] xcode project for iOS [\#349](https://github.com/realm/realm-cocoa/pull/349) ([kneth](https://github.com/kneth))

- Fixed issue in RealmTableViewExample that would prevent notifications from working on 64bit iOS [\#348](https://github.com/realm/realm-cocoa/pull/348) ([jpsim](https://github.com/jpsim))

- Added validation support for createInRealm:withObject: [\#347](https://github.com/realm/realm-cocoa/pull/347) ([fyell](https://github.com/fyell))

- Enable links support [\#346](https://github.com/realm/realm-cocoa/pull/346) ([alazier](https://github.com/alazier))

- Added podspec [\#345](https://github.com/realm/realm-cocoa/pull/345) ([jpsim](https://github.com/jpsim))

- Removed Podfile with realm core [\#344](https://github.com/realm/realm-cocoa/pull/344) ([jpsim](https://github.com/jpsim))

- Added basic Realm model Xcode template and installation script [\#343](https://github.com/realm/realm-cocoa/pull/343) ([jpsim](https://github.com/jpsim))

- Fix for test failures, Test cleanup [\#341](https://github.com/realm/realm-cocoa/pull/341) ([alazier](https://github.com/alazier))

- Default Values for RLMObject [\#340](https://github.com/realm/realm-cocoa/pull/340) ([fyell](https://github.com/fyell))

## [v0.20.0](https://github.com/realm/realm-cocoa/tree/v0.20.0) (2014-05-28)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.10.0...v0.20.0)

**Merged pull requests:**

- Mk test case commit [\#336](https://github.com/realm/realm-cocoa/pull/336) ([mekjaer](https://github.com/mekjaer))

- Added log message when a commit was not done before dealloc. [\#329](https://github.com/realm/realm-cocoa/pull/329) ([bmunkholm](https://github.com/bmunkholm))

- Docs cleanup [\#328](https://github.com/realm/realm-cocoa/pull/328) ([timanglade](https://github.com/timanglade))

- Fix some Xcode parameters [\#326](https://github.com/realm/realm-cocoa/pull/326) ([emanuelez](https://github.com/emanuelez))

- Minor updates to QueryTests. [\#325](https://github.com/realm/realm-cocoa/pull/325) ([bmunkholm](https://github.com/bmunkholm))

- Remove the docset from the HTML docs output [\#324](https://github.com/realm/realm-cocoa/pull/324) ([emanuelez](https://github.com/emanuelez))

- Make docs generation work on object-store [\#323](https://github.com/realm/realm-cocoa/pull/323) ([emanuelez](https://github.com/emanuelez))

- RLMArray backingView as ivar instead of property [\#322](https://github.com/realm/realm-cocoa/pull/322) ([mekjaer](https://github.com/mekjaer))

- Fix get-version and set-version [\#321](https://github.com/realm/realm-cocoa/pull/321) ([emanuelez](https://github.com/emanuelez))

-  build ios framework [\#320](https://github.com/realm/realm-cocoa/pull/320) ([mekjaer](https://github.com/mekjaer))

- Test sort on mixed col [\#319](https://github.com/realm/realm-cocoa/pull/319) ([mekjaer](https://github.com/mekjaer))

- Using xocdebuild in build.sh [\#318](https://github.com/realm/realm-cocoa/pull/318) ([kneth](https://github.com/kneth))

- Changelog in XCode [\#315](https://github.com/realm/realm-cocoa/pull/315) ([mekjaer](https://github.com/mekjaer))

- Merge master [\#314](https://github.com/realm/realm-cocoa/pull/314) ([bmunkholm](https://github.com/bmunkholm))

- lass extension test [\#313](https://github.com/realm/realm-cocoa/pull/313) ([mekjaer](https://github.com/mekjaer))

- build.sh for the new object store [\#311](https://github.com/realm/realm-cocoa/pull/311) ([kneth](https://github.com/kneth))

- translate to string in exceptions [\#310](https://github.com/realm/realm-cocoa/pull/310) ([mekjaer](https://github.com/mekjaer))

- Mk fix domain [\#308](https://github.com/realm/realm-cocoa/pull/308) ([mekjaer](https://github.com/mekjaer))

- Misuse of transactions test [\#307](https://github.com/realm/realm-cocoa/pull/307) ([mekjaer](https://github.com/mekjaer))

- RLMRow is removed [\#306](https://github.com/realm/realm-cocoa/pull/306) ([kneth](https://github.com/kneth))

- Dynamic interface [\#305](https://github.com/realm/realm-cocoa/pull/305) ([alazier](https://github.com/alazier))

- Sort column types tidy up [\#304](https://github.com/realm/realm-cocoa/pull/304) ([mekjaer](https://github.com/mekjaer))

- Sort view on float, double and string column types [\#303](https://github.com/realm/realm-cocoa/pull/303) ([mekjaer](https://github.com/mekjaer))

- Podfile for core [\#302](https://github.com/realm/realm-cocoa/pull/302) ([kneth](https://github.com/kneth))

- Rightside keypath predicate [\#301](https://github.com/realm/realm-cocoa/pull/301) ([zuschlag](https://github.com/zuschlag))

- Mixed support and tests [\#300](https://github.com/realm/realm-cocoa/pull/300) ([alazier](https://github.com/alazier))

- min max on date props [\#298](https://github.com/realm/realm-cocoa/pull/298) ([mekjaer](https://github.com/mekjaer))

- Use accessors to insert directly when adding an object to a Realm [\#297](https://github.com/realm/realm-cocoa/pull/297) ([alazier](https://github.com/alazier))

- ReadOnly and Invalid Accessors Classes for Objects and Arrays [\#296](https://github.com/realm/realm-cocoa/pull/296) ([alazier](https://github.com/alazier))

- Object typed table test [\#294](https://github.com/realm/realm-cocoa/pull/294) ([mekjaer](https://github.com/mekjaer))

- Fix crash when querying arrays [\#293](https://github.com/realm/realm-cocoa/pull/293) ([alazier](https://github.com/alazier))

- Fix for setting column index for properties, example test cleanup [\#291](https://github.com/realm/realm-cocoa/pull/291) ([alazier](https://github.com/alazier))

- Adding a number of new folders and files to dist-copy [\#290](https://github.com/realm/realm-cocoa/pull/290) ([kneth](https://github.com/kneth))

- Run examples from test-examples in build.sh [\#289](https://github.com/realm/realm-cocoa/pull/289) ([mekjaer](https://github.com/mekjaer))

- updated test-examples in build.sh [\#288](https://github.com/realm/realm-cocoa/pull/288) ([mekjaer](https://github.com/mekjaer))

- Make the schemas shared in order to be able to build the project with command line tools [\#287](https://github.com/realm/realm-cocoa/pull/287) ([emanuelez](https://github.com/emanuelez))

- simple example added to example folder [\#286](https://github.com/realm/realm-cocoa/pull/286) ([mekjaer](https://github.com/mekjaer))

- catch core not found, return NSNotFound [\#285](https://github.com/realm/realm-cocoa/pull/285) ([mekjaer](https://github.com/mekjaer))

- Install the documentation and improve the README [\#283](https://github.com/realm/realm-cocoa/pull/283) ([emanuelez](https://github.com/emanuelez))

- Add the docset package url in the docs generation [\#282](https://github.com/realm/realm-cocoa/pull/282) ([emanuelez](https://github.com/emanuelez))

- Ignore useless appledoc warnings, raise threshold to 1 [\#281](https://github.com/realm/realm-cocoa/pull/281) ([timanglade](https://github.com/timanglade))

- Change release notes to changelog [\#280](https://github.com/realm/realm-cocoa/pull/280) ([timanglade](https://github.com/timanglade))

- Removing examples folder from top Makefile [\#278](https://github.com/realm/realm-cocoa/pull/278) ([kneth](https://github.com/kneth))

- Add links to Xcode and dash in the html docs [\#277](https://github.com/realm/realm-cocoa/pull/277) ([emanuelez](https://github.com/emanuelez))

- Allow spaces in paths for the package-examples target [\#276](https://github.com/realm/realm-cocoa/pull/276) ([emanuelez](https://github.com/emanuelez))

- Remove the need to run the vi-test target as root [\#275](https://github.com/realm/realm-cocoa/pull/275) ([emanuelez](https://github.com/emanuelez))

- Fix incorrect read-only status for descriptors [\#274](https://github.com/realm/realm-cocoa/pull/274) ([kspangsege](https://github.com/kspangsege))

- Adding support for NOT operator in predicates [\#272](https://github.com/realm/realm-cocoa/pull/272) ([zuschlag](https://github.com/zuschlag))

- Package the examples as self-contained zip files [\#271](https://github.com/realm/realm-cocoa/pull/271) ([emanuelez](https://github.com/emanuelez))

- Docset generation [\#270](https://github.com/realm/realm-cocoa/pull/270) ([emanuelez](https://github.com/emanuelez))

- Increase the appledoc threshold to 2 in order not to fail on warnings [\#269](https://github.com/realm/realm-cocoa/pull/269) ([emanuelez](https://github.com/emanuelez))

- Fixed xib issue in RealmPerformanceExample [\#268](https://github.com/realm/realm-cocoa/pull/268) ([jpsim](https://github.com/jpsim))

- Rename set\_row methods in util.mm to be clear they're update\_row methods [\#265](https://github.com/realm/realm-cocoa/pull/265) ([fyell](https://github.com/fyell))

- Updated release notes for aggregates [\#264](https://github.com/realm/realm-cocoa/pull/264) ([fyell](https://github.com/fyell))

- added and renamed RealmPerformanceExample [\#263](https://github.com/realm/realm-cocoa/pull/263) ([mekjaer](https://github.com/mekjaer))

- Adding toJSONString methods to RLMRealm, RLMTable and RLMView. [\#262](https://github.com/realm/realm-cocoa/pull/262) ([zuschlag](https://github.com/zuschlag))

- Add the docs template to the repo [\#261](https://github.com/realm/realm-cocoa/pull/261) ([emanuelez](https://github.com/emanuelez))

- Using NSString instead of char \* [\#260](https://github.com/realm/realm-cocoa/pull/260) ([kneth](https://github.com/kneth))

- \[BUG\] Added tests to demonstrate crash when an RLMRow subclass contains both a mixed property and a subtable property [\#259](https://github.com/realm/realm-cocoa/pull/259) ([jpsim](https://github.com/jpsim))

- Increased async test timeouts [\#258](https://github.com/realm/realm-cocoa/pull/258) ([jpsim](https://github.com/jpsim))

- Clean up doc/ directory and move to docs/ [\#257](https://github.com/realm/realm-cocoa/pull/257) ([jpsim](https://github.com/jpsim))

- Updated README.md and removed README.linux [\#256](https://github.com/realm/realm-cocoa/pull/256) ([jpsim](https://github.com/jpsim))

- Query validate [\#254](https://github.com/realm/realm-cocoa/pull/254) ([mekjaer](https://github.com/mekjaer))

- Use anonymous namespace for stuff that is private to a translation unit [\#253](https://github.com/realm/realm-cocoa/pull/253) ([kspangsege](https://github.com/kspangsege))

- \[BUG\] Adding an empty subtable in typed tables. [\#252](https://github.com/realm/realm-cocoa/pull/252) ([kneth](https://github.com/kneth))

- Resolving RLMTypes to string [\#251](https://github.com/realm/realm-cocoa/pull/251) ([kneth](https://github.com/kneth))

- Fixed wrong comment. [\#250](https://github.com/realm/realm-cocoa/pull/250) ([bmunkholm](https://github.com/bmunkholm))

- Refactored and removed BG Add feature from RealmTableViewExample [\#249](https://github.com/realm/realm-cocoa/pull/249) ([jpsim](https://github.com/jpsim))

- Removed PrivateHelperMacros, PrivateTableMacros & RLMPrivateTableMacrosFast [\#247](https://github.com/realm/realm-cocoa/pull/247) ([jpsim](https://github.com/jpsim))

- updated docs for removing transaction manager [\#246](https://github.com/realm/realm-cocoa/pull/246) ([alazier](https://github.com/alazier))

- Fix old xcode test errors [\#245](https://github.com/realm/realm-cocoa/pull/245) ([fyell](https://github.com/fyell))

- Removed duplicate RLMRealm accessor method from RLMTestCase [\#244](https://github.com/realm/realm-cocoa/pull/244) ([fyell](https://github.com/fyell))

- Removed reference examples [\#243](https://github.com/realm/realm-cocoa/pull/243) ([jpsim](https://github.com/jpsim))

- Remove all /\* \*/ internal comments in favor of // comments [\#242](https://github.com/realm/realm-cocoa/pull/242) ([fyell](https://github.com/fyell))

- Tweaks to BETWEEN predicate operation [\#241](https://github.com/realm/realm-cocoa/pull/241) ([jpsim](https://github.com/jpsim))

- Add mixed support to object interface [\#240](https://github.com/realm/realm-cocoa/pull/240) ([alazier](https://github.com/alazier))

- Moved most functions in query\_util to an anonymous namespace [\#239](https://github.com/realm/realm-cocoa/pull/239) ([jpsim](https://github.com/jpsim))

- Version control the CI scripts for pull requests [\#238](https://github.com/realm/realm-cocoa/pull/238) ([emanuelez](https://github.com/emanuelez))

- Merge Conflict Resolution: Throw exception when initializing RLMTable outside of context [\#237](https://github.com/realm/realm-cocoa/pull/237) ([jpsim](https://github.com/jpsim))

- Writable RLMRealm \(no more TransactionManager\), block based notifications [\#236](https://github.com/realm/realm-cocoa/pull/236) ([alazier](https://github.com/alazier))

- Added support for optional format va\_list to firstWhere: and allWhere: methods [\#234](https://github.com/realm/realm-cocoa/pull/234) ([jpsim](https://github.com/jpsim))

- Adding minOfProperty:where: and maxOfProperty:where: [\#232](https://github.com/realm/realm-cocoa/pull/232) ([fyell](https://github.com/fyell))

- Added AND and OR predicate tests [\#231](https://github.com/realm/realm-cocoa/pull/231) ([jpsim](https://github.com/jpsim))

- Moved RLMTable predicate functionality to a separate file \(category\) [\#230](https://github.com/realm/realm-cocoa/pull/230) ([jpsim](https://github.com/jpsim))

- Support BETWEEN predicate operator type [\#229](https://github.com/realm/realm-cocoa/pull/229) ([jpsim](https://github.com/jpsim))

- Mk run all refdoc ex [\#228](https://github.com/realm/realm-cocoa/pull/228) ([mekjaer](https://github.com/mekjaer))

- Added predicate support for NSData [\#227](https://github.com/realm/realm-cocoa/pull/227) ([jpsim](https://github.com/jpsim))

- addColumnWithName and variant methods now return col index [\#226](https://github.com/realm/realm-cocoa/pull/226) ([jpsim](https://github.com/jpsim))

- Added description to RLMRow [\#225](https://github.com/realm/realm-cocoa/pull/225) ([jpsim](https://github.com/jpsim))

- \[WIP\] Appledocs [\#224](https://github.com/realm/realm-cocoa/pull/224) ([timanglade](https://github.com/timanglade))

- Tutorial Rewrite [\#223](https://github.com/realm/realm-cocoa/pull/223) ([jpsim](https://github.com/jpsim))

- Support NSPredicates on NSDate and NSString [\#222](https://github.com/realm/realm-cocoa/pull/222) ([jpsim](https://github.com/jpsim))

- Renamed RLMContext to RLMTransactionManager [\#220](https://github.com/realm/realm-cocoa/pull/220) ([jpsim](https://github.com/jpsim))

- bugfix version [\#219](https://github.com/realm/realm-cocoa/pull/219) ([bmunkholm](https://github.com/bmunkholm))

- Hide where, rename predicate methods, added countWhere:, added sumOfColumn:Where, added averageOfColumn:where:  [\#217](https://github.com/realm/realm-cocoa/pull/217) ([fyell](https://github.com/fyell))

- Fix tests, add XCTAssert's, no longer call \[\[RLMTable alloc\] init\] [\#216](https://github.com/realm/realm-cocoa/pull/216) ([jpsim](https://github.com/jpsim))

- block accessors [\#215](https://github.com/realm/realm-cocoa/pull/215) ([alazier](https://github.com/alazier))

- Throw exception when initializing RLMTable outside of context [\#214](https://github.com/realm/realm-cocoa/pull/214) ([fyell](https://github.com/fyell))

- Added writable initializer block to Realm constructors [\#213](https://github.com/realm/realm-cocoa/pull/213) ([jpsim](https://github.com/jpsim))

- Reverting links and fixing code snippets [\#212](https://github.com/realm/realm-cocoa/pull/212) ([kneth](https://github.com/kneth))

- \[WIP\] Revert "Revert "Merge pull request \#207 from Tightdb/fg-hide-where"" [\#211](https://github.com/realm/realm-cocoa/pull/211) ([emanuelez](https://github.com/emanuelez))

- Renaming TIGHTDB to REALM in a few more places [\#210](https://github.com/realm/realm-cocoa/pull/210) ([kspangsege](https://github.com/kspangsege))

- New object interface [\#200](https://github.com/realm/realm-cocoa/pull/200) ([alazier](https://github.com/alazier))

## [v0.10.0](https://github.com/realm/realm-cocoa/tree/v0.10.0) (2014-04-23)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/$version...v0.10.0)

**Merged pull requests:**

- Renamed some TightDB references in the RLMDemo. [\#209](https://github.com/realm/realm-cocoa/pull/209) ([bmunkholm](https://github.com/bmunkholm))

- Moved Xcode project to root of repo and renamed to Realm.xcodeproj [\#208](https://github.com/realm/realm-cocoa/pull/208) ([jpsim](https://github.com/jpsim))

- Hide where from RLMTable and RLMView [\#207](https://github.com/realm/realm-cocoa/pull/207) ([fyell](https://github.com/fyell))

- Transaction rollback with optional argument [\#206](https://github.com/realm/realm-cocoa/pull/206) ([astigsen](https://github.com/astigsen))

- Hide optimize method [\#205](https://github.com/realm/realm-cocoa/pull/205) ([fyell](https://github.com/fyell))

- These unit tests seems to fail now and then  [\#203](https://github.com/realm/realm-cocoa/pull/203) ([kneth](https://github.com/kneth))

- Merge RLMSmartContext and RLMTransaction into RLMRealm [\#201](https://github.com/realm/realm-cocoa/pull/201) ([jpsim](https://github.com/jpsim))

- Updated as many of the TightDB references to Realm in doc/\* as possible [\#199](https://github.com/realm/realm-cocoa/pull/199) ([jpsim](https://github.com/jpsim))

- Keyed subscripting for RLMTable [\#198](https://github.com/realm/realm-cocoa/pull/198) ([fyell](https://github.com/fyell))

- documented TDBTransaction -isEmpty method [\#195](https://github.com/realm/realm-cocoa/pull/195) ([jpsim](https://github.com/jpsim))

- Added +contextWithDefaultPersistence to TDBSmartContext [\#194](https://github.com/realm/realm-cocoa/pull/194) ([jpsim](https://github.com/jpsim))

- added isEmpty BOOL property to TDBTransaction [\#193](https://github.com/realm/realm-cocoa/pull/193) ([jpsim](https://github.com/jpsim))

- Fixed YAML issues in doc/ref/data to make ref\_generator work [\#192](https://github.com/realm/realm-cocoa/pull/192) ([jpsim](https://github.com/jpsim))

- New Tutorial [\#190](https://github.com/realm/realm-cocoa/pull/190) ([jpsim](https://github.com/jpsim))

- Rename to RLM [\#189](https://github.com/realm/realm-cocoa/pull/189) ([fyell](https://github.com/fyell))

- Updated call to throw exception from using raise to using @throw [\#186](https://github.com/realm/realm-cocoa/pull/186) ([fyell](https://github.com/fyell))

- Moving categories around [\#185](https://github.com/realm/realm-cocoa/pull/185) ([kneth](https://github.com/kneth))

- Kg update refdoc [\#183](https://github.com/realm/realm-cocoa/pull/183) ([kneth](https://github.com/kneth))

- min cleanups [\#182](https://github.com/realm/realm-cocoa/pull/182) ([mekjaer](https://github.com/mekjaer))

- Added new method to specify schema when creating a table from a TDBTransaction. This method is useful for adding subtables. [\#177](https://github.com/realm/realm-cocoa/pull/177) ([fyell](https://github.com/fyell))

- Migrate to xctest [\#171](https://github.com/realm/realm-cocoa/pull/171) ([oleks](https://github.com/oleks))

## [$version](https://github.com/realm/realm-cocoa/tree/$version) (2014-04-11)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.6.0...$version)

## [v0.6.0](https://github.com/realm/realm-cocoa/tree/v0.6.0) (2014-04-11)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.5.0...v0.6.0)

**Merged pull requests:**

- files relative to project [\#181](https://github.com/realm/realm-cocoa/pull/181) ([mekjaer](https://github.com/mekjaer))

- include smart context in xcode [\#180](https://github.com/realm/realm-cocoa/pull/180) ([mekjaer](https://github.com/mekjaer))

- \[WIP\] Updates  API ref [\#179](https://github.com/realm/realm-cocoa/pull/179) ([kneth](https://github.com/kneth))

- Add -mios-version-min=5.0 when compiling for iOS [\#178](https://github.com/realm/realm-cocoa/pull/178) ([kspangsege](https://github.com/kspangsege))

- Disable dealloc NSLogs \(in debug mode\) - it's just noisy... [\#176](https://github.com/realm/realm-cocoa/pull/176) ([bmunkholm](https://github.com/bmunkholm))

- Initial support for NSPredicate [\#175](https://github.com/realm/realm-cocoa/pull/175) ([alazier](https://github.com/alazier))

- Default path on context [\#174](https://github.com/realm/realm-cocoa/pull/174) ([mekjaer](https://github.com/mekjaer))

- \[BUG\] Query.removeRows now checks for readonly [\#173](https://github.com/realm/realm-cocoa/pull/173) ([mekjaer](https://github.com/mekjaer))

- where on view [\#172](https://github.com/realm/realm-cocoa/pull/172) ([mekjaer](https://github.com/mekjaer))

- Generic object [\#170](https://github.com/realm/realm-cocoa/pull/170) ([kneth](https://github.com/kneth))

- \[BUG\] Exception when adding row read transaction [\#169](https://github.com/realm/realm-cocoa/pull/169) ([mekjaer](https://github.com/mekjaer))

- Version 1 of 'implicit transactions' [\#168](https://github.com/realm/realm-cocoa/pull/168) ([kspangsege](https://github.com/kspangsege))

- addRow and insertRow do not return any value. [\#167](https://github.com/realm/realm-cocoa/pull/167) ([kneth](https://github.com/kneth))

- Renamed `castClass` to `castToTypedTableClass` in TDBTable. [\#166](https://github.com/realm/realm-cocoa/pull/166) ([bmunkholm](https://github.com/bmunkholm))

- using @throw for exceptions and better alignment [\#165](https://github.com/realm/realm-cocoa/pull/165) ([mekjaer](https://github.com/mekjaer))

- return void instead of bool [\#163](https://github.com/realm/realm-cocoa/pull/163) ([mekjaer](https://github.com/mekjaer))

- Removing old files [\#162](https://github.com/realm/realm-cocoa/pull/162) ([kneth](https://github.com/kneth))

- Update tutorial [\#161](https://github.com/realm/realm-cocoa/pull/161) ([kneth](https://github.com/kneth))

- all size\_t have been replaced by NSUInteger [\#160](https://github.com/realm/realm-cocoa/pull/160) ([kneth](https://github.com/kneth))

- Update refdoc examples [\#159](https://github.com/realm/realm-cocoa/pull/159) ([bmunkholm](https://github.com/bmunkholm))

- \[WIP\] merge query aggregate operation methods to NSNUmber  [\#158](https://github.com/realm/realm-cocoa/pull/158) ([mekjaer](https://github.com/mekjaer))

- rename of findFromRowIndex [\#157](https://github.com/realm/realm-cocoa/pull/157) ([mekjaer](https://github.com/mekjaer))

- tdb prefix to refdoc classes [\#156](https://github.com/realm/realm-cocoa/pull/156) ([mekjaer](https://github.com/mekjaer))

- Return NSNotFound when core returns not\_found [\#155](https://github.com/realm/realm-cocoa/pull/155) ([kneth](https://github.com/kneth))

- test case added [\#154](https://github.com/realm/realm-cocoa/pull/154) ([mekjaer](https://github.com/mekjaer))

- \[WIP\] Bug fixes columnless tables [\#153](https://github.com/realm/realm-cocoa/pull/153) ([kneth](https://github.com/kneth))

- Small cleanup on \_noinst categories [\#152](https://github.com/realm/realm-cocoa/pull/152) ([mekjaer](https://github.com/mekjaer))

- The validation of data for Mixed typed columns  [\#151](https://github.com/realm/realm-cocoa/pull/151) ([kneth](https://github.com/kneth))

- Distinct added to table [\#150](https://github.com/realm/realm-cocoa/pull/150) ([mekjaer](https://github.com/mekjaer))

- Rename column added to table. + release notes updated [\#149](https://github.com/realm/realm-cocoa/pull/149) ([mekjaer](https://github.com/mekjaer))

- Non-capital letters in typed table column names [\#148](https://github.com/realm/realm-cocoa/pull/148) ([kneth](https://github.com/kneth))

- Between in query added + test cases reenabled [\#147](https://github.com/realm/realm-cocoa/pull/147) ([mekjaer](https://github.com/mekjaer))

- Transaction methods renamed in TDBContext [\#138](https://github.com/realm/realm-cocoa/pull/138) ([mekjaer](https://github.com/mekjaer))

## [v0.5.0](https://github.com/realm/realm-cocoa/tree/v0.5.0) (2014-04-02)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.4.0...v0.5.0)

**Merged pull requests:**

- \[WIP\] Cleaning [\#146](https://github.com/realm/realm-cocoa/pull/146) ([mekjaer](https://github.com/mekjaer))

- Updated ref-doc examples [\#145](https://github.com/realm/realm-cocoa/pull/145) ([bmunkholm](https://github.com/bmunkholm))

- Add min & max for date columns in TDBQuery [\#144](https://github.com/realm/realm-cocoa/pull/144) ([bmunkholm](https://github.com/bmunkholm))

- \[WIP\] test-iphone removed \(moved to examples repo\) [\#143](https://github.com/realm/realm-cocoa/pull/143) ([mekjaer](https://github.com/mekjaer))

- \[WIP\] Fast interface [\#142](https://github.com/realm/realm-cocoa/pull/142) ([mekjaer](https://github.com/mekjaer))

- Type conversion when in setting a date column [\#141](https://github.com/realm/realm-cocoa/pull/141) ([kneth](https://github.com/kneth))

- \[BUG\] nsnumber os bool check [\#139](https://github.com/realm/realm-cocoa/pull/139) ([mekjaer](https://github.com/mekjaer))

- removed getting started mini tutorial [\#137](https://github.com/realm/realm-cocoa/pull/137) ([mekjaer](https://github.com/mekjaer))

- moved private row methods to private header [\#136](https://github.com/realm/realm-cocoa/pull/136) ([mekjaer](https://github.com/mekjaer))

- made isReadOnly private [\#135](https://github.com/realm/realm-cocoa/pull/135) ([mekjaer](https://github.com/mekjaer))

- Column renames [\#133](https://github.com/realm/realm-cocoa/pull/133) ([mekjaer](https://github.com/mekjaer))

- generic set and get for rows [\#132](https://github.com/realm/realm-cocoa/pull/132) ([kneth](https://github.com/kneth))

- The installation test is now very simple [\#131](https://github.com/realm/realm-cocoa/pull/131) ([kneth](https://github.com/kneth))

- renamed gettable [\#130](https://github.com/realm/realm-cocoa/pull/130) ([mekjaer](https://github.com/mekjaer))

- Removing TDBMixed [\#124](https://github.com/realm/realm-cocoa/pull/124) ([kneth](https://github.com/kneth))

- Improvements for working with dynamic tables [\#113](https://github.com/realm/realm-cocoa/pull/113) ([astigsen](https://github.com/astigsen))

## [v0.4.0](https://github.com/realm/realm-cocoa/tree/v0.4.0) (2014-03-26)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.3.0...v0.4.0)

**Merged pull requests:**

- Pinned transactions [\#128](https://github.com/realm/realm-cocoa/pull/128) ([mekjaer](https://github.com/mekjaer))

- text update [\#127](https://github.com/realm/realm-cocoa/pull/127) ([mekjaer](https://github.com/mekjaer))

- Object subscripting in Views [\#126](https://github.com/realm/realm-cocoa/pull/126) ([mekjaer](https://github.com/mekjaer))

- cleanup [\#125](https://github.com/realm/realm-cocoa/pull/125) ([mekjaer](https://github.com/mekjaer))

- removed insertEmptyRow from table [\#123](https://github.com/realm/realm-cocoa/pull/123) ([mekjaer](https://github.com/mekjaer))

- withError - error rename [\#122](https://github.com/realm/realm-cocoa/pull/122) ([mekjaer](https://github.com/mekjaer))

- dynamic.m -\> dynamic.mm [\#121](https://github.com/realm/realm-cocoa/pull/121) ([mekjaer](https://github.com/mekjaer))

- Rename tightdb h [\#120](https://github.com/realm/realm-cocoa/pull/120) ([kneth](https://github.com/kneth))

- correct headers [\#118](https://github.com/realm/realm-cocoa/pull/118) ([mekjaer](https://github.com/mekjaer))

- Appending tdb prefixes to setString:inColumnWithIndex:atRowIndex etc [\#117](https://github.com/realm/realm-cocoa/pull/117) ([mekjaer](https://github.com/mekjaer))

- using created var [\#116](https://github.com/realm/realm-cocoa/pull/116) ([mekjaer](https://github.com/mekjaer))

- iPhone example reenabled [\#115](https://github.com/realm/realm-cocoa/pull/115) ([mekjaer](https://github.com/mekjaer))

- writeContextToFile public in transaction [\#114](https://github.com/realm/realm-cocoa/pull/114) ([mekjaer](https://github.com/mekjaer))

- table methods fixes and updates [\#112](https://github.com/realm/realm-cocoa/pull/112) ([mekjaer](https://github.com/mekjaer))

- Split getTable and createTable [\#111](https://github.com/realm/realm-cocoa/pull/111) ([mekjaer](https://github.com/mekjaer))

- Use nsdata instead of tdbbinary [\#110](https://github.com/realm/realm-cocoa/pull/110) ([kneth](https://github.com/kneth))

- Remove underscores in typed interface [\#109](https://github.com/realm/realm-cocoa/pull/109) ([mekjaer](https://github.com/mekjaer))

- ref doc updated [\#108](https://github.com/realm/realm-cocoa/pull/108) ([mekjaer](https://github.com/mekjaer))

- Contructor renamed to contextWithPersistenceToFile: [\#107](https://github.com/realm/realm-cocoa/pull/107) ([mekjaer](https://github.com/mekjaer))

- Removing underscore from typed table's generated classes [\#106](https://github.com/realm/realm-cocoa/pull/106) ([kneth](https://github.com/kneth))

- Remove verify [\#105](https://github.com/realm/realm-cocoa/pull/105) ([mekjaer](https://github.com/mekjaer))

- Improve readability of header files [\#104](https://github.com/realm/realm-cocoa/pull/104) ([astigsen](https://github.com/astigsen))

- \[WIP\] subtable and parent now return TDBQuery \* [\#103](https://github.com/realm/realm-cocoa/pull/103) ([mekjaer](https://github.com/mekjaer))

- Renaming files [\#102](https://github.com/realm/realm-cocoa/pull/102) ([kneth](https://github.com/kneth))

- Renaming shared group and group. [\#101](https://github.com/realm/realm-cocoa/pull/101) ([kneth](https://github.com/kneth))

- \[WIP\] added findFirstRow and rename [\#100](https://github.com/realm/realm-cocoa/pull/100) ([mekjaer](https://github.com/mekjaer))

- Devel into master [\#99](https://github.com/realm/realm-cocoa/pull/99) ([mekjaer](https://github.com/mekjaer))

- Devel up-to-date [\#98](https://github.com/realm/realm-cocoa/pull/98) ([mekjaer](https://github.com/mekjaer))

- Documenting renames [\#96](https://github.com/realm/realm-cocoa/pull/96) ([kneth](https://github.com/kneth))

- remove where and optimise error selector versions [\#95](https://github.com/realm/realm-cocoa/pull/95) ([mekjaer](https://github.com/mekjaer))

- reenabled test cases for dates [\#94](https://github.com/realm/realm-cocoa/pull/94) ([mekjaer](https://github.com/mekjaer))

- Devel [\#93](https://github.com/realm/realm-cocoa/pull/93) ([mekjaer](https://github.com/mekjaer))

- Fix doc examples to use the latest interface [\#92](https://github.com/realm/realm-cocoa/pull/92) ([emanuelez](https://github.com/emanuelez))

- Shared and group rename [\#91](https://github.com/realm/realm-cocoa/pull/91) ([mekjaer](https://github.com/mekjaer))

- Sharing scheme for doc examples. [\#90](https://github.com/realm/realm-cocoa/pull/90) ([kneth](https://github.com/kneth))

- Using Row instead of Cursor in examples and tutorial [\#89](https://github.com/realm/realm-cocoa/pull/89) ([mekjaer](https://github.com/mekjaer))

- Fixed examples and tutorials to build again [\#88](https://github.com/realm/realm-cocoa/pull/88) ([mekjaer](https://github.com/mekjaer))

- Shared and group rename [\#87](https://github.com/realm/realm-cocoa/pull/87) ([kneth](https://github.com/kneth))

- Merging mekjaer's NSDate branch [\#86](https://github.com/realm/realm-cocoa/pull/86) ([kneth](https://github.com/kneth))

- removed countEnumerator from headers [\#84](https://github.com/realm/realm-cocoa/pull/84) ([mekjaer](https://github.com/mekjaer))

- renamed cursor to row [\#83](https://github.com/realm/realm-cocoa/pull/83) ([mekjaer](https://github.com/mekjaer))

- \[WIP\] Remove error pam from group [\#81](https://github.com/realm/realm-cocoa/pull/81) ([mekjaer](https://github.com/mekjaer))

- First last row [\#80](https://github.com/realm/realm-cocoa/pull/80) ([mekjaer](https://github.com/mekjaer))

- \[WIP\] initial usage of NSDate. [\#79](https://github.com/realm/realm-cocoa/pull/79) ([mekjaer](https://github.com/mekjaer))

- \[WIP\] Examples should use newer features [\#78](https://github.com/realm/realm-cocoa/pull/78) ([kneth](https://github.com/kneth))

- \[group getTableWithName:\] added [\#77](https://github.com/realm/realm-cocoa/pull/77) ([mekjaer](https://github.com/mekjaer))

- removed unused Xcode project [\#76](https://github.com/realm/realm-cocoa/pull/76) ([mekjaer](https://github.com/mekjaer))

- Updated tutorial with latest syntax improvements [\#75](https://github.com/realm/realm-cocoa/pull/75) ([astigsen](https://github.com/astigsen))

## [v0.3.0](https://github.com/realm/realm-cocoa/tree/v0.3.0) (2014-03-14)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.2.0...v0.3.0)

**Merged pull requests:**

- Updated dynamic table refdoc to reflect the new names [\#74](https://github.com/realm/realm-cocoa/pull/74) ([hovoere](https://github.com/hovoere))

- hasChanged implemented + test cases [\#73](https://github.com/realm/realm-cocoa/pull/73) ([mekjaer](https://github.com/mekjaer))

- renamed ref doc selectors for view [\#72](https://github.com/realm/realm-cocoa/pull/72) ([mekjaer](https://github.com/mekjaer))

- ref doc old import [\#71](https://github.com/realm/realm-cocoa/pull/71) ([mekjaer](https://github.com/mekjaer))

- macro now used NSUInteger instead of size\_t as arguments [\#70](https://github.com/realm/realm-cocoa/pull/70) ([mekjaer](https://github.com/mekjaer))

- ref doc updated [\#69](https://github.com/realm/realm-cocoa/pull/69) ([mekjaer](https://github.com/mekjaer))

- created Xcode project to handle ref doc using framework [\#68](https://github.com/realm/realm-cocoa/pull/68) ([mekjaer](https://github.com/mekjaer))

- Making unit tests more readable. [\#67](https://github.com/realm/realm-cocoa/pull/67) ([kneth](https://github.com/kneth))

- TDB prefix [\#66](https://github.com/realm/realm-cocoa/pull/66) ([mekjaer](https://github.com/mekjaer))

- changes.txt [\#65](https://github.com/realm/realm-cocoa/pull/65) ([mekjaer](https://github.com/mekjaer))

- \[WIP\] Object Subscripting on cursors [\#64](https://github.com/realm/realm-cocoa/pull/64) ([astigsen](https://github.com/astigsen))

- New names for methods in objc [\#63](https://github.com/realm/realm-cocoa/pull/63) ([mekjaer](https://github.com/mekjaer))

- Make the Xcode scheme shared [\#62](https://github.com/realm/realm-cocoa/pull/62) ([emanuelez](https://github.com/emanuelez))

- \[WIP\] append rows using dictionaries [\#61](https://github.com/realm/realm-cocoa/pull/61) ([kneth](https://github.com/kneth))

- NSUInteger instead of size\_t [\#60](https://github.com/realm/realm-cocoa/pull/60) ([mekjaer](https://github.com/mekjaer))

- make sure test gets run =\> Start method name with test [\#59](https://github.com/realm/realm-cocoa/pull/59) ([mekjaer](https://github.com/mekjaer))

## [v0.2.0](https://github.com/realm/realm-cocoa/tree/v0.2.0) (2014-03-07)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.1.6...v0.2.0)

**Merged pull requests:**

- ignore readonly test [\#58](https://github.com/realm/realm-cocoa/pull/58) ([mekjaer](https://github.com/mekjaer))

- include table\_view test in Makefile + sorted make files sources alphabet... [\#56](https://github.com/realm/realm-cocoa/pull/56) ([mekjaer](https://github.com/mekjaer))

- documenting appendRow [\#55](https://github.com/realm/realm-cocoa/pull/55) ([kneth](https://github.com/kneth))

- using libc++ in example and getting started example instaed of libstdc++ [\#54](https://github.com/realm/realm-cocoa/pull/54) ([mekjaer](https://github.com/mekjaer))

- Object subscripting [\#53](https://github.com/realm/realm-cocoa/pull/53) ([astigsen](https://github.com/astigsen))

- Restoring tutorial [\#52](https://github.com/realm/realm-cocoa/pull/52) ([kneth](https://github.com/kneth))

- added read-only flag to view and test case [\#51](https://github.com/realm/realm-cocoa/pull/51) ([mekjaer](https://github.com/mekjaer))

- Feature object literals more tests [\#50](https://github.com/realm/realm-cocoa/pull/50) ([oleks](https://github.com/oleks))

- added remove column method on table [\#49](https://github.com/realm/realm-cocoa/pull/49) ([mekjaer](https://github.com/mekjaer))

- smaller text [\#48](https://github.com/realm/realm-cocoa/pull/48) ([mekjaer](https://github.com/mekjaer))

- added sort on view and getColumnType on view [\#47](https://github.com/realm/realm-cocoa/pull/47) ([mekjaer](https://github.com/mekjaer))

- Tutorial shared group  [\#44](https://github.com/realm/realm-cocoa/pull/44) ([mekjaer](https://github.com/mekjaer))

- \[WIP\] Using object literals to append rows to tables [\#42](https://github.com/realm/realm-cocoa/pull/42) ([kneth](https://github.com/kneth))

- Build fat binaries for iPhone when supported by Xcode \(from version 5\)  [\#41](https://github.com/realm/realm-cocoa/pull/41) ([kspangsege](https://github.com/kspangsege))

- \[BUG\] A range of tests on columnless tables. [\#39](https://github.com/realm/realm-cocoa/pull/39) ([oleks](https://github.com/oleks))

- Feature get version [\#38](https://github.com/realm/realm-cocoa/pull/38) ([kneth](https://github.com/kneth))

- addRow renamed to addEmptyRow [\#37](https://github.com/realm/realm-cocoa/pull/37) ([mekjaer](https://github.com/mekjaer))

- updated project to include table\_macros [\#36](https://github.com/realm/realm-cocoa/pull/36) ([mekjaer](https://github.com/mekjaer))

- Table test clean up [\#35](https://github.com/realm/realm-cocoa/pull/35) ([oleks](https://github.com/oleks))

- Framework header [\#33](https://github.com/realm/realm-cocoa/pull/33) ([mekjaer](https://github.com/mekjaer))

- Test cover [\#32](https://github.com/realm/realm-cocoa/pull/32) ([oleks](https://github.com/oleks))

- Test app framework [\#31](https://github.com/realm/realm-cocoa/pull/31) ([mekjaer](https://github.com/mekjaer))

- Error handling from Jesper \(and much more\)  [\#30](https://github.com/realm/realm-cocoa/pull/30) ([kspangsege](https://github.com/kspangsege))

- Support added for checking documentation examples [\#29](https://github.com/realm/realm-cocoa/pull/29) ([kspangsege](https://github.com/kspangsege))

- No C99/C++ comments allowed in Obj-C files \(discounting Obj-C++ files\) [\#28](https://github.com/realm/realm-cocoa/pull/28) ([kspangsege](https://github.com/kspangsege))

- Makefile upgraded to latest version from core library [\#27](https://github.com/realm/realm-cocoa/pull/27) ([kspangsege](https://github.com/kspangsege))

- Add col ref [\#24](https://github.com/realm/realm-cocoa/pull/24) ([mekjaer](https://github.com/mekjaer))

- Mini tutorial [\#23](https://github.com/realm/realm-cocoa/pull/23) ([mekjaer](https://github.com/mekjaer))

- Adding a target for build.sh to generate iOS framework [\#22](https://github.com/realm/realm-cocoa/pull/22) ([kneth](https://github.com/kneth))

- Check that $CONFIG\_MK is writable. [\#21](https://github.com/realm/realm-cocoa/pull/21) ([oleks](https://github.com/oleks))

- Typo in documentation. Can now generate again. [\#20](https://github.com/realm/realm-cocoa/pull/20) ([kspangsege](https://github.com/kspangsege))

- Xcode project [\#19](https://github.com/realm/realm-cocoa/pull/19) ([mekjaer](https://github.com/mekjaer))

- using correct compiler + added 2x default image [\#18](https://github.com/realm/realm-cocoa/pull/18) ([mekjaer](https://github.com/mekjaer))

- Renaming optimize references. [\#17](https://github.com/realm/realm-cocoa/pull/17) ([oleks](https://github.com/oleks))

## [v0.1.6](https://github.com/realm/realm-cocoa/tree/v0.1.6) (2014-02-04)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.1.5...v0.1.6)

**Merged pull requests:**

- Now using new Descriptor based API \(Spec is no longer a public class\) [\#16](https://github.com/realm/realm-cocoa/pull/16) ([kspangsege](https://github.com/kspangsege))

## [v0.1.5](https://github.com/realm/realm-cocoa/tree/v0.1.5) (2013-12-19)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.1.4...v0.1.5)

**Merged pull requests:**

- v.0.1.5 [\#15](https://github.com/realm/realm-cocoa/pull/15) ([bmunkholm](https://github.com/bmunkholm))

- added xcode project to examples [\#14](https://github.com/realm/realm-cocoa/pull/14) ([mekjaer](https://github.com/mekjaer))

## [v0.1.4](https://github.com/realm/realm-cocoa/tree/v0.1.4) (2013-12-07)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.1.3...v0.1.4)

## [v0.1.3](https://github.com/realm/realm-cocoa/tree/v0.1.3) (2013-11-11)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.1.2...v0.1.3)

## [v0.1.2](https://github.com/realm/realm-cocoa/tree/v0.1.2) (2013-11-08)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.1.1...v0.1.2)

**Merged pull requests:**

- Update examples [\#12](https://github.com/realm/realm-cocoa/pull/12) ([mekjaer](https://github.com/mekjaer))

## [v0.1.1](https://github.com/realm/realm-cocoa/tree/v0.1.1) (2013-10-16)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.1.0...v0.1.1)

**Merged pull requests:**

- Subtable assigment issue fixed. [\#11](https://github.com/realm/realm-cocoa/pull/11) ([jjepsen](https://github.com/jjepsen))

- Adds new unit test for cursors. [\#10](https://github.com/realm/realm-cocoa/pull/10) ([jjepsen](https://github.com/jjepsen))

- Objc query leak fix [\#9](https://github.com/realm/realm-cocoa/pull/9) ([jjepsen](https://github.com/jjepsen))

- Fix for memory leakage when typed tables are created in a group. [\#8](https://github.com/realm/realm-cocoa/pull/8) ([jjepsen](https://github.com/jjepsen))

## [v0.1.0](https://github.com/realm/realm-cocoa/tree/v0.1.0) (2013-10-04)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.30...v0.1.0)

## [v0.0.30](https://github.com/realm/realm-cocoa/tree/v0.0.30) (2013-10-03)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.29...v0.0.30)

## [v0.0.29](https://github.com/realm/realm-cocoa/tree/v0.0.29) (2013-10-03)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.28...v0.0.29)

**Merged pull requests:**

- Tutorial \(./examples/tutorial.m\) ready for inspection and upload if found ok. [\#6](https://github.com/realm/realm-cocoa/pull/6) ([jjepsen](https://github.com/jjepsen))

## [v0.0.28](https://github.com/realm/realm-cocoa/tree/v0.0.28) (2013-06-26)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.27...v0.0.28)

## [v0.0.27](https://github.com/realm/realm-cocoa/tree/v0.0.27) (2013-06-26)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.26...v0.0.27)

**Merged pull requests:**

- A 'config' step has been introduced into the build procedure. [\#7](https://github.com/realm/realm-cocoa/pull/7) ([kspangsege](https://github.com/kspangsege))

- Added documentation. Moved and cleaned up tutorial.  [\#5](https://github.com/realm/realm-cocoa/pull/5) ([jjepsen](https://github.com/jjepsen))

## [v0.0.26](https://github.com/realm/realm-cocoa/tree/v0.0.26) (2013-05-29)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.25...v0.0.26)

## [v0.0.25](https://github.com/realm/realm-cocoa/tree/v0.0.25) (2013-05-16)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.24b...v0.0.25)

## [v0.0.24b](https://github.com/realm/realm-cocoa/tree/v0.0.24b) (2013-05-03)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.24...v0.0.24b)

**Merged pull requests:**

- Explicit string size - Obj-C [\#4](https://github.com/realm/realm-cocoa/pull/4) ([kspangsege](https://github.com/kspangsege))

## [v0.0.24](https://github.com/realm/realm-cocoa/tree/v0.0.24) (2013-03-12)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.23...v0.0.24)

## [v0.0.23](https://github.com/realm/realm-cocoa/tree/v0.0.23) (2013-03-12)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.22...v0.0.23)

## [v0.0.22](https://github.com/realm/realm-cocoa/tree/v0.0.22) (2013-02-28)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.21...v0.0.22)

**Merged pull requests:**

- Updated tutorial [\#3](https://github.com/realm/realm-cocoa/pull/3) ([kneth](https://github.com/kneth))

## [v0.0.21](https://github.com/realm/realm-cocoa/tree/v0.0.21) (2013-02-26)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.20...v0.0.21)

## [v0.0.20](https://github.com/realm/realm-cocoa/tree/v0.0.20) (2013-02-26)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.19...v0.0.20)

**Merged pull requests:**

- Support for 'float' and 'double' column types and a lot of other fixes [\#2](https://github.com/realm/realm-cocoa/pull/2) ([kspangsege](https://github.com/kspangsege))

- Column type rename [\#1](https://github.com/realm/realm-cocoa/pull/1) ([kspangsege](https://github.com/kspangsege))

## [v0.0.19](https://github.com/realm/realm-cocoa/tree/v0.0.19) (2013-01-14)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.18...v0.0.19)

## [v0.0.18](https://github.com/realm/realm-cocoa/tree/v0.0.18) (2012-12-17)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.17...v0.0.18)

## [v0.0.17](https://github.com/realm/realm-cocoa/tree/v0.0.17) (2012-12-17)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.16...v0.0.17)

## [v0.0.16](https://github.com/realm/realm-cocoa/tree/v0.0.16) (2012-11-16)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.15...v0.0.16)

## [v0.0.15](https://github.com/realm/realm-cocoa/tree/v0.0.15) (2012-11-15)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.14...v0.0.15)

## [v0.0.14](https://github.com/realm/realm-cocoa/tree/v0.0.14) (2012-10-31)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.13...v0.0.14)

## [v0.0.13](https://github.com/realm/realm-cocoa/tree/v0.0.13) (2012-10-08)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.12...v0.0.13)

## [v0.0.12](https://github.com/realm/realm-cocoa/tree/v0.0.12) (2012-10-08)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.11...v0.0.12)

## [v0.0.11](https://github.com/realm/realm-cocoa/tree/v0.0.11) (2012-10-04)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.10...v0.0.11)

## [v0.0.10](https://github.com/realm/realm-cocoa/tree/v0.0.10) (2012-10-04)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.9...v0.0.10)

## [v0.0.9](https://github.com/realm/realm-cocoa/tree/v0.0.9) (2012-09-07)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.8...v0.0.9)

## [v0.0.8](https://github.com/realm/realm-cocoa/tree/v0.0.8) (2012-09-07)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.7...v0.0.8)

## [v0.0.7](https://github.com/realm/realm-cocoa/tree/v0.0.7) (2012-09-07)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.6...v0.0.7)

## [v0.0.6](https://github.com/realm/realm-cocoa/tree/v0.0.6) (2012-09-07)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.5...v0.0.6)

## [v0.0.5](https://github.com/realm/realm-cocoa/tree/v0.0.5) (2012-09-07)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.4...v0.0.5)

## [v0.0.4](https://github.com/realm/realm-cocoa/tree/v0.0.4) (2012-09-07)

[Full Changelog](https://github.com/realm/realm-cocoa/compare/v0.0.3...v0.0.4)

## [v0.0.3](https://github.com/realm/realm-cocoa/tree/v0.0.3) (2012-08-29)



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
# Filter Data - Swift SDK
## Overview
To filter data in your realm, you can leverage
Realm's query engine.

> Version added: 10.19.0
>

The Realm Swift Query API offers an
idiomatic way for Swift developers to query data. Use Swift-style syntax
to query a realm with the benefits of auto-completion and
type safety. The Realm Swift Query API does not replace the NSPredicate
Query API in newer SDK versions; instead, you can use either.

For SDK versions prior to 10.19.0, or for Objective-C developers,
Realm's query engine supports NSPredicate Query.

## About the Examples on This Page
The examples in this page use a simple data set for a
task list app. The two Realm object types are `Project`
and `Task`. A `Task` has a name, assignee's name, and
completed flag. There is also an arbitrary number for
priority -- higher is more important -- and a count of
minutes spent working on it. Finally, a `Task` can have one
or more string `labels` and one or more integer `ratings`.

A `Project` has zero or more `Tasks`.

See the schema for these two classes, `Project` and
`Task`, below:

#### Objective-C

```objectivec
// Task.h
@interface Task : RLMObject
@property NSString *name;
@property bool isComplete;
@property NSString *assignee;
@property int priority;
@property int progressMinutes;
@end
RLM_COLLECTION_TYPE(Task)
// Task.m
@implementation Task
@end

// Project.h
@interface Project : RLMObject
@property NSString *name;
@property RLMArray<Task> *tasks;
@end
// Project.m
@implementation Project
@end

```

#### Swift

```swift
class Task: Object {
    @Persisted var name = ""
    @Persisted var isComplete = false
    @Persisted var assignee: String?
    @Persisted var priority = 0
    @Persisted var progressMinutes = 0
    @Persisted var labels: MutableSet<String>
    @Persisted var ratings: MutableSet<Int>
}

class Project: Object {
    @Persisted var name = ""
    @Persisted var tasks: List<Task>
}

```

You can set up the realm for these examples with the following code:

#### Objective-C

```objectivec
RLMRealm *realm = [RLMRealm defaultRealm];
[realm transactionWithBlock:^() {
    // Add projects and tasks here
}];

RLMResults *tasks = [Task allObjectsInRealm:realm];
RLMResults *projects = [Project allObjectsInRealm:realm];

```

#### Swift

```swift
let realm = try! Realm()
try! realm.write {
    // Add tasks and projects here.
    let project = Project()
    project.name = "New Project"
    let task = Task()
    task.assignee = "Alex"
    task.priority = 5
    project.tasks.append(task)
    realm.add(project)
    // ...
}
let tasks = realm.objects(Task.self)
let projects = realm.objects(Project.self)

```

## Realm Swift Query API
> Version added: 10.19.0
> For SDK versions older than 10.19.0, use the NSPredicate query API.
>

You can build a filter with Swift-style syntax using the `.where`
`Realm Swift query API`:

```swift
let realmSwiftQuery = projects.where {
    ($0.tasks.progressMinutes > 1) && ($0.tasks.assignee == "Ali")
}

```

This query API constructs an NSPredicate
to perform the query. It gives developers a type-safe idiomatic API to
use directly, and abstracts away the NSPredicate construction.

The `.where` API takes a callback that evaluates to true or false. The
callback receives an instance of the type being queried, and you can
leverage the compiler to statically check that you are creating valid queries
that reference valid properties.

In the examples on this page, we use the `$0` shorthand to reference
the variable passed into the callback.

### Operators
There are several types of operators available to query a
Realm collection. Queries
work by **evaluating** an operator expression for every
object in the collection being
queried. If the expression resolves to `true`, Realm
Database includes the object in the results collection.

#### Comparison Operators
You can use Swift comparison operators with the Realm Swift
Query API (`==`, `!=`, `>`, `>=`, `<`, `<=`).

> Example:
> The following example uses the query engine's
comparison operators to:
>
> - Find high priority tasks by comparing the value of the `priority` property value with a threshold number, above which priority can be considered high.
> - Find long-running tasks by seeing if the `progressMinutes` property is at or above a certain value.
> - Find unassigned tasks by finding tasks where the `assignee` property is equal to `null`.
>
> ```swift
> let highPriorityTasks = tasks.where {
>     $0.priority > 5
> }
> print("High-priority tasks: \(highPriorityTasks.count)")
>
> let longRunningTasks = tasks.where {
>     $0.progressMinutes >= 120
> }
> print("Long running tasks: \(longRunningTasks.count)")
>
> let unassignedTasks = tasks.where {
>     $0.assignee == nil
> }
> print("Unassigned tasks: \(unassignedTasks.count)")
>
> ```
>

#### Collections
You can query for values within a collection using the `.contains` operators.
You can search for individual values by element, or search within a range.

|Operator|Description|
| --- | --- |
|.in(_ collection:)|Evaluates to `true` if the property referenced by the expression contains an element in the given array.|
|.contains(_ element:)|Equivalent to the `IN` operator. Evaluates to `true` if the property referenced by the expression contains the value.|
|`.contains(_ range:)`|Equivalent to the `BETWEEN` operator. Evaluates to `true` if the property referenced by the expression contains a value that is within the range.|
|`.containsAny(in: )`|Equivalent to the `IN` operator combined with the `ANY` operator. Evaluates to `true` if any elements contained in the given array are present in the collection.|

> Example:
> - Find tasks where the `labels` MutableSet collection property contains "quick win".
> - Find tasks where the `progressMinutes` property is within a given range of minutes.
>
> ```swift
> let quickWinTasks = tasks.where {
>     $0.labels.contains("quick win")
> }
> print("Tasks labeled 'quick win': \(quickWinTasks.count)")
>
> let progressBetween30and60 = tasks.where {
>     $0.progressMinutes.contains(30...60)
> }
> print("Tasks with progress between 30 and 60 minutes: \(progressBetween30and60.count)")
>
> ```
>
> Find tasks where the `labels` MutableSet collection property contains any of the elements in the given array: "quick win" or "bug".
>
> ```swift
> let quickWinOrBugTasks = tasks.where {
>     $0.labels.containsAny(in: ["quick win", "bug"])
> }
> print("Tasks labeled 'quick win' or 'bug': \(quickWinOrBugTasks.count)")
>
> ```
>

> Version added: 10.23.0
> :The `IN` operator
>

The Realm Swift Query API now supports the `IN` operator. Evaluates to `true` if the property referenced by the expression contains the value.

> Example:
> Find tasks assigned to specific teammates Ali or Jamie by seeing if the `assignee` property is in a list of names.
>
> ```swift
> let taskAssigneeInAliOrJamie = tasks.where {
>     let assigneeNames = ["Ali", "Jamie"]
>     return $0.assignee.in(assigneeNames)
> }
> print("Tasks IN Ali or Jamie: \(taskAssigneeInAliOrJamie.count)")
>
> ```
>

#### Logical Operators
You can make compound queries using Swift logical operators (`&&`, `!`,
`||`).

> Example:
> We can use the query language's logical operators to find
all of Ali's completed tasks. That is, we find all tasks
where the `assignee` property value is equal to 'Ali' AND
the `isComplete` property value is `true`:
>
> ```swift
> let aliComplete = tasks.where {
>     ($0.assignee == "Ali") && ($0.isComplete == true)
> }
> print("Ali's complete tasks: \(aliComplete.count)")
>
> ```
>

#### String Operators
You can compare string values using these string operators.
Regex-like wildcards allow more flexibility in search.

> Note:
> You can use the following options with string operators:
>
> - `.caseInsensitive` for case insensitivity. `$0.name.contains("f", options: .caseInsensitive)`
> - `.diacriticInsensitive` for diacritic insensitivity: Realm treats
special characters as the base character (e.g. `é` -> `e`). `$0.name.contains("e", options: .diacriticInsensitive)`
>

|Operator|Description|
| --- | --- |
|.starts(with value: String)|Evaluates to `true` if the collection contains an element whose value begins with the specified string value.|
|.contains(_ value: String)|Evaluates to `true` if the left-hand string expression is found anywhere in the right-hand string expression.|
|.ends(with value: String)|Evaluates to `true` if the collection contains an element whose value ends with the specified string value.|
|.like(_ value: String)|Evaluates to `true` if the left-hand string expression matches the right-hand string wildcard string expression. A wildcard string expression is a string that uses normal characters with two special wildcard characters: The `*` wildcard matches zero or more of any character The `?` wildcard matches any character. For example, the wildcard string "d?g" matches "dog", "dig", and "dug", but not "ding", "dg", or "a dog".|
|==|Evaluates to `true` if the left-hand string is lexicographically equal to the right-hand string.|
|!=|Evaluates to `true` if the left-hand string is not lexicographically equal to the right-hand string.|

> Example:
> The following example uses the query engine's string operators to find:
>
> - Projects with a name starting with the letter 'e'
> - Projects with names that contain 'ie'
> - Projects with an `assignee` property whose value is similar to `Al?x`
> - Projects that contain e-like characters with diacritic insensitivity
>
> ```swift
> // Use the .caseInsensitive option for case-insensitivity.
> let startWithE = projects.where {
>     $0.name.starts(with: "e", options: .caseInsensitive)
> }
> print("Projects that start with 'e': \(startWithE.count)")
>
> let containIe = projects.where {
>     $0.name.contains("ie")
> }
> print("Projects that contain 'ie': \(containIe.count)")
>
> let likeWildcard = tasks.where {
>     $0.assignee.like("Al?x")
> }
> print("Tasks with assignees like Al?x: \(likeWildcard.count)")
>
> // Use the .diacriticInsensitive option for diacritic insensitivity: contains 'e', 'E', 'é', etc.
> let containElike = projects.where {
>     $0.name.contains("e", options: .diacriticInsensitive)
> }
> print("Projects that contain 'e', 'E', 'é', etc.: \(containElike.count)")
>
> ```
>

> Note:
> String sorting and case-insensitive queries are only supported for
character sets in 'Latin Basic', 'Latin Supplement', 'Latin Extended
A', and 'Latin Extended B' (UTF-8 range 0-591).
>

#### Geospatial Operators
> Version added: 10.47.0

Use the `geoWithin` operator to query geospatial data with one of the
SDK's provided shapes:

- `GeoCircle`
- `GeoBox`
- `GeoPolygon`

This operator evaluates to `true` if:

- An object has a geospatial data "shape" containing a `String` property
with the value of Point and a `List` containing a longitude/latitude
pair.
- The longitude/latitude of the persisted object falls within the geospatial
query shape.

```swift
let companiesInSmallCircle = realm.objects(Geospatial_Company.self).where {
    $0.location.geoWithin(smallCircle!)
}
print("Number of companies in small circle: \(companiesInSmallCircle.count)")

```

For more information about querying geospatial data, refer to
Query Geospatial Data.

#### Aggregate Operators
You can apply an aggregate operator to a collection property
of a Realm object. Aggregate operators traverse a
collection and reduce it
to a single value.

|Operator|Description|
| --- | --- |
|.avg|Evaluates to the average value of a given numerical property across a collection.|
|.count|Evaluates to the number of objects in the given collection. This is currently only supported on to-many relationship collections and not on lists of primitives. In order to use `.count` on a list of primitives, consider wrapping the primitives in a Realm object.|
|.max|Evaluates to the highest value of a given numerical property across a collection.|
|.min|Evaluates to the lowest value of a given numerical property across a collection.|
|.sum|Evaluates to the sum of a given numerical property across a collection.|

> Example:
> We create a couple of filters to show different facets of
the data:
>
> - Projects with average tasks priority above 5.
> - Projects that contain only low-priority tasks below 5.
> - Projects where all tasks are high-priority above 5.
> - Projects that contain more than 5 tasks.
> - Long running projects.
>
> ```swift
> let averageTaskPriorityAbove5 = projects.where {
>     $0.tasks.priority.avg > 5
> }
> print("Projects with average task priority above 5: \(averageTaskPriorityAbove5.count)")
>
> let allTasksLowerPriority = projects.where {
>     $0.tasks.priority.max < 5
> }
> print("Projects where all tasks are lower priority: \(allTasksLowerPriority.count)")
>
> let allTasksHighPriority = projects.where {
>     $0.tasks.priority.min > 5
> }
> print("Projects where all tasks are high priority: \(allTasksHighPriority.count)")
>
> let moreThan5Tasks = projects.where {
>     $0.tasks.count > 5
> }
> print("Projects with more than 5 tasks: \(moreThan5Tasks.count)")
>
> let longRunningProjects = projects.where {
>     $0.tasks.progressMinutes.sum > 100
> }
> print("Long running projects: \(longRunningProjects.count)")
>
> ```
>

#### Set Operators
A **set operator** uses specific rules to determine whether
to pass each input collection object to the output
collection by applying a given query expression to every element of
a given list property of
the object.

> Example:
> Running the following queries in `projects` collections returns:
>
> - Projects where a set of string `labels` contains any of "quick win", "bug".
> - Projects where any element in a set of integer `ratings` is greater than 3.
>
> ```swift
> let projectsWithGivenLabels = projects.where {
>     $0.tasks.labels.containsAny(in: ["quick win", "bug"])
> }
> print("Projects with quick wins: \(projectsWithGivenLabels.count)")
>
> let projectsWithRatingsOver3 = projects.where {
>     $0.tasks.ratings > 3
> }
> print("Projects with any ratings over 3: \(projectsWithRatingsOver3.count)")
>
> ```
>

### Subqueries
You can iterate through a collection property with another query using a
subquery. To form a subquery, you must wrap the expression in parentheses
and immediately follow it with the `.count` aggregator.

```swift
(<query>).count > n
```

If the expression does not produce a valid subquery, you'll get an
exception at runtime.

> Example:
> Running the following query on a `projects` collection returns projects
with tasks that have not been completed by a user named Alex.
>
> ```swift
> let subquery = projects.where {
>             ($0.tasks.isComplete == false && $0.tasks.assignee == "Alex").count > 0
> }
> print("Projects with incomplete tasks assigned to Alex: \(subquery.count)")
>
> ```
>

## NSPredicate Queries
You can build a filter with NSPredicate:

#### Objective-C

```objectivec
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"progressMinutes > %@ AND name == %@", @1, @"Ali"];

```

#### Swift

```swift
let predicate = NSPredicate(format: "progressMinutes > 1 AND name == %@", "Ali")

```

### Expressions
Filters consist of **expressions** in an NSPredicate. An expression consists of
one of the following:

- The name (keypath) of a property of the object currently being evaluated.
- An operator and up to two argument expression(s).
- A value, such as a string (`'hello'`) or a number (`5`).

### Dot Notation
When referring to an object property, you can use **dot notation** to refer
to child properties of that object. You can even refer to the properties of
embedded objects and relationships with dot notation.

For example, consider a query on an object with a `workplace` property that
refers to a Workplace object. The Workplace object has an embedded object
property, `address`. You can chain dot notations to refer to the zipcode
property of that address:

```objective-c
workplace.address.zipcode == 10012
```

### Substitutions
You can use the following substitutions in your predicate format strings:

- `%@` to specify values
- `%K` to specify [keypaths](https://docs.swift.org/swift-book/ReferenceManual/Expressions.html#grammar_key-path-expression)

#### Objective-C

```objectivec
[NSPredicate predicateWithFormat:@"%K > %@ AND %K == %@", @"progressMinutes", @1, @"name", @"Ali"];

```

#### Swift

```swift
NSPredicate(format: "%K > %@ AND %K == %@", "progressMinutes", NSNumber(1), "name", "Ali")

```

### Operators
There are several types of operators available to filter a
Realm collection. Filters
work by **evaluating** an operator expression for every
object in the collection being
filtered. If the expression resolves to `true`, Realm
Database includes the object in the results collection.

#### Comparison Operators
The most straightforward operation in a search is to compare
values.

> Important:
> The type on both sides of the operator must be equivalent. For
example, comparing an ObjectId with string will result in a precondition failure with a
message like:
>
> ```
> "Expected object of type object id for property 'id' on object of type
> 'User', but received: 11223344556677889900aabb (Invalid value)"
> ```
>
> You can compare any numeric type with any other numeric type.
>

|Operator|Description|
| --- | --- |
|`between`|Evaluates to `true` if the left-hand numerical or date expression is between or equal to the right-hand range. For dates, this evaluates to `true` if the left-hand date is within the right-hand date range.|
|== , =|Evaluates to `true` if the left-hand expression is equal to the right-hand expression.|
|>|Evaluates to `true` if the left-hand numerical or date expression is greater than the right-hand numerical or date expression. For dates, this evaluates to `true` if the left-hand date is later than the right-hand date.|
|>=|Evaluates to `true` if the left-hand numerical or date expression is greater than or equal to the right-hand numerical or date expression. For dates, this evaluates to `true` if the left-hand date is later than or the same as the right-hand date.|
|`in`|Evaluates to `true` if the left-hand expression is in the right-hand list or string.|
|<|Evaluates to `true` if the left-hand numerical or date expression is less than the right-hand numerical or date expression. For dates, this evaluates to `true` if the left-hand date is earlier than the right-hand date.|
|<=|Evaluates to `true` if the left-hand numeric expression is less than or equal to the right-hand numeric expression. For dates, this evaluates to `true` if the left-hand date is earlier than or the same as the right-hand date.|
|!= , <>|Evaluates to `true` if the left-hand expression is not equal to the right-hand expression.|

> Example:
> The following example uses the query engine's
comparison operators to:
>
> - Find high priority tasks by comparing the value of the `priority` property value with a threshold number, above which priority can be considered high.
> - Find long-running tasks by seeing if the `progressMinutes` property is at or above a certain value.
> - Find unassigned tasks by finding tasks where the `assignee` property is equal to `null`.
> - Find tasks assigned to specific teammates Ali or Jamie by seeing if the `assignee` property is in a list of names.
>
> #### Objective-C
>
> ```objectivec
> NSLog(@"High priority tasks: %lu",
>       [[tasks objectsWithPredicate:[NSPredicate predicateWithFormat:@"priority > %@", @5]] count]);
>
> NSLog(@"Short running tasks: %lu",
>       [[tasks objectsWhere:@"progressMinutes between {1, 15}"] count]);
>
> NSLog(@"Unassigned tasks: %lu",
>       [[tasks objectsWhere:@"assignee == nil"] count]);
>
> NSLog(@"Ali or Jamie's tasks: %lu",
>       [[tasks objectsWhere:@"assignee IN {'Ali', 'Jamie'}"] count]);
>
> NSLog(@"Tasks with progress between 30 and 60 minutes: %lu",
>       [[tasks objectsWhere:@"progressMinutes BETWEEN {30, 60}"] count]);
>
>
> ```
>
>
> #### Swift
>
> ```swift
> let highPriorityTasks = tasks.filter("priority > 5")
> print("High priority tasks: \(highPriorityTasks.count)")
>
> let longRunningTasks = tasks.filter("progressMinutes > 120")
> print("Long running tasks: \(longRunningTasks.count)")
>
> let unassignedTasks = tasks.filter("assignee == nil")
> print("Unassigned tasks: \(unassignedTasks.count)")
>
> let aliOrJamiesTasks = tasks.filter("assignee IN {'Ali', 'Jamie'}")
> print("Ali or Jamie's tasks: \(aliOrJamiesTasks.count)")
>
> let progressBetween30and60 = tasks.filter("progressMinutes BETWEEN {30, 60}")
> print("Tasks with progress between 30 and 60 minutes: \(progressBetween30and60.count)")
>
> ```
>
>

#### Logical Operators
You can make compound predicates using logical operators.

|Operator|Description|
| --- | --- |
|and &&|Evaluates to `true` if both left-hand and right-hand expressions are `true`.|
|not !|Negates the result of the given expression.|
|or \\|\\||Evaluates to `true` if either expression returns `true`.|

> Example:
> We can use the query language's logical operators to find
all of Ali's completed tasks. That is, we find all tasks
where the `assignee` property value is equal to 'Ali' AND
the `isComplete` property value is `true`:
>
> #### Objective-C
>
> ```objectivec
> NSLog(@"Ali's complete tasks: %lu",
>   [[tasks objectsWhere:@"assignee == 'Ali' AND isComplete == true"] count]);
>
> ```
>
>
> #### Swift
>
> ```swift
> let aliComplete = tasks.filter("assignee == 'Ali' AND isComplete == true")
> print("Ali's complete tasks: \(aliComplete.count)")
>
> ```
>
>

#### String Operators
You can compare string values using these string operators.
Regex-like wildcards allow more flexibility in search.

> Note:
> You can use the following modifiers with the string operators:
>
> - `[c]` for case insensitivity. `[NSPredicate predicateWithFormat: @"name CONTAINS[c] 'f'"]``NSPredicate(format: "name CONTAINS[c] 'f'")`
> - `[d]` for diacritic insensitivity: Realm treats special characters as the base character (e.g. `é` -> `e`). `[NSPredicate predicateWithFormat: @"name CONTAINS[d] 'e'"]``NSPredicate(format: "name CONTAINS[d] 'e'")`
>

|Operator|Description|
| --- | --- |
|beginsWith|Evaluates to `true` if the left-hand string expression begins with the right-hand string expression. This is similar to `contains`, but only matches if the right-hand string expression is found at the beginning of the left-hand string expression.|
|contains , in|Evaluates to `true` if the left-hand string expression is found anywhere in the right-hand string expression.|
|endsWith|Evaluates to `true` if the left-hand string expression ends with the right-hand string expression. This is similar to `contains`, but only matches if the left-hand string expression is found at the very end of the right-hand string expression.|
|like|Evaluates to `true` if the left-hand string expression matches the right-hand string wildcard string expression. A wildcard string expression is a string that uses normal characters with two special wildcard characters: The `*` wildcard matches zero or more of any character The `?` wildcard matches any character. For example, the wildcard string "d?g" matches "dog", "dig", and "dug", but not "ding", "dg", or "a dog".|
|== , =|Evaluates to `true` if the left-hand string is lexicographically equal to the right-hand string.|
|!= , <>|Evaluates to `true` if the left-hand string is not lexicographically equal to the right-hand string.|

> Example:
> We use the query engine's string operators to find
projects with a name starting with the letter 'e' and
projects with names that contain 'ie':
>
> #### Objective-C
>
> ```objectivec
> // Use [c] for case-insensitivity.
> NSLog(@"Projects that start with 'e': %lu",
>   [[projects objectsWhere:@"name BEGINSWITH[c] 'e'"] count]);
>
> NSLog(@"Projects that contain 'ie': %lu",
>   [[projects objectsWhere:@"name CONTAINS 'ie'"] count]);
>
> ```
>
>
> #### Swift
>
> ```swift
> // Use [c] for case-insensitivity.
> let startWithE = projects.filter("name BEGINSWITH[c] 'e'")
> print("Projects that start with 'e': \(startWithE.count)")
>
> let containIe = projects.filter("name CONTAINS 'ie'")
> print("Projects that contain 'ie': \(containIe.count)")
>
> // [d] for diacritic insensitivty: contains 'e', 'E', 'é', etc.
> let containElike = projects.filter("name CONTAINS[cd] 'e'")
> print("Projects that contain 'e', 'E', 'é', etc.: \(containElike.count)")
>
> ```
>
>

> Note:
> String sorting and case-insensitive queries are only supported for
character sets in 'Latin Basic', 'Latin Supplement', 'Latin Extended
A', and 'Latin Extended B' (UTF-8 range 0-591).
>

#### Geospatial Operators
> Version added: 10.47.0

You can perform a geospatial query using the `IN` operator with one
of the SDK's provided shapes:

- `GeoCircle`
- `GeoBox`
- `GeoPolygon`

This operator evaluates to `true` if:

- An object has a geospatial data "shape" containing a `String` property
with the value of Point and a `List` containing a longitude/latitude
pair.
- The longitude/latitude of the persisted object falls within the geospatial
query shape.

```swift
let filterArguments = NSMutableArray()
filterArguments.add(largeBox)
let companiesInLargeBox = realm.objects(Geospatial_Company.self)
    .filter(NSPredicate(format: "location IN %@", argumentArray: filterArguments as? [Any]))
print("Number of companies in large box: \(companiesInLargeBox.count)")

```

For more information about querying geospatial data, refer to
Query Geospatial Data.

#### Aggregate Operators
You can apply an aggregate operator to a collection property
of a Realm object. Aggregate operators traverse a
collection and reduce it
to a single value.

|Operator|Description|
| --- | --- |
|@avg|Evaluates to the average value of a given numerical property across a collection.|
|@count|Evaluates to the number of objects in the given collection. This is currently only supported on to-many relationship collections and not on lists of primitives. In order to use `@count` on a list of primitives, consider wrapping the primitives in a Realm object.|
|@max|Evaluates to the highest value of a given numerical property across a collection.|
|@min|Evaluates to the lowest value of a given numerical property across a collection.|
|@sum|Evaluates to the sum of a given numerical property across a collection.|

> Example:
> We create a couple of filters to show different facets of
the data:
>
> - Projects with average tasks priority above 5.
> - Long running projects.
>
> #### Objective-C
>
> ```objectivec
> NSLog(@"Projects with average tasks priority above 5: %lu",
>       [[projects objectsWhere:@"tasks.@avg.priority > 5"] count]);
>
> NSLog(@"Projects where all tasks are lower priority: %lu",
>       [[projects objectsWhere:@"tasks.@max.priority < 5"] count]);
>
> NSLog(@"Projects where all tasks are high priority: %lu",
>       [[projects objectsWhere:@"tasks.@min.priority > 5"] count]);
>
> NSLog(@"Projects with more than 5 tasks: %lu",
>       [[projects objectsWhere:@"tasks.@count > 5"] count]);
>
> NSLog(@"Long running projects: %lu",
>       [[projects objectsWhere:@"tasks.@sum.progressMinutes > 100"] count]);
>
> ```
>
>
> #### Swift
>
> ```swift
> let averageTaskPriorityAbove5 = projects.filter("tasks.@avg.priority > 5")
> print("Projects with average task priority above 5: \(averageTaskPriorityAbove5.count)")
>
> let allTasksLowerPriority = projects.filter("tasks.@max.priority < 5")
> print("Projects where all tasks are lower priority: \(allTasksLowerPriority.count)")
>
> let allTasksHighPriority = projects.filter("tasks.@min.priority > 5")
> print("Projects where all tasks are high priority: \(allTasksHighPriority.count)")
>
> let moreThan5Tasks = projects.filter("tasks.@count > 5")
> print("Projects with more than 5 tasks: \(moreThan5Tasks.count)")
>
> let longRunningProjects = projects.filter("tasks.@sum.progressMinutes > 100")
> print("Long running projects: \(longRunningProjects.count)")
>
> ```
>
>

#### Set Operators
A **set operator** uses specific rules to determine whether
to pass each input collection object to the output
collection by applying a given predicate to every element of
a given list property of
the object.

|Operator|Description|
| --- | --- |
|`ALL`|Returns objects where the predicate evaluates to `true` for all objects in the collection.|
|`ANY`, `SOME`|Returns objects where the predicate evaluates to `true` for any objects in the collection.|
|`NONE`|Returns objects where the predicate evaluates to false for all objects in the collection.|

> Example:
> We use the query engine's set operators to find:
>
> - Projects with no complete tasks.
> - Projects with any top priority tasks.
>
> #### Objective-C
>
> ```objectivec
> NSLog(@"Projects with no complete tasks: %lu",
>   [[projects objectsWhere:@"NONE tasks.isComplete == true"] count]);
>
> NSLog(@"Projects with any top priority tasks: %lu",
>   [[projects objectsWhere:@"ANY tasks.priority == 10"] count]);
>
> ```
>
>
> #### Swift
>
> ```swift
> let noCompleteTasks = projects.filter("NONE tasks.isComplete == true")
> print("Projects with no complete tasks: \(noCompleteTasks.count)")
>
> let anyTopPriorityTasks = projects.filter("ANY tasks.priority == 10")
> print("Projects with any top priority tasks: \(anyTopPriorityTasks.count)")
>
> ```
>
>

### Subqueries
You can iterate through a collection property with another query using the
`SUBQUERY()` predicate function. `SUBQUERY()` has the following signature:

```objective-c
SUBQUERY(<collection>, <variableName>, <predicate>)
```

- `collection`: the name of the list property to iterate through
- `variableName`: a variable name of the current element to use in the subquery
- `predicate`: a string that contains the subquery predicate. You can use the
variable name specified by `variableName` to refer to the currently iterated
element.

> Example:
> Running the following filter on a `projects` collection returns projects
with tasks that have not been completed by a user named Alex.
>
> #### Objective-C
>
> ```objectivec
> NSPredicate *predicate = [NSPredicate predicateWithFormat:
>                           @"SUBQUERY(tasks, $task, $task.isComplete == %@ AND $task.assignee == %@).@count > 0",
>                           @NO,
>                           @"Alex"];
> NSLog(@"Projects with incomplete tasks assigned to Alex: %lu",
>   [[projects objectsWithPredicate:predicate] count]);
>
> ```
>
>
> #### Swift
>
> ```swift
> let predicate = NSPredicate(
>     format: "SUBQUERY(tasks, $task, $task.isComplete == false AND $task.assignee == %@).@count > 0", "Alex")
> print("Projects with incomplete tasks assigned to Alex: \(projects.filter(predicate).count)")
>
> ```
>
>

Category 1: Errors for "expected" problems 
==========================================
Characterized by: File access problem, network access problems.... User should be informed. Problems which cannot be eliminated during development.

Examples:

    (TightdbGroup *)groupWithFilename:(NSString *)filename error:(NSError *__autoreleasing *)error;

    -(BOOL)write:(NSString *)filePath error:(NSError *__autoreleasing *)error;


Category 2: Exceptions for "unexpected" problems - no recovery 
==============================================================
Characterized by: Fatal errors. Wrong use of API. Application should just crash. Problems which should be eliminated during development.

Examples:

- Indexing out of bounds.
- Passing illegal parameter type.
- Writing to read only table (working assumption).
- Core library exception.

(Category 3: Exceptions for "unexpected" problems - with recovery)
==================================================================
Technically possible with ARC safe exceptions flag. Leads to excessive release code (automatically inserted). 

Not recommended.









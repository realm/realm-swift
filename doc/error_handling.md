Category 1: NSError for "expected" problems 
===========================================
Characterized by: File access problem, network access problems.... User should be informed. Problems which cannot be eliminated during development.

- Writing a group to a file, with file access problems.


Category 2: NSException for "unexpected" problems - no recovery 
===============================================================
Characterized by: Fatal errors. Wrong use of API. Application should rightfully crash. These problems should be eliminated during development. Feedback should be fast and direct in the form of an exception. The 
application should not attempt to catch the exception.

- Indexing out of bounds.
- Passing illegal parameter type.
- Writing to read only table (working assumption).
- Core library exceptions.


Category 3: NSException for "unexpected" problems - with recovery
=================================================================
Technically possible with ARC safe exceptions flag. Leads to excessive release code (automatically inserted). Should not be needed.









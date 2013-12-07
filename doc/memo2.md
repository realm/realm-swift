Objective-C Dynamic API: Dynamic language features
==================================================

This document described a pre-study of using dymamic methods in Objective-C for adding methods to tables at runtime. The idea was to generate typed setters and getters for column names dynamically and which would allow for use of column names in method names (without code completion, however).

Adding methods
--------------
Methods can be added at runtime with:

    class_addMethod([Dummy class], @selector(addedMethod), (IMP)newMethod, "v@:");

In this case the method name is defined by the selector. The selector created from a string as well.

Calling methods (sending messages to objects)
---------------------------------------------

    [object addedMethod];                              // works ONLY with ARC disabled
    [object performSelector:@selector(addedMethod)];   // works with our without ARC


Conclusion
----------
While it's possilbe to add methods dynamically, they cannot be called without ugly looking syntax (with ARC). In our case this syntax is not useful. Disabling ARC is not an option. Apple has responded on a blog to an inquery about why the methods cannot be called directly after ARC.

"Our reasoning was split about 50/50 between (1) needing to be more careful about types and ownership and (2) wanting to eliminate an embarrassing wart in the language (not being allowed to complain about completely unknown methods with anything more strenuous than a warning). There is really no legitimate reason to call a method that's not even declared somewhere. The ability to do this makes some really trivial bugs (e.g. typos in selectors) runtime failures instead of compile failures. We have always warned about it. Fix your code."

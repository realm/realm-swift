# Migration Examples

The Migration project shows several examples of migrations and migration blocks.

The purpose of this example is to provide a more in depth view of certain problems and pitfalls users might face when 
migrations get more complex and the number of versions increases.

## How to use the example

You can build and run the project as is. Migrations from all prior version to the current version will be checked:
   - v0 -> v5
   - v1 -> v5
   - v2 -> v5
   - v3 -> v5
   - v4 -> v5

The files to look at are located in the `Examples` folder. Every file contains an extract of everything necessary for
this version (schema version, objects, migration and migration checks).

If you want to compare older versions among each other (i.e. v2 -> v3) you can do so by enabling the schema version, for example:
   - Deactivate version 5 by setting `#define SCHEMA_VERSION_5 1` to `#define SCHEMA_VERSION_5 0` in `Example_v5.h`.
   - Activate version 3 by seting `#define SCHEMA_VERSION_3 0` to `#define SCHEMA_VERSION_3 1` in `Example_v3.h`.

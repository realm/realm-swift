===========
BSON Corpus
===========

:Status: Accepted
:Minimum Server Version: N/A

.. contents::

Abstract
========

The official BSON specification does not include test data, so this
pseudo-specification describes tests for BSON encoding and decoding.  It also
includes tests for MongoDB's "Extended JSON" specification (hereafter
abbreviated as ``extjson``).

Meta
====

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL" in this document are to be
interpreted as described in `RFC 2119`_.

.. _RFC 2119: https://www.ietf.org/rfc/rfc2119.txt

Motivation for Change
=====================

To ensure correct operation, we want drivers to implement identical tests
for important features.  BSON (and ``extjson``) are critical for correct
operation and data exchange, but historically had no common test corpus.
This pseudo-specification provides such tests.

Goals
-----

* Provide machine-readable test data files for BSON and ``extjson`` encoding
  and decoding.

* Cover all current and historical BSON types.

* Define test data patterns for three cases: (a) conversion/roundtrip, (b)
  decode errors, and (c) parse errors.

Non-Goals
---------

* Replace or extend the offical BSON spec at http://bsonspec.org.

* Provide a formal specification for ``extjson``.

Specification
=============

The specification for BSON lives at http://bsonspec.org.  The ``extjson``
format specification lives at
https://github.com/mongodb/specifications/blob/master/source/extended-json.rst.

Test Plan
=========

This test plan describes a general approach for BSON testing.  Future BSON
specifications (such as for new types like Decimal128) may specialize or
alter the approach described below.

Description of the BSON Corpus
------------------------------

This BSON test data corpus consists of a JSON file for each BSON type, plus
a ``top.json`` file for testing the overall, enclosing document and a
``multi-type.json`` file for testing a document with all BSON types.
There is also a ``multi-type-deprecated.json`` that includes deprecated keys.

Top level keys
~~~~~~~~~~~~~~

* ``description``: human-readable description of what is in the file

* ``bson_type``: hex string of the first byte of a BSON element (e.g. "0x01"
  for type "double"); this will be the synthetic value "0x00" for "whole
  document" tests like ``top.json``.

* ``test_key``: (optional) name of a field in a single-BSON-type ``valid`` test
  case that contains the data type being tested.

* ``valid`` (optional): an array of validity test cases (see below).

* ``decodeErrors`` (optional): an array of decode error cases (see below).

* ``parseErrors`` (optional): an array of type-specific parse error case (see
  below).

* ``deprecated`` (optional): this field will be present (and true) if the
  BSON type has been deprecated (i.e. Symbol, Undefined and DBPointer)

Validity test case keys
~~~~~~~~~~~~~~~~~~~~~~~

Validity test cases include 'canonical' forms of BSON and Extended JSON that
are deemed equivalent and may provide additional cases or metadata for
additional assertions.  For each case, keys include:

* ``description``: human-readable test case label.

* ``canonical_bson``: an (uppercase) big-endian hex representation of a BSON
  byte string.  Be sure to mangle the case as appropriate in any roundtrip
  tests.

* ``canonical_extjson``: a string containing a Canonical Extended JSON document.
  Because this is itself embedded as a *string* inside a JSON document,
  characters like quote and backslash are escaped.

* ``relaxed_extjson``: (optional) a string containing a Relaxed Extended JSON
  document.  Because this is itself embedded as a *string* inside a JSON
  document, characters like quote and backslash are escaped.

* ``degenerate_bson``: (optional) an (uppercase) big-endian hex representation
  of a BSON byte string that is technically parseable, but not in compliance
  with the BSON spec.  Be sure to mangle the case as appropriate in any
  roundtrip tests.

* ``degenerate_extjson``: (optional) a string containing an invalid form of
  Canonical Extended JSON that is still parseable according to type-specific
  rules.  (For example, "1e100" instead of "1E+100".)

* ``converted_bson``: (optional) an (uppercase) big-endian hex representation
  of a BSON byte string.  It may be present for deprecated types. It represents
  a possible conversion of the deprecated type to a non-deprecated type, e.g.
  symbol to string.

* ``converted_extjson``: (optional) a string containing a Canonical Extended
  JSON document.  Because this is itself embedded as a *string* inside a JSON
  document, characters like quote and backslash are escaped.  It may be
  present for deprecated types and is the Canonical Extended JSON
  representation of ``converted_bson``.

* ``lossy`` (optional) -- boolean; present (and true) iff ``canonical_bson``
  can't be represented exactly with extended JSON (e.g. NaN with a payload).

Decode error case keys
~~~~~~~~~~~~~~~~~~~~~~

Decode error cases provide an invalid BSON document or field that
should result in an error. For each case, keys include:

* ``description``: human-readable test case label.

* ``bson``: an (uppercase) big-endian hex representation of an invalid
  BSON string that should fail to decode correctly.

Parse error case keys
~~~~~~~~~~~~~~~~~~~~~

Parse error cases are type-specific and represent some input that can not
be encoded to the ``bson_type`` under test.  For each case, keys include:

* ``description``: human-readable test case label.

* ``string``: a text or numeric representation of an input that can't be
  parsed to a valid value of the given type.

Extended JSON encoding, escaping and ordering
---------------------------------------------

Because the ``canonical_extjson`` and other Extended JSON fields are embedded
in a JSON document, all their JSON metacharacters are escaped.  Control
characters and non-ASCII codepoints are represented with ``\uXXXX``.  Note that
this means that the corpus JSON will appear to have double-escaped characters
``\\uXXXX``.  This is by design to ensure that the Extended JSON fields remain
printable ASCII without embedded null characters to ensure maximum portability
to different language JSON or extended JSON decoders.

There are legal differences in JSON representation that may complicate
testing for particular codecs.  The JSON in the corpus may not resemble
the JSON generated by a codec, even though they represent the same data.
Some known differences include:

* JSON only requires certain characters to be escaped but allows any character
  to be escaped.

* The JSON format is *unordered* and whitespace (outside of strings) is not
  significant.

Implementations using these tests MUST normalize JSON comparisons however
necessary for effective comparison.

Language-specific differences
-----------------------------

Some programming languages may not be able to represent or transmit all
types accurately.  In such cases, implementations SHOULD ignore (or modify)
any tests which are not supported on that platform.

Testing validity
----------------

To test validity of a case in the ``valid`` array, we consider up to five
possible representations:

* Canonical BSON (denoted herein as "cB") -- fully valid, spec-compliant BSON

* Degenerate BSON (denoted herein as "dB") -- invalid but still parseable BSON
  (bad array keys, regex options out of order)

* Canonical Extended JSON (denoted herein as "cEJ") -- A string format based on
  the JSON standard that emphasizes type preservation at the expense of
  readability and interoperability.

* Degenerate Extended JSON (denoted herin as "dEJ") -- An invalid form of
  Canonical Extended JSON that is still parseable.  (For example, "1e100"
  instead of "1E+100".)

* Relaxed Extended JSON (denoted herein as "rEJ") -- A string format based on
  the JSON standard that emphasizes readability and interoperability at the
  expense of type preservation.

Not all input types will exist for a given test case.

There are two forms of BSON/Extended JSON codecs: ones that have a language-native
"intermediate" representation and ones that do not.

For a codec *without* an intermediate representation (i.e. one that translates
directly from BSON to JSON or back), the following assertions MUST hold
(function names are for clarity of illustration only):

* for cB input:

  * bson_to_canonical_extended_json(cB) = cEJ

  * bson_to_relaxed_extended_json(cB) = rEJ (if rEJ exists)

* for cEJ input:

  * json_to_bson(cEJ) = cB (unless lossy)

* for dB input (if it exists):

  * bson_to_canonical_extended_json(dB) = cEJ

  * bson_to_relaxed_extended_json(dB) = rEJ (if rEJ exists)

* for dEJ input (if it exists):

  * json_to_bson(dEJ) = cB (unless lossy)

* for rEJ input (if it exists):

  *  bson_to_relaxed_extended_json( json_to_bson(rEJ) ) = rEJ

For a codec that has a language-native representation, we want to test both
conversion and round-tripping.  For these codecs, the following assertions MUST
hold (function names are for clarity of illustration only):

* for cB input:

  * native_to_bson( bson_to_native(cB) ) = cB

  * native_to_canonical_extended_json( bson_to_native(cB) ) = cEJ

  * native_to_relaxed_extended_json( bson_to_native(cB) ) = rEJ (if rEJ exists)

* for cEJ input:

  * native_to_canonical_extended_json( json_to_native(cEJ) ) = cEJ

  * native_to_bson( json_to_native(cEJ) ) = cB (unless lossy)

* for dB input (if it exists):

  * native_to_bson( bson_to_native(dB) ) = cB

* for dEJ input (if it exists):

  * native_to_canonical_extended_json( json_to_native(dEJ) ) = cEJ

  * native_to_bson( json_to_native(dEJ) ) = cB (unless lossy)

* for rEJ input (if it exists):

  * native_to_relaxed_extended_json( json_to_native(rEJ) ) = rEJ

Implementations MAY test assertions in an implementation-specific
manner.

Testing decode errors
---------------------

The ``decodeErrors`` cases represent BSON documents that are sufficiently
incorrect that they can't be parsed even with liberal interpretation of
the BSON schema (e.g. reading arrays with invalid keys is possible, even
though technically invalid, so they are *not* ``decodeErrors``).

Drivers SHOULD test that each case results in a decoding error.
Implementations MAY test assertions in an implementation-specific
manner.

Testing parsing errors
----------------------

The interpretation of ``parseErrors`` is type-specific. The structure of test
cases within ``parseErrors`` is described in `Parse error case keys`_.

Drivers SHOULD test that each case results in a parsing error (e.g. parsing
Extended JSON, constructing a language type). Implementations MAY test
assertions in an implementation-specific manner.


Top-level Document (type 0x00)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For type "0x00" (i.e. top-level documents), the ``string`` field contains input
for an Extended JSON parser. Drivers MUST parse the Extended JSON input using an
Extended JSON parser and verify that doing so yields an error. Drivers that parse
Extended JSON into language types instead of directly to BSON MAY need to
additionally convert the resulting language type(s) to BSON to expect an error.

Drivers SHOULD also parse the Extended JSON input using a regular JSON parser (not
an Extended JSON one) and verify the input is parsed successfully. This serves
to verify that the ``parseErrors`` test cases are testing Extended JSON-specific
error conditions and that they do not have, for example, unintended syntax
errors.

Note: due to the generic nature of these tests, they may also be used to test
Extended JSON parsing errors for various BSON types appearing within a document.


Binary (type 0x05)
~~~~~~~~~~~~~~~~~~

For type "0x05" (i.e. binary), the rules for handling ``parseErrors`` are the
same as those for `Top-level Document (type 0x00)`_.


Decimal128 (type 0x13)
~~~~~~~~~~~~~~~~~~~~~~

For type "0x13" (i.e. Decimal128), the ``string`` field contains input for a
Decimal128 parser that converts string input to a binary Decimal128 value (e.g.
Decimal128 constructor). Drivers MUST assert that these strings cannot be
successfully converted to a binary Decimal128 value and that parsing the string
produces an error.


Deprecated types
----------------

The corpus files for deprecated types are provided for informational purposes.
Implementations MAY ignore or modify them to match legacy treatment of
deprecated types.  The ``converted_bson`` and ``converted_extjson`` fields MAY
be used to test conversion to a standard type or MAY be ignored.

Prose Tests
===========

The following tests have not yet been automated, but MUST still be tested.

1. Prohibit null bytes in null-terminated strings when encoding BSON
--------------------------------------------------------------------

The BSON spec uses null-terminated strings to represent document field names and
regex components (i.e. pattern and flags/options). Drivers MUST assert that null
bytes are prohibited in the following contexts when encoding BSON (i.e. creating
raw BSON bytes or constructing BSON-specific type classes):

* Field name within a root document
* Field name within a sub-document
* Pattern for a regular expression
* Flags/options for a regular expression

Depending on how drivers implement BSON encoding, they MAY expect an error when
constructing a type class (e.g. BSON Document or Regex class) or when encoding a
language representation to BSON (e.g. converting a dictionary, which might allow
null bytes in its keys, to raw BSON bytes).

Implementation Notes
====================

A tool for visualizing BSON
---------------------------

The test directory includes a Perl script ``bsonview``, which will
decompose and highlight elements of a BSON document.  It may be used like
this::

    echo "0900000010610005000000" | perl bsonview -x

Notes for certain types
-----------------------

Array
~~~~~

Arrays can have degenerate BSON if the array indexes are not set as
"0", "1", etc.

Boolean
~~~~~~~

The only valid values are 0 and 1.  Other non-zero numbers MUST be
interpreted as errors rather than "true" values.

Binary
~~~~~~

The Base64 encoded text in the extended JSON representation MUST be padded.

Code
~~~~

There are multiple ways to encode Unicode characters as a JSON document.
Individual implementers may need to normalize provided and generated
extended JSON before comparison.

Decimal
~~~~~~~

NaN with payload can't be represented in extended JSON, so such conversions are
lossy.

Double
~~~~~~

There is not yet a way to represent Inf, -Inf or NaN in extended JSON.  Even if
a $numberDouble is added, it is unlikely to support special values with
payloads, so such doubles would be lossy when converted to extended JSON.

String representation of doubles is fairly unportable so it's hard to provide
a single string that all platforms/languages will generate.  Testers may
need to normalize/modify the test cases.

String
~~~~~~

There are multiple ways to encode Unicode characters as a JSON document.
Individual implementers may need to normalize provided and generated
extended JSON before comparison.

DBPointer
~~~~~~~~~

This type is deprecated.  The provided converted form (``converted_bson``)
represents them as DBRef documents, but such conversion is outside the scope of
this spec.

Symbol
~~~~~~

This type is deprecated.  The provided converted form converts these to
strings, but such conversion is outside the scope of this spec.

Undefined
~~~~~~~~~

This type is deprecated.  The provided converted form converts these to Null,
but such conversion is outside the scope of this spec.

Reference Implementation
========================

The Java, C# and Perl drivers.

Design Rationale
================

Use of extjson
--------------

Testing conversion requires an "input" and an "output".  With a BSON string
as both input and output, we can only test that it roundtrips correctly --
we can't test that the decoded value visible to the language is correct.

For example, a pathological encoder/decoder could invert Boolean true and
false during decoding and encoding.  The BSON would roundtrip but the
program would see the wrong values.

Therefore, we need a separate, semantic description of the contents of a BSON
string in a machine readable format.  Fortunately, we already have extjson as a
means of doing so.  The extended JSON strings contained within the tests adhere
to the Extended JSON Specification.

Repetition across cases
-----------------------

Some validity cases may result in duplicate assertions across cases,
particularly if the ``degenerate_bson`` field is different in different cases,
but the ``canonical_bson`` field is the same.  This is by design so that each
case stands alone and can be confirmed to be internally consistent via the
assertions.  This makes for easier and safer test case development.

Changelog
=========

:2023-06-14: Add decimal128 Extended JSON parse tests for clamped zeros with
             very large exponents.
:2022-10-05: Remove spec front matter and reformat changelog.
:2021-09-09: Clarify error expectation rules for ``parseErrors``.
:2021-09-02: Add spec and prose tests for prohibiting null bytes in
             null-terminated strings within document field names and regular
             expressions. Clarify type-specific rules for ``parseErrors``.
:2017-05-26: Revised to be consistent with Extended JSON spec 2.0: valid case
             fields have changed, as have the test assertions.
:2017-01-23: Added ``multi-type.json`` to test encoding and decoding all BSON
             types within the same document. Amended all extended JSON strings
             to adhere to the Extended JSON Specification. Modified the "Use of
             extjson" section of this specification to note that canonical
             extended JSON is now used.
:2016-11-14: Removed "invalid flags" BSON Regexp case.
:2016-10-25: Added a "non-alphabetized flags" case to the BSON Regexp corpus
             file; decoders must be able to read non-alphabetized flags, but
             encoders must emit alphabetized flags. Added an "invalid flags"
             case to the BSON Regexp corpus file.

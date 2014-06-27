#!/usr/bin/env python
import sys
import fileinput

inside_flag = False
for line in fileinput.input():
    if "FRAMEWORK_SEARCH_PATHS = " in line:
        if inside_flag:
            sys.stderr.write("ERROR! Nested FRAMEWORK_SEARCH_PATHS ?")
            exit(1)
        else:
            if line.endswith("(\n"):
                inside_flag = True
                print line,
                continue
            else:
                print line.replace('"${SRCROOT}/../../../build/${CONFIGURATION}"', '${SRCROOT}/..'),
                continue
    else:
        if inside_flag:
            if line.endswith(");\n"):
                inside_flag = False
                print line,
                continue
            else:
                print line.replace('"${SRCROOT}/../../../build/${CONFIGURATION}"', '${SRCROOT}/..'),
                continue
        else:
            print line,
            continue
//
//  SwiftDemangling.swift
//  Realm
//
//  Created by JP Simard on 9/30/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

func isSwiftClassName(className: String) -> Bool {
    return contains(className, ".")
}

func demangleClassName(className: String) -> String? {
    if let start = className.rangeOfString(".")?.startIndex.successor() {
        return className.substringWithRange(Range<String.Index>(start: start, end: className.endIndex))
    }
    return nil
}

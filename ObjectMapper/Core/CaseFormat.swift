//
// Created by Trevor Boyer on 4/17/15.
// Copyright (c) 2015 Trevor Boyer. All rights reserved.
//

import Foundation

class CaseFormat {

    // MARK: - Detect String Case
    func isLowerCaseString(string: NSString) -> Bool {
        return String(string.characterAtIndex(0)).lowercaseString == String(string.characterAtIndex(0))
    }

    func isUpperCaseString(string: NSString) -> Bool {
        return String(string.characterAtIndex(0)).uppercaseString == String(string.characterAtIndex(0))
    }

    //MARK: - Making Components from String
    func componentsFromCamelCaseString(camelCaseString: String) -> Array<String> {
        var components: NSMutableArray = NSMutableArray()
        var scanner: NSScanner = NSScanner(string: camelCaseString)
        var string: NSMutableString = NSMutableString()

        while !scanner.atEnd {
            var scannedString: NSString? = nil
            scanner.scanUpToCharactersFromSet(NSCharacterSet.uppercaseLetterCharacterSet(), intoString: &scannedString)

            if scannedString?.length > 0 {
                string.appendString(scannedString! as String)
                components.addObject(string.copy())
                string.deleteCharactersInRange(NSMakeRange(0, string.length))
            }

            // Scan uppercase strings
            scannedString = nil;
            scanner.scanCharactersFromSet(NSCharacterSet.uppercaseLetterCharacterSet(), intoString: &scannedString)

            // Check the multiple uppercase string
            if scannedString?.length > 0 {
                if scannedString?.length > 1 {
                    components.addObject(scannedString!.substringToIndex(scannedString!.length - 1))
                    scannedString = scannedString!.substringFromIndex(scannedString!.length - 1)
                }
                string.appendString(scannedString! as String)
            }
        }

        return components.copy() as! Array
    }

    func componentsFromSnakeCaseString(snakeCaseString: NSString) -> Array<NSString> {
        return snakeCaseString.componentsSeparatedByString("_") as! Array
    }

    // MARK: - Making String from Components
    func camelCaseStringFromComponents(components: Array<NSString>) -> NSString {
        var string: NSMutableString = NSMutableString()

        for component in components {
            if (component.length > 0) {
                string.appendString(component.substringToIndex(1).uppercaseString)
                string.appendString(component.substringFromIndex(1).lowercaseString)
            }
        }

        return string.copy() as! NSString
    }

    func snakeCaseStringFromComponents(components: NSArray) -> NSString {
        return components.componentsJoinedByString("_").lowercaseString
    }

    // MARK: - Convering String
    func camelCaseStringFromSnakeCaseString(snakeCaseString:String) -> String {
        return camelCaseStringFromComponents(componentsFromSnakeCaseString(snakeCaseString)) as String
    }

    func snakeCaseStringFromCamelCaseString(camelCaseString:String) -> String {
        return snakeCaseStringFromComponents(componentsFromCamelCaseString(camelCaseString)) as String
    }
}
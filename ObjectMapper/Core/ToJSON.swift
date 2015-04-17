//
//  ToJSON.swift
//  ObjectMapper
//
//  Created by Tristan Himmelman on 2014-10-13.
//  Copyright (c) 2014 hearst. All rights reserved.
//

import Foundation

class ToJSON {
	
    func basicType<N>(field: N, key: String, inout dictionary: [String : AnyObject]) {
		var temp = dictionary
		var currentKey = key

        switch field {
        // basic Types
        case let x as Bool:
            dictionary[currentKey] = x
        case let x as Int:
            dictionary[currentKey] = x
        case let x as Double:
            dictionary[currentKey] = x
        case let x as Float:
            dictionary[currentKey] = x
        case let x as String:
            dictionary[currentKey] = x

        // Arrays with basic types
        case let x as Array<Bool>:
            dictionary[currentKey] = x
        case let x as Array<Int>:
            dictionary[currentKey] = x
        case let x as Array<Double>:
            dictionary[currentKey] = x
        case let x as Array<Float>:
            dictionary[currentKey] = x
        case let x as Array<String>:
            dictionary[currentKey] = x
			
        // Dictionaries with basic types
        case let x as Dictionary<String, Bool>:
            dictionary[currentKey] = x
        case let x as Dictionary<String, Int>:
            dictionary[currentKey] = x
        case let x as Dictionary<String, Double>:
            dictionary[currentKey] = x
        case let x as Dictionary<String, Float>:
            dictionary[currentKey] = x
        case let x as Dictionary<String, String>:
            dictionary[currentKey] = x
        default:
            //println("Default")
            return
        }
    }
    
    func optionalBasicType<N>(field: N?, key: String, inout dictionary: [String : AnyObject]) {
        if let field = field {
            basicType(field, key: key, dictionary: &dictionary)
        }
    }
    
    func basicArray(field: Array<AnyObject>, key: String, inout dictionary: [String : AnyObject]){
        dictionary[key] = field
    }
    
    func optionalBasicArray(field: Array<AnyObject>?, key: String, inout dictionary: [String : AnyObject]){
        if let value = field {
            basicArray(value, key: key, dictionary: &dictionary)
        }
    }
    
    func basicDictionary(field: Dictionary<String, AnyObject>, key: String, inout dictionary: [String : AnyObject]){
        dictionary[key] = field
    }
    
    func optionalBasicDictionary(field: Dictionary<String, AnyObject>?, key: String, inout dictionary: [String : AnyObject]){
        if let value = field {
            basicDictionary(value, key: key, dictionary: &dictionary)
        }
    }
    
    func object<N: _Mappable>(field: N, key: String, inout dictionary: [String : AnyObject]) {
        dictionary[key] = Mapper().toJsonTree(field)
    }
    
    func optionalObject<N: _Mappable>(field: N?, key: String, inout dictionary: [String : AnyObject]) {
        if let field = field {
            object(field, key: key, dictionary: &dictionary)
        }
    }
    
    func objectArray<N: _Mappable>(field: Array<N>, key: String, inout dictionary: [String : AnyObject]) {
		let objects = Mapper().toJsonArray(field)

		if !objects.isEmpty {
            dictionary[key] = objects
        }
    }
    
    func optionalObjectArray<N: _Mappable>(field: Array<N>?, key: String, inout dictionary: [String : AnyObject]) {
        if let field = field {
            objectArray(field, key: key, dictionary: &dictionary)
        }
    }
    
    func objectDictionary<N: _Mappable>(field: Dictionary<String, N>, key: String, inout dictionary: [String : AnyObject]) {
		let objects = Mapper().toJsonDictionary(field)

		if !objects.isEmpty {
			dictionary[key] = objects
		}
    }
    
    func optionalObjectDictionary<N: _Mappable>(field: Dictionary<String, N>?, key: String, inout dictionary: [String : AnyObject]) {
        if let field = field {
            objectDictionary(field, key: key, dictionary: &dictionary)
        }
    }
}

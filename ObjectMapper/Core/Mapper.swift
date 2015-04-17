//
//  Mapper.swift
//  ObjectMapper
//
//  Created by Tristan Himmelman on 2014-10-09.
//  Copyright (c) 2014 hearst. All rights reserved.
//

import Foundation

public protocol _Mappable {
    mutating func mapping(map: Map)
    init()
}

public class Mappable : _Mappable {

    public enum FieldNamingPolicy {
        case CamelCase
        case LowerUnderscore
    }

    public var namingPolicy: FieldNamingPolicy
    var map: Map?
    var dictionary: [String : AnyObject] = [String : AnyObject]()

    public required init() {
        self.namingPolicy = .LowerUnderscore
    }

    public init(namingPolicy: FieldNamingPolicy) {
        self.namingPolicy = namingPolicy
    }

    /**
     * Mapping for objects using reflection. Creates a dictionary that can be used
     * in RestKit for [de]serialization.
     *
     * :param: object The object to be mapped.
     * :param: namingPolicy The mapping naming policy to be used for serialization. (NOTE: All Strings are deserialized to camelCase).
     *
     * Adapted from Gist: https://gist.github.com/mchambers/67640d9c3e2bcffbb1e2
     */
	public func mapping(var map: Map) {
        var dictionary: [String : AnyObject] = [String : AnyObject]()
        var serializeName: String?

        for index in 0 ..< reflect(self).count {
            // INFO: The key represents the Json/XML version of the identifier, the value is the POSO version
            let value = reflect(self)[index].0
            // TODO: Include other naming policies
            var key = namingPolicy == .CamelCase ? value : CaseFormat().snakeCaseStringFromCamelCaseString(value)

            if key=="super" && index==0 {
                // if the first key is super, we should probably skip it
                // because it's most likely the reflector telling us the
                // superclass of this model
                // we'll need to handle this separately
                // right now the else is only giving us the K/Vs from
                // the current class. we need to also find a way to get
                // them from the base class. <- INFO: May need this for Post subclasses - we would want to iterate through var classes
            } else if value.rangeOfString("__") != nil {
                serializeName = value.stringByReplacingOccurrencesOfString("__", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
            } else {
                if serializeName != nil {
                    key = serializeName!
                }

                dictionary[key] = value

                // FIXME: This is close - we have the object initialized with the correct data, but it doesn't get set to the current instance (self)
                var object = reflect(self)[index].1.value
                object <= map[key]

                println(object)

                // Reset the serialize name
                serializeName = nil
            }
        }

        println(dictionary)

        self.dictionary = dictionary
        self.map = map
    }

    public func mapping() -> Map? {
        return self.map
    }
}

public enum MappingType {
	case fromJSON
	case toJSON
}

/**
 * A class used for holding mapping data
 */
public final class Map {
	public let mappingType: MappingType

	var jsonDictionary: [String : AnyObject] = [:]
	var currentValue: AnyObject?
	var currentKey: String?

	private init(mappingType: MappingType, jsonDictionary: [String : AnyObject]) {
		self.mappingType = mappingType
		self.jsonDictionary = jsonDictionary
	}
	
	/**
	* Sets the current mapper value and key.
	* 
	* The Key paramater can be a period separated string (ex. "distance.value") to access sub objects.
	*/
	public subscript(key: String) -> Map {
		// save key and value associated to it
		currentKey = key
		// break down the components of the key
		currentValue = valueFor(key.componentsSeparatedByString("."), jsonDictionary)
		
		return self
	}
}

/**
* Fetch value from JSON dictionary, loop through them until we reach the desired object.
*/
private func valueFor(keyPathComponents: [String], dictionary: [String : AnyObject]) -> AnyObject? {
	// Implement it as a tail recursive function.

	if keyPathComponents.isEmpty {
		return nil
	}

	if let object: AnyObject = dictionary[keyPathComponents.first!] {
		switch object {
		case is NSNull:
			return nil

		case let dict as [String : AnyObject] where keyPathComponents.count > 1:
			let tail = Array(keyPathComponents[1..<keyPathComponents.count])
			return valueFor(tail, dict)

		default:
			return object
		}
	}

	return nil
}

/**
* The Mapper class provides methods for converting Model objects to JSON and methods for converting JSON to Model objects
*/
public final class Mapper<N: _Mappable> {

	public init() { }
	
	// MARK: Public Mapping functions
	
	/**
	 * Map a JSON string onto an existing object
	 */
	public func map(string: String, var toObject object: N) -> N! {
		if let json = parseJsonDictionary(string) {
			return map(json, toObject: object)
		}
		return nil
	}

	/**
	 * Map a JSON string to an object that conforms to Mappable
	 */
	public func map(string jsonStr: String) -> N! {
		if let json = parseJsonDictionary(jsonStr) {
			return map(json: json)
		}
		return nil
	}

	/// Maps a JSON object to a Mappable object if it is a JSON dictionary,
	/// or returns nil.
	public func map(json jsonObject: AnyObject?) -> N? {
		if let json = jsonObject as? [String : AnyObject] {
			return map(json: json)
		}

		return nil
	}

	/// Maps a JSON object to an existing Mappable object if it is a JSON dictionary,
	/// or returns the passed object as is.
	public func map(json jsonObject: AnyObject?, var toObject object: N) -> N {
		if let json = jsonObject as? [String : AnyObject] {
			return map(json, toObject: object)
		}

		return object
	}

	/**
	 * Maps a JSON dictionary to an object that conforms to Mappable
	 */
	public func map(json jsonDictionary: [String : AnyObject]) -> N! {
		let object = N()
		return map(jsonDictionary, toObject: object)
	}

	/**
	 * Maps a JSON dictionary to an existing object that conforms to Mappable.
	 * Usefull for those pesky objects that have crappy designated initializers like NSManagedObject
	 */
	public func map(json: [String : AnyObject], var toObject object: N) -> N! {
		let map = Map(mappingType: .fromJSON, jsonDictionary: json)
		object.mapping(map)
		return object
	}

	/**
	 * Maps a JSON array to an object that conforms to Mappable
	 */
	public func mapArray(string: String) -> [N] {
		let json: AnyObject? = parseJsonString(string)

		if let objectArray = mapArray(json) {
			return objectArray
		}

		// failed to parse JSON into array form
		// try to parse it into a dictionary and then wrap it in an array
		if let object = map(json: json) {
			return [object]
		}

		return []
	}

	/// Maps a JSON object to an array of Mappable objects if it is an array of
	/// JSON dictionary, or returns nil.
	public func mapArray(json: AnyObject?) -> [N]? {
		if let array = json as? [[String : AnyObject]] {
			return mapArray(array)
		}

		return nil
	}
	
	/**
	* Maps an array of JSON dictionary to an array of object that conforms to Mappable
	*/
	public func mapArray(json: [[String : AnyObject]]) -> [N] {
		return json.map {
			// map every element in JSON array to type N
			self.map(json: $0)
		}		
	}

	/// Maps a JSON object to a dictionary of Mappable objects if it is a JSON
	/// dictionary of dictionaries, or returns nil.
	public func mapDictionary(json: AnyObject?) -> [String : N]? {
		if let dictionary = json as? [String : [String : AnyObject]] {
			return mapDictionary(dictionary)
		}

		return nil
	}

	/**
	* Maps a JSON dictionary of dictionaries to a dictionary of objects that conform to Mappable.
	*/
	public func mapDictionary(json: [String : [String : AnyObject]]) -> [String : N] {
		return json.map { k, v in
			// map every value in dictionary to type N
			return (k, self.map(json: v))
		}
	}

	// MARK: public toJSON functions
	
	/**
	 * Maps an object that conforms to Mappable to a JSON dictionary <String : AnyObject>
	 */
	public func toJsonTree(var object: N) -> [String : AnyObject] {
		let map = Map(mappingType: .toJSON, jsonDictionary: [:])
		object.mapping(map)
		return map.jsonDictionary
	}
	
	/** 
	* Maps an array of Objects to an array of JSON dictionaries [[String : AnyObject]]
	*/
	public func toJsonArray(array: [N]) -> [[String : AnyObject]] {
		return array.map {
			// convert every element in array to JSON dictionary equivalent
			self.toJsonTree($0)
		}
	}

	/**
	* Maps a dictionary of Objects that conform to Mappable to a JSON dictionary of dictionaries.
	*/
	public func toJsonDictionary(dictionary: [String : N]) -> [String : [String : AnyObject]] {
		return dictionary.map { k, v in
			// convert every value in dictionary to its JSON dictionary equivalent			
			return (k, self.toJsonTree(v))
		}
	}

	/** 
	* Maps an Object to a JSON string
	*/
	public func toJsonString(object: N, prettyPrint: Bool) -> String! {
		let dictionary = toJsonTree(object)

		var err: NSError?
		if NSJSONSerialization.isValidJSONObject(dictionary) {
			let options: NSJSONWritingOptions = prettyPrint ? .PrettyPrinted : .allZeros
			let data: NSData? = NSJSONSerialization.dataWithJSONObject(dictionary, options: options, error: &err)
			if let error = err {
				println(error)
			}

			if let json = data {
				return NSString(data: json, encoding: NSUTF8StringEncoding) as! String
			}
		}

		return nil
	}

	// MARK: Private utility functions for converting strings to JSON objects
	
	/** 
	* Convert a JSON String into a Dictionary<String, AnyObject> using NSJSONSerialization 
	*/
	private func parseJsonDictionary(json: String) -> [String : AnyObject]? {
		let parsedJson: AnyObject? = parseJsonString(json)
		return parseJsonDictionary(parsedJson)
	}

	/**
	* Convert a JSON Object into a Dictionary<String, AnyObject> using NSJSONSerialization
	*/
	private func parseJsonDictionary(json: AnyObject?) -> [String : AnyObject]? {
		if let dictionary = json as? [String : AnyObject] {
			return dictionary
		}

		return nil
	}

	/**
	* Convert a JSON String into an Object using NSJSONSerialization 
	*/
	private func parseJsonString(json: String) -> AnyObject? {
		let data = json.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
		if let data = data {
			var error: NSError?
			let parsedJson: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &error)
			return parsedJson
		}

		return nil
	}
}

extension Dictionary {
	private func map<K: Hashable, V>(f: Element -> (K, V)) -> [K : V] {
		var mapped = [K : V]()

		for element in self {
			let newElement = f(element)
			mapped[newElement.0] = newElement.1
		}

		return mapped
	}
}

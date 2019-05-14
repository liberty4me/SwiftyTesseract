//
//  TesseractVariableName.swift
//  SwiftyTesseract
//
//  Created by Steven Sherry on 3/24/18.
//  Copyright © 2018 Steven Sherry. All rights reserved.
//
import libtesseract

public enum TesseractOption {
  /// **Only available for** `EngineMode.tesseractOnly`.
  /// **Setting** `whiteList` **in any other EngineMode will do nothing**.
  ///
  /// Sets a `String` of characters that will **only** be recognized. This does **not** filter values.
  ///
  /// Example: setting a whiteList of "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  /// with an image containing digits may result in "1" being recognized as "I" and "2" being
  /// recognized as "Z". Set this value **only** if it is 100% certain the characters that are
  /// defined will **only** be present during recognition.
  ///
  /// **This may cause unpredictable recognition results if characters not defined in whiteList**
  /// **are present**. If **removal** and not **replacement** is desired, filtering the recognition
  /// string is a better option.
  case whiteList(String)
  /// **Only available for** `EngineMode.tesseractOnly`.
  /// **Setting** `blackList` **in any other EngineMode will do nothing**.
  ///
  /// Sets a `String` of characters that will **not** be recognized. This does **not** filter values.
  ///
  /// Example: setting a blackList of "0123456789" with an image containing digits may result in
  /// "1" being recognized as "I" and "2" being recognized as "Z". Set this value **only** if it
  /// is 100% certain that the characters defined will **not** be present during recognition.
  ///
  /// **This may cause unpredictable recognition results if characters defined in blackList are**
  /// **present**. If **removal** and not **replacement** is desired, filtering the recognition
  /// string is a better option
  case blackList(String)
  /// Preserve multiple interword spaces
  case preserveInterwordSpaces(Bool)
  /// Minimum character height
  case minimumCharacterHeight(Int)
  
  var value: String {
    switch self {
    case .whiteList(let string): return string
    case .blackList(let string): return string
    case .preserveInterwordSpaces(let bool): return bool ? "1" : "0"
    case .minimumCharacterHeight(let int): return "\(int)"
    }
  }
  
  func setVariable(to tesseract: TessBaseAPI) {
    switch self {
    case .minimumCharacterHeight:
      let oldHeight = InternalTesseractVariable.oldCharacterHeight(1)
      TessBaseAPISetVariable(tesseract, oldHeight.description, oldHeight.value)
      TessBaseAPISetVariable(tesseract, description, value)
    default:
      TessBaseAPISetVariable(tesseract, description, value)
    }
    
  }
}

extension TesseractOption: CustomStringConvertible {
  public var description: String {
    switch self {
    case .whiteList: return "tessedit_char_whitelist"
    case .blackList: return "tessedit_char_blacklist"
    case .preserveInterwordSpaces: return "preserve_interword_spaces"
    case .minimumCharacterHeight: return "textord_min_xheight"
    }
  }
}

extension TesseractOption: Hashable {
  public static func ==(lhs: TesseractOption, rhs: TesseractOption) -> Bool {
    return lhs.description == rhs.description
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(description)
  }
}

enum InternalTesseractVariable: CustomStringConvertible {
  case oldCharacterHeight(Int)
  
  var description: String {
    switch self {
    case .oldCharacterHeight: return "textord_old_xheight"
    }
  }
  
  var value: String {
    switch self {
    case .oldCharacterHeight(let int): return "\(int)"
    }
  }
}

enum TesseractEnvironment {
  case tessDataPrefix(String)
  
  var value: String {
    switch self {
    case .tessDataPrefix(let prefix): return prefix
    }
  }
}

extension TesseractEnvironment: CustomStringConvertible {
  var description: String {
    switch self {
    case .tessDataPrefix: return "TESSDATA_PREFIX"
    }
  }
}


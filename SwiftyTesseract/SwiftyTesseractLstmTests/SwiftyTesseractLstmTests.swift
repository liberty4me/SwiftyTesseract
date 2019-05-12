//
//  SwiftyTesseractLstmTests.swift
//  SwiftyTesseractLstmTests
//
//  Created by Steven Sherry on 2/2/19.
//  Copyright © 2019 Steven Sherry. All rights reserved.
//

import XCTest
import SwiftyTesseract

class SwiftyTesseractLstmTests: XCTestCase {

  var swiftyTesseract: SwiftyTesseract!
  var bundle: Bundle!
  
  override func setUp() {
    super.setUp()
    bundle = Bundle(for: self.classForCoder)
  }
  
  override func tearDown() {
    super.tearDown()
    swiftyTesseract = nil
  }
  
  func testVersion() {
    swiftyTesseract = SwiftyTesseract(language: .english, bundle: bundle)
    print(swiftyTesseract.version!)
    XCTAssertNotNil(swiftyTesseract.version)
  }
  
  func testReturnStringTestImage() {
    swiftyTesseract = SwiftyTesseract(language: .english, bundle: bundle)
    guard let image = UIImage(named: "image_sample.jpg", in: Bundle(for: self.classForCoder), compatibleWith: nil) else { fatalError() }
    let answer = "1234567890"
    
    let result = swiftyTesseract.performOCR(on: image)
    
    switch result {
    case .success(let string):
      XCTAssertEqual(answer, string.trimmingCharacters(in: .whitespacesAndNewlines))
    case .failure(let error):
      XCTFail("OCR failed with error: \(error.localizedDescription)")
    }
  }
  
  func testRealImage() {
    swiftyTesseract = SwiftyTesseract(language: .english, bundle: bundle)
    guard let image = UIImage(named: "IMG_1108.jpg", in: Bundle(for: self.classForCoder), compatibleWith: nil) else { fatalError() }
    let answer = "2F.SM.LC.SCA.12FT"
    
    let result = swiftyTesseract.performOCR(on: image)
    
    switch result {
    case .success(let string):
      XCTAssertEqual(answer, string.trimmingCharacters(in: .whitespacesAndNewlines))
    case .failure(let error):
      XCTFail("OCR failed with error: \(error.localizedDescription)")
    }
  }
  
  func testMultipleSpacesImage_withPreserveMultipleSpaces() {
    swiftyTesseract = SwiftyTesseract(language: .english, bundle: bundle)
    swiftyTesseract.preserveInterwordSpaces = true
    guard let image = UIImage(named: "HugeInterwordSpace.png", in: Bundle(for: self.classForCoder), compatibleWith: nil) else { fatalError() }
    
    let result = swiftyTesseract.performOCR(on: image)
    
    switch result {
    case .success(let string):
      XCTAssertTrue(string.contains("  "))
    case .failure(let error):
      XCTFail("OCR failed with error: \(error.localizedDescription)")
    }
  }
  
  func testNormalAndSmallFontsImage_withMinimumCharacterHeight() {
    swiftyTesseract = SwiftyTesseract(language: .english, bundle: bundle, engineMode: .lstmOnly)
    swiftyTesseract.minimumCharacterHeight = 15
    guard let image = UIImage(named: "NormalAndSmallFonts.jpg", in: Bundle(for: self.classForCoder), compatibleWith: nil) else { fatalError() }
    
    let result = swiftyTesseract.performOCR(on: image)
    
    switch result {
    case .success(let string):
      XCTAssertEqual(string.trimmingCharacters(in: .whitespacesAndNewlines), "21.02.2012")
    case .failure(let error):
      XCTFail("OCR failed with error: \(error.localizedDescription)")
    }
  }
  
  func testMultipleLanguages() {
    swiftyTesseract = SwiftyTesseract(languages: [.english, .french], bundle: bundle)
    swiftyTesseract.blackList = "|"
    let answer = """
    Lenore
    Lenore, Lenore, mon amour
    Every day I love you more
    Without you, my heart grows sore
    Je te aime encore trés beaucoup, Lenore
    Lenore, Lenore, don’t think me a bore
    But I can go on and on about your charms
    forever and ever more
    On a scale of one to three, I love you four
    Mon amour, je te aime encore tres beaucoup,
    Lenore
    """
    guard let image = UIImage(named: "Lenore3.png", in: bundle, compatibleWith: nil) else { fatalError() }
    let result = swiftyTesseract.performOCR(on: image)
    
    switch result {
    case .success(let string):
      let string = string.replacingOccurrences(of: "|", with: "I")
      XCTAssertEqual(answer.trimmingCharacters(in: .whitespacesAndNewlines), string.trimmingCharacters(in: .whitespacesAndNewlines))
    case .failure(let error):
      XCTFail("OCR failed with error: \(error.localizedDescription)")
    }
  }
}

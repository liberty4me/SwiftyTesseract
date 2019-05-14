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
  
  override func setUp() {
    super.setUp()
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
    let image = getImage(named: "image_sample.jpg")

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
    let image = getImage(named: "IMG_1108.jpg")

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
    swiftyTesseract.options.update(with: .preserveInterwordSpaces(true))
    
    let image = getImage(named: "HugeInterwordSpace.png")
    
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
    swiftyTesseract.options.update(with: .minimumCharacterHeight(15))

    let image = getImage(named: "NormalAndSmallFonts.jpg")
    
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
    let image = getImage(named: "Lenore3.png")

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

extension XCTestCase {
  var bundle: Bundle {
    return Bundle(for: self.classForCoder)
  }
  
  func getImage(named name: String) -> UIImage {
    guard let image = UIImage(
      named: name,
      in: bundle,
      compatibleWith: nil
      ) else {
        fatalError()
    }
    
    return image
  }
}

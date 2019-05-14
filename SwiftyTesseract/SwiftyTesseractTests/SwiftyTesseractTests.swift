//
//  SwiftyTesseractTests.swift
//  SwiftyTesseractTests
//
//  Created by Steven Sherry on 2/28/18.
//  Copyright © 2018 Steven Sherry. All rights reserved.
//

import XCTest
@testable import SwiftyTesseract
import PDFKit

/// Must be tested with legacy tessdata to verify results for `EngineMode.tesseractOnly`
class SwiftyTesseractTests: XCTestCase {
  
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

  func testRealImage_withWhiteList() {
    swiftyTesseract = SwiftyTesseract(language: .english, bundle: bundle, engineMode: .tesseractOnly, options: [.whiteList("ABCDEFGHIJKLMNOPQRSTUVWXYZ.")])
    let image = getImage(named: "IMG_1108.jpg")
    
    let result = swiftyTesseract.performOCR(on: image)
    
    switch result {
    case .success(let string):
      XCTAssertFalse(string.contains("2") && string.contains("1"))
    case .failure(let error):
      XCTFail("OCR failed with error: \(error.localizedDescription)")
    }
    
  }
  
  func testSettingWhiteList_ToEmptyString_ClearsUnderlyingWhiteList() {
    swiftyTesseract = SwiftyTesseract(
      language: .english,
      bundle: bundle,
      engineMode: .tesseractOnly,
      options: [.whiteList("ABCDEFGHIJKLMNOPQRSTUVWXYZ.")]
    )
    swiftyTesseract.options.update(with: .whiteList(""))
    
    let image = getImage(named: "IMG_1108.jpg")
    
    let result = swiftyTesseract.performOCR(on: image)
    
    switch result {
    case .success(let string):
      XCTAssertTrue(string.contains("2") && string.contains("1"))
    case .failure(let error):
      XCTFail("OCR failed with error: \(error.localizedDescription)")
    }
  }

  func testRealImage_withBlackList() {
    swiftyTesseract = SwiftyTesseract(
      language: .english,
      bundle: bundle,
      engineMode: .tesseractOnly,
      options: [.blackList("0123456789")]
    )

    let image = getImage(named: "IMG_1108.jpg")
    
    let result = swiftyTesseract.performOCR(on: image)
    
    switch result {
    case .success(let string):
      XCTAssertFalse(string.contains("2") && string.contains("1"))
    case .failure(let error):
      XCTFail("OCR failed with error: \(error.localizedDescription)")
    }

  }
  


  func testMultipleSpacesImage_withPreserveMultipleSpaces() {
    swiftyTesseract = SwiftyTesseract(language: .english, bundle: bundle, engineMode: .tesseractOnly)
    
    swiftyTesseract.options.update(with: .preserveInterwordSpaces(true))
    
    let image = getImage(named: "MultipleInterwordSpaces.jpg")

    let result = swiftyTesseract.performOCR(on: image)
    
    switch result {
    case .success(let string):
      XCTAssertTrue(string.contains("  "))
    case .failure(let error):
      XCTFail("OCR failed with error: \(error.localizedDescription)")
    }
    
  }

  func testNormalAndSmallFontsImage_withMinimumCharacterHeight() {
    swiftyTesseract = SwiftyTesseract(language: .english, bundle: bundle, engineMode: .tesseractOnly)
    swiftyTesseract.options.update(with: .minimumCharacterHeight(15))
    
    let image = getImage(named: "NormalAndSmallFonts.jpg")
    
    let result = swiftyTesseract.performOCR(on: image)
    
    switch result {
    case .success(let string):
      XCTAssertEqual(string.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: ""), "21.02.2012")
    case .failure(let error):
      XCTFail("OCR failed with error: \(error.localizedDescription)")
    }
  }
  
  func testMultipleLanguages() {
    swiftyTesseract = SwiftyTesseract(languages: [.english, .french], bundle: bundle, engineMode: .tesseractOnly)
    let answer = """
    Lenore
    Lenore, Lenore, mon amour
    Every day I love you more
    Without you, my heart grows sore
    Je te aime encore très beauCoup, Lenore
    Lenore, Lenore, don’t think me a bore
    But I can go on and on about your charms
    forever and ever more
    On a scale of one to three, I love you four
    Mon amour, je te aime encore trés beaucoup,
    Lenore
    """
    
    let image = getImage(named: "Lenore3.png")
    
    let result = swiftyTesseract.performOCR(on: image)
    
    switch result {
    case .success(let string):
      XCTAssertEqual(answer.trimmingCharacters(in: .whitespacesAndNewlines), string.trimmingCharacters(in: .whitespacesAndNewlines))
    case .failure(let error):
      XCTFail("OCR failed with error: \(error.localizedDescription)")
    }
    
  }

  func testWithNoImage() {
    swiftyTesseract = SwiftyTesseract(language: .english, bundle: bundle, engineMode: .tesseractOnly)
    let image = UIImage()
    let result = swiftyTesseract.performOCR(on: image)
    
    switch result {
    case .success:
      XCTFail("Should not have been able to extract any text from a non-existent image")
    case .failure(let error as SwiftyTesseractError):
      XCTAssertEqual(SwiftyTesseractError.unableToExtractTextFromImage, error)
    default:
      XCTFail("Should have failed with SwiftyTesseractError.unableToExtractTextFromImage")
    }
  }

  func testWithCustomLanguage() {
    guard let image = UIImage(named: "MVRCode3.png", in: bundle, compatibleWith: nil) else { fatalError() }
    swiftyTesseract = SwiftyTesseract(language: .custom("OCRB"), bundle: bundle, engineMode: .tesseractOnly)
    
//    let image = getImage(named: "MVRCode3.png")
    
    let answer = """
    P<GRCELLINAS<<GEORGIOS<<<<<<<<<<<<<<<<<<<<<<
    AE00000057GRC6504049M1208283<<<<<<<<<<<<<<00
    """
    let result = swiftyTesseract.performOCR(on: image)
    
    switch result {
    case .success(let string):
      XCTAssertEqual(answer.trimmingCharacters(in: .whitespacesAndNewlines), string.trimmingCharacters(in: .whitespacesAndNewlines))
    case .failure(let error):
      XCTFail("OCR failed with error: \(error.localizedDescription)")
    }
    
  }

  func testLoadingStandardAndCustomLanguages() {
    // This test would otherwise crash if it was unable to load both languages
    swiftyTesseract = SwiftyTesseract(languages: [.custom("OCRB"), .english], bundle: bundle)
    XCTPass()
  }

  func testMultipleThreads() {
    let bundle = Bundle(for: self.classForCoder)
    swiftyTesseract = SwiftyTesseract(language: .english, bundle: bundle)
    let image = getImage(named: "image_sample.jpg")

    /*
     `measure` is used because it runs a given closure 10 times. If performOCR(on:completionHandler:) was not thread safe,
     there would be failures & crashes in various tests.
    */
    measure {
      DispatchQueue.global(qos: .userInitiated).async {
        let result = self.swiftyTesseract.performOCR(on: image)
        switch result {
        case .success: XCTPass()
        case .failure: XCTFail()
        }
      }
    }
    
    swiftyTesseract = nil
  
  }

  func testPDFSinglePage() {
    swiftyTesseract = SwiftyTesseract(language: .english, bundle: bundle)
    let image = getImage(named: "image_sample.jpg")
    
    let result = swiftyTesseract.createPDF(from: [image])
    
    switch result {
    case .success(let data):
      if #available(iOS 11.0, *) {
        let document = PDFDocument(data: data)
        XCTAssertNotNil(document)
        XCTAssertEqual(document?.string, "1234567890\n ")
      } else {
        // Fallback on earlier versions
        XCTAssertEqual(data.count, 53248)
      }
    case .failure(let error):
      XCTFail("PDF Generation failed with error: \(error.localizedDescription)")
    }
  }

  func testPDFMultiplePages() {
    swiftyTesseract = SwiftyTesseract(language: .english, bundle: bundle)
    let image = getImage(named: "image_sample.jpg")
   
    let result = swiftyTesseract.createPDF(from: [image, image, image])
    
    switch result {
    case .success(let data):
      if #available(iOS 11.0, *) {
        let document = PDFDocument(data: data)
        XCTAssertNotNil(document)
        XCTAssertTrue(document?.string?.contains("1234567890") ?? false)
      } else {
        // Fallback on earlier versions
        XCTAssertEqual(data.count, 53248)
      }
    case .failure(let error):
      XCTFail("PDF Generation failed with error: \(error.localizedDescription)")
    }
  }
}

func XCTPass() {
  XCTAssert(true)
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

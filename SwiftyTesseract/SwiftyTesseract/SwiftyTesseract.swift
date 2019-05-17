//
//  SwiftyTesseract.swift
//  SwiftyTesseract
//
//  Created by Steven Sherry on 2/28/18.
//  Copyright © 2018 Steven Sherry. All rights reserved.
//

import UIKit
import libtesseract
import libleptonica

typealias TessBaseAPI = OpaquePointer
typealias TessString = UnsafePointer<Int8>
typealias Pix = UnsafeMutablePointer<PIX>?

/// A class to perform optical character recognition with the open-source Tesseract library
public class SwiftyTesseract {
  
  // MARK: - Properties
  private let tesseract: TessBaseAPI = TessBaseAPICreate()
    
  private let bundle: Bundle
  
  /// Required to make `performOCR(on:completionHandler:)` thread safe. Runs faster on average than a `DispatchQueue` with `.barrier` flag.
  private let semaphore = DispatchSemaphore(value: 1)

  public var options: Set<TesseractOption> {
    didSet {
      options.subtracting(options: oldValue).forEach { $0.setVariable(to: tesseract) }
    }
  }
  
  /// The current version of the underlying Tesseract library
  lazy public private(set) var version: String? = {
    guard let tesseractVersion = TessVersion() else { return nil }
    return String(tesseractString: tesseractVersion)
  }()
  
  private init(languageString: String,
               bundle: Bundle,
               engineMode: EngineMode,
               options: Set<TesseractOption>) {
    
    self.bundle = bundle
    self.options = options
    
    setEnvironmentVariable(.tessDataPrefix(bundle.pathToTrainedData))
    
    // This variable's value somehow persists between deinit and init, default value should be set
    guard TessBaseAPIInit2(tesseract,
                           bundle.pathToTrainedData,
                           languageString,
                           TessOcrEngineMode(rawValue: engineMode.rawValue)) == 0
    else { fatalError(SwiftyTesseractError.initializationErrorMessage) }
    
    // This variable's value somehow persists between deinit and init, default value should be set
    InternalTesseractVariable.setOldHeightToZero(to: tesseract)
    
    self.options.forEach { $0.setVariable(to: tesseract) }
    
  }
  
  // MARK: - Initialization
  /// Creates an instance of SwiftyTesseract using standard RecognitionLanguages. The tessdata
  /// folder MUST be in your Xcode project as a folder reference (blue folder icon, not yellow)
  /// and be named "tessdata"
  ///
  /// - Parameters:
  ///   - languages: Languages of the text to be recognized
  ///   - bundle: The bundle that contains the tessdata folder - default is .main
  ///   - engineMode: The tesseract engine mode - default is .lstmOnly
  public convenience init(languages: [RecognitionLanguage],
              bundle: Bundle = .main,
              engineMode: EngineMode = .lstmOnly,
              options: Set<TesseractOption> = []) {
    
    let stringLanguages = RecognitionLanguage.createLanguageString(from: languages)
    self.init(languageString: stringLanguages, bundle: bundle, engineMode: engineMode, options: options)
  }
  
  /// Convenience initializer for creating an instance of SwiftyTesseract with one language to avoid having to
  /// input an array with one value (e.g. [.english]) for the languages parameter
  ///
  /// - Parameters:
  ///   - language: The language of the text to be recognized
  ///   - bundle: The bundle that contains the tessdata folder - default is .main
  ///   - engineMode: The tesseract engine mode - default is .lstmOnly
  public convenience init(language: RecognitionLanguage,
                          bundle: Bundle = .main,
                          engineMode: EngineMode = .lstmOnly,
                          options: Set<TesseractOption> = []) {
    
    self.init(languages: [language], bundle: bundle, engineMode: engineMode, options: options)
  }
  
  deinit {
    // Releases the tesseract instance from memory
    TessBaseAPIEnd(tesseract)
    TessBaseAPIDelete(tesseract)
  }
  
  // MARK: - Methods
  /// Takes a UIImage and passes resulting recognized UTF-8 text into completion handler
  ///
  /// - Parameters:
  ///   - image: The image to perform recognition on
  ///   - completionHandler: The action to be performed on the recognized string
  ///
  public func performOCR(on image: UIImage) -> Result<String, Error> {
    let _ = semaphore.wait(timeout: .distantFuture)
    
    let pixResult = Result {
      try createPix(from: image)
    }
    
    pixResult.do { pix in
      TessBaseAPISetImage2(tesseract, pix)
      
      // This is contained in the `do` block because attempting to get the source resolution
      // if an image has not been set traps execution
      if TessBaseAPIGetSourceYResolution(tesseract) < 70 {
        TessBaseAPISetSourceResolution(tesseract, 300)
      }
    }
    
    defer {
      // Release the Pix instance from memory if it exists
      pixResult.destroyPix()
      semaphore.signal()
    }

    guard let tesseractString = TessBaseAPIGetUTF8Text(tesseract) else {
      return .failure(SwiftyTesseractError.unableToExtractTextFromImage)
    }
    
    defer {
      // Releases the Tesseract string from memory
      TessDeleteText(tesseractString)
    }
    
    let swiftString = String(tesseractString: tesseractString)
    return .success(swiftString)
  }
  
  /// Takes an array UIImages and returns the PDF as a `Data` object.
  /// If using PDFKit introduced in iOS 11, this will produce a valid
  /// PDF Document.
  ///
  /// - Parameter images: Array of UIImages to perform OCR on
  /// - Returns: PDF `Data` object
  /// - Throws: SwiftyTesseractError
  public func createPDF(from images: [UIImage]) -> Result<Data, Error> {
    let _ = semaphore.wait(timeout: .distantFuture)
    defer {
      semaphore.signal()
    }
    
    return Result {
      try createPDF(from: images)
    }
  }
}

// MARK: - Helper Functions
extension SwiftyTesseract {
  private func createPix(from image: UIImage) throws -> Pix {
    guard let data = image.pngData() else { throw SwiftyTesseractError.imageConversionError }
    let rawPointer = (data as NSData).bytes
    let uint8Pointer = rawPointer.assumingMemoryBound(to: UInt8.self)
    return pixReadMem(uint8Pointer, data.count)
  }

  private func setEnvironmentVariable(_ variableName: TesseractEnvironment) {
    setenv(variableName.description, variableName.value, 1)
  }
}

// MARK: - PDF Helper Functions
extension SwiftyTesseract {
  private func createPDF(from images: [UIImage]) throws -> Data {
    // create unique file path
    let filepath = try processPDF(images: images)
    
    // get data from pdf and remove file
    let data = try Data(contentsOf: filepath)
    try FileManager.default.removeItem(at: filepath)
    
    return data
  }
  
  private func processPDF(images: [UIImage]) throws -> URL {
    let filepath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    
    let renderer = try makeRenderer(at: filepath)
    
    defer {
      TessDeleteResultRenderer(renderer)
    }
    
    try render(images, with: renderer)
    
    return filepath.appendingPathExtension("pdf")
  }
  
  private func render(_ images: [UIImage], with renderer: OpaquePointer) throws {
    let pixImages = try images.map(createPix)
    
    defer {
      for var pix in pixImages { pixDestroy(&pix) }
    }
    
    try pixImages.enumerated().forEach { [weak self] pageNumber, pix in
      guard let self = self else { return }
      guard TessBaseAPIProcessPage(self.tesseract, pix, Int32(pageNumber), "page.\(pageNumber)", nil, 30000, renderer) == 1 else {
        throw SwiftyTesseractError.unableToProcessPage
      }
    }
    
    guard TessResultRendererEndDocument(renderer) == 1 else { throw SwiftyTesseractError.unableToEndDocument }
  }
  
  private func makeRenderer(at url: URL) throws -> OpaquePointer {
    guard let renderer = TessPDFRendererCreate(url.path, bundle.pathToTrainedData, 0) else {
      throw SwiftyTesseractError.unableToCreateRenderer
    }
    
    guard TessResultRendererBeginDocument(renderer, "Unkown Title") == 1 else {
      TessDeleteResultRenderer(renderer)
      throw SwiftyTesseractError.unableToBeginDocument
    }
    
    return renderer
  }
}

public extension Result {
  func `do`(_ fn: (Success) -> ()) {
    switch self {
    case .success(let value): fn(value)
    default: return
    }
  }
}

extension Result where Success == Pix {
  func destroyPix() {
    switch self {
    case .success(var pix): pixDestroy(&pix)
    default: return
    }
  }
}

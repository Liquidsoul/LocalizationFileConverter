//
//  AndroidLocalizationFolderStringProviderTests.swift
//
//  Created by Sébastien Duperron on 26/09/2016.
//  Copyright © 2016 Sébastien Duperron
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

import XCTest

@testable import LocalizationConverter

class AndroidLocalizationFolderStringProviderTests: XCTestCase {

    func test_That_Provider_ListFolders() throws {
        // GIVEN: a fake FileProvider
        let fileProvider = FileProviderStub(list: ["values", "values-fr"])
        // GIVEN: a localization provider
        let localizationProvider = try AndroidLocalizationFolderStringProvider(folderPath: "any", fileProvider: fileProvider)

        // WHEN: we query the languages
        let languages = localizationProvider.languages
        
        // THEN: we get the expected languages
        XCTAssertTrue(languages.contains(.base))
        XCTAssertTrue(languages.contains(.named("fr")))

        // THEN: we get the expected string providers
        guard let baseFileProvider = localizationProvider.contentProvider(for: .base) as? StringFileContentProvider else {
            XCTFail()
            return
        }
        XCTAssertEqual("any/values/strings.xml", baseFileProvider.filePath)
        guard let frFileProvider = localizationProvider.contentProvider(for: .named("fr")) as? StringFileContentProvider else {
            XCTFail()
            return
        }
        XCTAssertEqual("any/values-fr/strings.xml", frFileProvider.filePath)
    }

    fileprivate struct FileProviderStub: FileProvider {
        let list: [String]

        func contentsOfDirectory(atPath: String) throws -> [String] {
            return list
        }
    }
}

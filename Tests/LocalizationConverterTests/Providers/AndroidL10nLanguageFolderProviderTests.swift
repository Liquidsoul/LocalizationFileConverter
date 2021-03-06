//
//  AndroidL10nLanguageFolderProviderTests.swift
//
//  Created by Sébastien Duperron on 26/09/2016.
//  Copyright © 2016 Sébastien Duperron
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

import XCTest

@testable import LocalizationConverter

class AndroidL10nLanguageFolderProviderTests: XCTestCase {

    func test_That_Provider_ListFolders() throws {
        // GIVEN: a fake provider
        let directoryContentProvider = DirectoryContentProviderStub(list: ["values", "values-fr"])
        // GIVEN: a localization provider
        let l10nProvider = try AndroidL10nLanguageFolderProvider(folderPath: "any", provider: directoryContentProvider)

        // WHEN: we query the languages
        let languages = l10nProvider.languages

        // THEN: we get the expected languages
        XCTAssertTrue(languages.contains(.base))
        XCTAssertTrue(languages.contains(.named("fr")))

        // THEN: we get the expected string providers
        guard let baseLocalizationProvider = l10nProvider.contentProvider(for: .base) as? AndroidL10nFileProvider else {
            XCTFail("Could not find the base localization provider")
            return
        }
        XCTAssertEqual("any/values/strings.xml", baseLocalizationProvider.filePath)
        guard let frLocalizationProvider = l10nProvider.contentProvider(for: .named("fr")) as? AndroidL10nFileProvider else {
            XCTFail("Could not find the fr localization provider")
            return
        }
        XCTAssertEqual("any/values-fr/strings.xml", frLocalizationProvider.filePath)
    }

    fileprivate struct DirectoryContentProviderStub: DirectoryContentProvider {
        let list: [String]

        func contentsOfDirectory(atPath: String) throws -> [String] {
            return list
        }
    }
}

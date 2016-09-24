//
//  mainFunctions.swift
//
//  Created by Sébastien Duperron on 14/05/2016.
//  Copyright © 2016 Sébastien Duperron
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

import Foundation
import RegexReplacer
import FoundationExtensions

protocol LocalizationStore {
    func storeFormattedLocalizable(data: Data) throws
    func storeFormattedStringsDict(data: Data) throws
}

struct FileLocalizationStore: LocalizationStore {
    private let localizablePath: String
    private let stringsDictPath: String

    init(outputFolderPath: String) {
        localizablePath = outputFolderPath.appending(pathComponent: "Localizable.strings")
        stringsDictPath = outputFolderPath.appending(pathComponent: "Localizable.stringsdict")
    }

    func storeFormattedLocalizable(data: Data) throws {
        try write(data: data, toFilePath: localizablePath)
    }

    func storeFormattedStringsDict(data: Data) throws {
        try write(data: data, toFilePath: stringsDictPath)
    }

    private func write(data: Data, toFilePath filePath: String) throws {
        guard FileManager().createFile(atPath: filePath, contents: data, attributes: nil) else {
            throw Error.fileWriteError(path: filePath)
        }
    }

    enum Error: Swift.Error {
        case fileWriteError(path: String)
    }
}

public func convert(androidFileName fileName: String, outputPath: String, includePlurals: Bool) -> Bool {
    guard let localization = parseAndroidFile(withName: fileName) else {
        return false
    }

    let store: LocalizationStore = FileLocalizationStore(outputFolderPath: outputPath)

    do {
        let localizableString = try LocalizableFormatter(includePlurals: includePlurals).format(localization)
        try store.storeFormattedLocalizable(data: localizableString)
        let stringsDictContent = try StringsDictFormatter().format(localization)
        try store.storeFormattedStringsDict(data: stringsDictContent)
    } catch StringsDictFormatter.Error.noPlurals {
        print("No plural found, skipping stringsdict file.")
    } catch {
        print("Error: \(error)")
        return false
    }

    return true
}

func parseAndroidFile(withName name: String) -> LocalizationMap? {
    guard let fileContent = readFile(withName: name, encoding: String.Encoding.utf8) else {
        return nil
    }
    return try? AndroidStringsParser().parse(string: fileContent)
}

func readFile(withName fileName: String, encoding: String.Encoding = String.Encoding.utf16) -> String? {
    let fileManager = FileManager()
    let filePath: String
    if fileManager.fileExists(atPath: fileName) {
        filePath = fileName
    } else {
        filePath = NSString.path(withComponents: [fileManager.currentDirectoryPath, fileName])
    }
    guard let content = fileManager.contents(atPath: filePath) else {
        print("Failed to load file \(fileName) from path \(filePath)")
        return nil
    }
    guard let contentAsString = String(data: content, encoding: encoding) else {
        print("Failed to read contents of file at path \(filePath)")
        return nil
    }
    return contentAsString
}

func write(stringData string: String, toFilePath filePath: String) -> Bool {
    if !FileManager().createFile(atPath: filePath, contents: string.data(using: String.Encoding.utf8), attributes: nil) {
        print("Failed to write output at path: \(filePath)")
        return false
    }
    return true
}

public func convert(androidFolder resourceFolder: String, outputPath: String, includePlurals: Bool) -> Bool {
    let fileManager = FileManager()

    let outputFolder = outputPath

    do {
        let folders = try fileManager.contentsOfDirectory(atPath: resourceFolder)
        let valuesFolders = folders.filter { (folderName) -> Bool in
            return folderName.hasPrefix("values")
        }

        let results = try valuesFolders.map { (valuesFolderName) -> Bool in
            guard let outputFolderName = iOSFolderName(from: valuesFolderName) else {
                print("Could not convert values folder name '\(valuesFolderName)' to its iOS counterpart")
                return false
            }
            let outputFolderPath = outputFolder.appending(pathComponent: outputFolderName)
            try fileManager.createDirectory(atPath: outputFolderPath, withIntermediateDirectories: true, attributes: nil)
            let inputFilePath = resourceFolder
                .appending(pathComponent: valuesFolderName)
                .appending(pathComponent: "strings.xml")
            return convert(androidFileName: inputFilePath, outputPath: outputFolderPath, includePlurals: includePlurals)
        }
        return results.reduce(true, { (accumulator, result) -> Bool in
            return accumulator && result
        })
    } catch {
        print("Error: \(error)")
        return false
    }
}

func iOSFolderName(from valuesName: String) -> String? {
    if valuesName == "values" { return "Base.lproj" }

    let replacer = RegexReplacer(pattern: "values-(.*)", replaceTemplate: "$1.lproj")
    return replacer?.replacingMatches(in: valuesName)
}

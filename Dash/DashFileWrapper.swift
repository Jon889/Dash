//
//  DashFileWrapper.swift
//  Dash
//
//  Created by Jonathan Bailey on 13/03/2019.
//  Copyright © 2019 jonathan. All rights reserved.
//

import Cocoa

class DashFileWrapper: FileWrapper {
    private enum Keys {
        static let contents = "contents.json"
    }
    
    public init() {
        super.init(directoryWithFileWrappers: [:])
    }
    
    public init(_ fileWrapper: FileWrapper) {
        super.init(directoryWithFileWrappers: fileWrapper.fileWrappers ?? [:])
    }
    
    required init?(coder inCoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var contentsJSON: Data {
        get {
            return fileWrappers?[Keys.contents]?.regularFileContents ?? Data()
        }
        set {
            if let contentsFileWrapper = fileWrappers?[Keys.contents] {
                removeFileWrapper(contentsFileWrapper)
            }
            let contentsFileWrapper = FileWrapper(regularFileWithContents: newValue)
            contentsFileWrapper.preferredFilename = Keys.contents
            addFileWrapper(contentsFileWrapper)
        }
    }
    
    
    
    
}

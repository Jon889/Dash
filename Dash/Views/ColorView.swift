//
//  ColorView.swift
//  Dash
//
//  Created by Jonathan Bailey on 09/04/2019.
//  Copyright © 2019 jonathan. All rights reserved.
//

import Cocoa

class ColorView: View, Encodable {
	static var type: String = "Color"
	
	var color: NSColor
	
	required convenience init() {
		self.init(color: .red)
	}
	
	init(color: NSColor) {
		self.color = color
		super.init(frame: .zero)
	}
	enum Keys: String {
		case color
	}
	required init?(coder decoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
		color.setFill()
		dirtyRect.fill()
	}
	
	var dictionary: DictionaryBox<Keys> {
		return [ .color : color.hexString ]
	}
	
	required convenience init(from dictionary: DictionaryBox<Keys>) throws {
		let colorString: String = try dictionary(.color)
		guard let color = NSColor.fromHexString(hex: colorString, alpha: 1) else {
			throw InvalidValueError(key: "color", message: "Unable to create color from string \(colorString)")
		}
		self.init(color: color)
	}
}

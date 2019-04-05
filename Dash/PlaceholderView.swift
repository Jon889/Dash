//
//  PlaceholderView.swift
//  Dash
//
//  Created by Jonathan Bailey on 05/04/2019.
//  Copyright © 2019 jonathan. All rights reserved.
//
import Foundation
import Cocoa
class PlaceholderView: View {
	required convenience init() {
		try! self.init(from: DictionaryBox<Keys>.init(dictionary: [: ]))
	}
	
	let popupButton: NSPopUpButton
	required init(from dictionary: DictionaryBox<PlaceholderView.Keys>) throws {
		self.ownDictionary = dictionary
		let b = NSPopUpButton()
		self.popupButton = b
		super.init(frame: .zero)
		b.addItems(withTitles: viewTypes.compactMap { $0 is PlaceholderView.Type ? nil : $0.type })
		b.target = self
		b.action = #selector(didChange(_:))
		addSubview(b)
		b.centerXAnchor.constrain(equalTo: centerXAnchor)
		b.centerYAnchor.constrain(equalTo: centerYAnchor)
		
	}
	var subview: SubView? {
		didSet {
			if subview != nil {
				popupButton.removeFromSuperview()
			}
		}
	}
	@objc
	func didChange(_ sender: NSPopUpButton) {
		let vt = viewTypes[sender.indexOfSelectedItem].init()
		addContainedSubview(vt)
		subview = vt
	}
	required init?(coder decoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	var ownDictionary: DictionaryBox<Keys>
	var dictionary: DictionaryBox<Keys> {
		if let subview = subview {
			return DictionaryBox<Keys>(dictionary: subview.dictionary)
		}
		return ownDictionary
	}
	
	
	enum Keys: String {
		case nothing
	}
	
	var isEditing: Bool = false
	
	static var type: String = "PlaceholderView"
	
	
}

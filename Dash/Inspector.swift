//
//  Inspector.swift
//  Dash
//
//  Created by Jonathan Bailey on 09/04/2019.
//  Copyright © 2019 jonathan. All rights reserved.
//

import Foundation
import Cocoa

class AttributeView: NSView {
	let alignmentAnchor: NSLayoutXAxisAnchor
	let label: NSTextField
	init(label labelString: String, rightView: NSView) {
		label = NSTextField(frame: .zero)
		label.stringValue = labelString
		label.isEditable = false
		label.isBordered = false
		label.backgroundColor = nil
		alignmentAnchor = label.rightAnchor
		super.init(frame: .zero)
		addSubview(label)
		label.leftAnchor.constrain(equalTo: leftAnchor)
//		label.bottomAnchor.constrain(equalTo: bottomAnchor)
//		label.topAnchor.constrain(equalTo: topAnchor)
		addSubview(rightView)
		rightView.leftAnchor.constrain(equalTo: label.rightAnchor)
		rightView.topAnchor.constrain(equalTo: topAnchor)
		rightView.bottomAnchor.constrain(equalTo: bottomAnchor)
		rightView.rightAnchor.constrain(equalTo: rightAnchor)
		
		rightView.firstBaselineAnchor.constrain(equalTo: label.firstBaselineAnchor)
	}
	
	required init?(coder decoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class TextAttributeView: AttributeView {
	
	let textField: NSTextField
	init(label: String) {
		textField = NSTextField()
		super.init(label: label, rightView: textField)
		textField.target = self
		textField.action = #selector(textFieldChanged)
	}
	
	@objc
	private func textFieldChanged() {
		changeHandler?(textField.stringValue)
	}
	
	required init?(coder decoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var changeHandler: ((String) -> Void)?
	
	var stringValue: String {
		get {
			return textField.stringValue
		}
		set {
			textField.stringValue = newValue
		}
	}
}

class InspectorView: NSView {
	let stackView: NSStackView
	init() {
		stackView = NSStackView()
		stackView.orientation = .vertical
		super.init(frame: .zero)
		addContainedSubview(stackView)
	}
	
	required init?(coder decoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func addAttribute(view: AttributeView) {
		let firstView = stackView.arrangedSubviews.first
		stackView.addArrangedSubview(view)
		if let firstView = firstView as? AttributeView {
			view.alignmentAnchor.constrain(equalTo: firstView.alignmentAnchor)
		}
	}
}

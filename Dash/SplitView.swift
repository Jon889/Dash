//
//  SplitView.swift
//  Dash
//
//  Created by Jonathan Bailey on 21/03/2019.
//  Copyright © 2019 jonathan. All rights reserved.
//

import Cocoa

class SplitView: View {
	
	static var type: String = "SplitView"
	
    
    private var isVertical: Bool
    private var left: SubView
    private var right: SubView
	private let sv: NSSplitView
	private var splitPosition: CGFloat
	init(isVertical: Bool, left: SubView, right: SubView, splitPosition: CGFloat) {
		self.splitPosition = splitPosition
        sv = NSSplitView()
        sv.isVertical = isVertical
        sv.setValue(NSColor.black, forKey: "dividerColor")
        sv.addArrangedSubview(left)
        sv.addArrangedSubview(right)
//        sv.autosaveName = "testSV"
		
        self.isVertical = isVertical
        self.left = left
        self.right = right
        super.init(frame: .zero)
        addContainedSubview(sv)
    }
	
	enum Keys: String {
		case isVertical, left, right, splitPosition
	}
	required convenience init(from dictionary: DictionaryBox<Keys>) throws {
		let isVertical: Bool = try dictionary.get(.isVertical)
		let splitPosition: CGFloat =  (try? dictionary.get(.splitPosition)) ?? 0.5
		guard let left = viewFrom(dictionary: try dictionary.get(.left)),
			let right = viewFrom(dictionary: try dictionary.get(.left)) else {
				throw MissingKeyError()
		}
		self.init(isVertical: isVertical, left: left, right: right, splitPosition: splitPosition)
		
		
	}
	
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var dictionary: DictionaryBox<Keys> {
		return [ .isVertical: isVertical, .left: left.dictionary, .right: right.dictionary, .splitPosition: splitPosition]
    }
	
	override func layout() {
		super.layout()
		sv.setPosition(self.bounds.width * splitPosition, ofDividerAt: 0)
	}
	var isEditing: Bool = false {
		didSet {
			left.isEditing = isEditing
			right.isEditing = isEditing
		}
	}
}

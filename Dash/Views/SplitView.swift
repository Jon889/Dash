//
//  SplitView.swift
//  Dash
//
//  Created by Jonathan Bailey on 21/03/2019.
//  Copyright © 2019 jonathan. All rights reserved.
//

import Cocoa

class SplitView: View, NSSplitViewDelegate {
	required convenience init() {
		self.init(isVertical: false, left: PlaceholderView(), right: PlaceholderView(), splitPosition: 0.5)
	}
	
	
	static var type: String = "SplitView"
    private var isVertical: Bool
    private var left: SubView
    private var right: SubView
	private let sv: NSSplitView
	@objc dynamic
	private var splitPosition: CGFloat {
		didSet {
			undoManager?.registerUndo(withTarget: self) { $0.splitPosition = oldValue }
			needsLayout = true
		}
	}
	var observer: Any?
	init(isVertical: Bool, left: SubView, right: SubView, splitPosition: CGFloat) {
		self.splitPosition = splitPosition
        sv = NSSplitView()
	
		
        sv.isVertical = isVertical
        sv.setValue(NSColor.black, forKey: "dividerColor")
        sv.addArrangedSubview(left)
        sv.addArrangedSubview(right)
		sv.dividerStyle = .thin
        self.isVertical = isVertical
        self.left = left
        self.right = right
        super.init(frame: .zero)
		sv.delegate = self
        addContainedSubview(sv)
    }

	
	func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
		if !isEditing {
			return splitPosition * self.bounds.width
		}
		splitPosition = proposedPosition / self.bounds.width
		return proposedPosition
	}
	
	enum Keys: String {
		case isVertical, left, right, splitPosition
	}
	required convenience init(from dictionary: DictionaryBox<Keys>) throws {
		let isVertical: Bool = try dictionary(.isVertical)
		let splitPosition: CGFloat =  (try? dictionary(.splitPosition)) ?? 0.5
		let left = try viewFrom(dictionary: try dictionary(.left))
		let right = try viewFrom(dictionary: try dictionary(.right))
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
			sv.dividerStyle = isEditing ? .thick : .thin
		}
	}
	
	var children: [SubView] {
		return [left, right]
	}
	
	lazy var inspectorView: NSView? = {
		let iv = InspectorView()
		let av = TextAttributeView(label: "Split Position")
		av.textField.bind(.value, to: self, withKeyPath: "splitPosition", options: nil)
		iv.addAttribute(view: av)
		return iv
	}()
	
	func didSelectViewInInspector() {
		isEditing = true
	}
	
	func didDeselectViewInInspector() {
		isEditing = false
	}
}

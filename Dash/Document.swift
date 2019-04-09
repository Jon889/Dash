//
//  Document.swift
//  Dash
//
//  Created by Jonathan Bailey on 04/03/2019.
//  Copyright © 2019 jonathan. All rights reserved.
//

import Cocoa
import WebKit


let viewTypes: [SubView.Type] = [SplitView.self, PageView.self, WebPageView.self, ColorView.self, PlaceholderView.self]
func viewFrom(dictionary: [String: Any]) throws -> SubView {
    guard let type = dictionary["type"] as? String else {
		throw MissingKeyError(key: "type")
	}
	
	for viewType in viewTypes {
		if type == viewType.type {
			return try viewType.init(from: dictionary)
		}
	}
	throw InvalidValueError(key: "type", message: "Couldn't create view from type \(type)")
}

typealias SubView = NSView & SubViewType
typealias View = NSView & ViewType

protocol SubViewType: AnyObject {
	var dictionary: [String: Any] { get }
	var isEditing: Bool { get set }
	init(from dictionary: [String: Any]) throws
	init()
	static var type: String { get }
	var children: [SubView] { get }
	var inspectorView: NSView? { get }
}

extension SubViewType {
	var children: [SubView] {
		return []
	}
	var inspectorView: NSView? {
		return nil
	}
}
protocol ViewType: SubViewType {
	associatedtype K: RawRepresentable where K.RawValue == String
	var dictionary: DictionaryBox<K> { get }
	init(from dictionary: DictionaryBox<K>) throws
}

struct MissingKeyError: Error {
	let key: String
}

struct ValueIncorrectTypeError: Error {
	let key: String
	let expectedType: String
	let actualType: String
}

struct InvalidValueError: Error {
	let key: String
	let message: String
}

extension ViewType {
	var dictionary: [String: Any] {
		var dictionary = self.dictionary.dictionary
		if dictionary["type"] == nil {
			dictionary["type"] = Self.type
		}
		return dictionary
	}
	init(from dictionary: [String: Any]) throws {
		try self.init(from: DictionaryBox<K>(dictionary: dictionary))
	}
}
class Document: NSDocument {
	@IBOutlet var editPanel: NSPanel!
	@objc
	func editMode(_ menuItem: NSMenuItem) {
		menuItem.state = menuItem.state == .off ? .on : .off
		contents?.isEditing = menuItem.state == .on
	}
	@objc
	func reloadWebviews(_ sender: Any) {
		contents?.performActionOnSubviews(#selector(WebPageView.reloadWebview(_:)), sender: sender)
	}
	
	var contents: SubView? {
		didSet {
			let superview = oldValue?.superview
			oldValue?.removeFromSuperview()
			contents.map { superview?.addContainedSubview($0) }
		}
	}
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class var autosavesInPlace: Bool {

        return true

    }

	@IBOutlet var outlineView: NSOutlineView!
	override var windowNibName: NSNib.Name? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return NSNib.Name("Document")
    }
    
    private var fileWrapper: DashFileWrapper?
    
    override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
        let fileWrapper = DashFileWrapper(fileWrapper)
		if let dict = try JSONSerialization.jsonObject(with: fileWrapper.contentsJSON, options: []) as? [String : Any] {
			contents = try viewFrom(dictionary: dict)
		}
        self.fileWrapper = fileWrapper
    }

    
    override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        let fileWrapper = self.fileWrapper ?? DashFileWrapper()
        self.fileWrapper = fileWrapper
        
        let dict = contents?.dictionary ?? [:]
        let data = try JSONSerialization.data(withJSONObject: dict, options: [])
        fileWrapper.contentsJSON = data
        return fileWrapper
    }

    override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
        if let contents = contents {
            windowController.window?.contentView?.addContainedSubview(contents)
		} else {
			contents = try! PlaceholderView.init(from: [:])
			windowController.window?.contentView?.addContainedSubview(contents!)
		}
        windowController.window?.delegate = self
		outlineView.dataSource = self
		outlineView.target = self
		outlineView.action = #selector(outlineViewDidSelect(_:))
		outlineView.reloadData()
    }
	
	@IBOutlet var inspectorView: NSView!
	@objc
	private func outlineViewDidSelect(_ object: Any) {
		let selected = outlineView.selectedRow
		self.inspectorView.subviews.forEach { $0.removeFromSuperview() }
		guard let item = outlineView.item(atRow: selected) as? SubView,
			let inspectorView = item.inspectorView else { return }
		self.inspectorView.addContainedSubview(inspectorView)
	}
}

extension Document: NSOutlineViewDataSource {
	
	
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		if let item = item as? SubView {
			return item.children.count
		} else {
			return contents == nil ? 0 : 1
		}
	}
	
	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		return ((item as? SubView)?.children.count ?? 0) != 0
	}
	
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		if let item = item as? SubView {
			return item.children[index]
		} else {
			return contents as Any
		}
	}
	
	func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
		guard let subView = item as? SubView else { return "View" }
		return type(of: subView).type
	}
	

}

extension Document: NSWindowDelegate {

    func windowDidResignKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if NSApp.isActive { return }
        if !NSEvent.modifierFlags.contains(.shift) {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKey()
            
            if let view = window.contentView {
                let label = NSTextField()
                label.isEditable = false
                label.backgroundColor = .black
                label.textColor = .white
                label.font = NSFont.systemFont(ofSize: 50)
                label.stringValue = "Hold shift to leave window"
                label.isBordered = false
                view.addSubview(label)
                label.centerXAnchor.constrain(equalTo: view.centerXAnchor)
                label.centerYAnchor.constrain(equalTo: view.centerYAnchor)
                Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                    NSAnimationContext.runAnimationGroup({ context in
                        context.duration = 1
                        
                        label.animator().alphaValue = 0
                    }, completionHandler: {
                        label.removeFromSuperview()
                    })
                }
            }
        }
    }
}

extension NSView {
    func addContainedSubview(_ subview: NSView) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        [
            subview.leftAnchor.constraint(equalTo: leftAnchor),
            subview.topAnchor.constraint(equalTo: topAnchor),
            subview.rightAnchor.constraint(equalTo: rightAnchor),
            subview.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()
    }
}
extension Array where Element == NSLayoutConstraint {
    func activate() {
        NSLayoutConstraint.activate(self)
    }
}
extension NSLayoutAnchor {
    @objc
    @discardableResult
    func constrain(equalTo anchor: NSLayoutAnchor<AnchorType>, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {
        let constraint = self.constraint(equalTo: anchor)
        (constraint.firstItem as? NSView)?.translatesAutoresizingMaskIntoConstraints = false
        constraint.priority = priority
        constraint.isActive = true
        return constraint
    }
}


extension NSColor {
    
    var hexString: String {
        guard let rgbColor = usingColorSpace(.sRGB) else {
            return "#FFFFFF"
        }
        let red = Int(round(rgbColor.redComponent * 0xFF))
        let green = Int(round(rgbColor.greenComponent * 0xFF))
        let blue = Int(round(rgbColor.blueComponent * 0xFF))
        let hexString = NSString(format: "#%02X%02X%02X", red, green, blue)
        return hexString as String
    }
}

extension NSColor {
    class func fromHex(hex: Int, alpha: Float) -> NSColor {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let blue = CGFloat((hex & 0xFF)) / 255.0
        return NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1.0)
    }
    
    class func fromHexString(hex: String, alpha: Float) -> NSColor? {
        // Handle two types of literals: 0x and # prefixed
        var cleanedString = ""
        if hex.hasPrefix("0x") {
            cleanedString = String(hex.dropFirst(2))
        } else if hex.hasPrefix("#") {
            cleanedString = String(hex.dropFirst())
        }
        // Ensure it only contains valid hex characters 0
        let validHexPattern = "[a-fA-F0-9]+"
        if cleanedString.conformsTo(pattern: validHexPattern) {
            var theInt: UInt32 = 0
            let scanner = Scanner(string: cleanedString)
            scanner.scanHexInt32(&theInt)
            let red = CGFloat((theInt & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((theInt & 0xFF00) >> 8) / 255.0
            let blue = CGFloat((theInt & 0xFF)) / 255.0
            return NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1.0)
            
        } else {
            return nil
        }
    }
}

extension NSColor: Encodable {
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(hexString)
    }
}

extension String  {
    func conformsTo(pattern: String) -> Bool {
        let pattern = NSPredicate(format:"SELF MATCHES %@", pattern)
        return pattern.evaluate(with: self)
    }
}

extension Dictionary where Key: RawRepresentable, Key.RawValue: Hashable  {
	func rawKeys() -> [Key.RawValue: Value] {
		return Dictionary<Key.RawValue, Value>(uniqueKeysWithValues: self.map { ($0.key.rawValue, $0.value) })
	}
}

extension Dictionary where Key == String {
	subscript <T: RawRepresentable>(_ key: T) -> Value? where T.RawValue == String {
		return self[key.rawValue]
	}
}

extension NSView {
	func performActionOnSubviews(_ action: Selector, sender: Any) {
		for view in subviews {
			if view.responds(to: action) {
				view.perform(action, with: sender)
			}
			view.performActionOnSubviews(action, sender: sender)
		}
	}
}

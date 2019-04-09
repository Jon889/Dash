//
//  WebPageView.swift
//  Dash
//
//  Created by Jonathan Bailey on 13/03/2019.
//  Copyright © 2019 jonathan. All rights reserved.
//

import Cocoa
import WebKit

class WebPageView: View {

	static var type: String = "WebView"
	
	@IBOutlet var webView: WKWebView!
	@IBOutlet var editToolbar: NSView!
	
	@objc dynamic
	private var zoomLevel: CGFloat = 1 {
		didSet {
			needsLayout = true
			undoManager?.registerUndo(withTarget: self) { $0.zoomLevel = oldValue }
		}
	}
	private static let processPool = WKProcessPool()
	@objc dynamic
	private var url: URL {
		didSet {
			undoManager?.registerUndo(withTarget: self) { $0.url = oldValue }
			webView.load(URLRequest(url: url))
		}
	}
	
	required convenience init() {
		self.init(url: URL(string: "http://google.com")!, zoom: 1)
	}
	
	public init(url: URL, zoom: CGFloat) {
		self.url = url
		super.init(frame: .zero)
		if let rootView = NSNib.loadRootViewFromNib(for: self) {
			addContainedSubview(rootView)
		}
		
		let config = WKWebViewConfiguration()
		config.processPool = WebPageView.processPool
		
        webView.load(URLRequest(url: url))
		zoomLevel = zoom
		needsLayout = true
    }
	
	@IBAction
	private func didTapZoomIn(_ sender: Any) {
		zoomLevel += 0.2
	}
	@IBAction
	private func didTapZoomOut(_ sender: Any) {
        zoomLevel -= 0.2
    }
	@objc
	func reloadWebview(_ sender: Any) {
		webView.reload()
	}
    override func layout() {
        super.layout()
        webView.frame.size = CGSize(width: frame.width * (1/zoomLevel), height: frame.height * (1/zoomLevel))
        webView.layer?.transform = CATransform3DMakeScale(zoomLevel, zoomLevel, 1)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
	required convenience init(from dictionary: DictionaryBox<Keys>) throws {
		self.init(url: try dictionary(.url),
				  zoom: (try? dictionary(.zoom)) ?? 1)
	}
	
	enum Keys: String {
		case url, zoom
	}
	
	var dictionary: DictionaryBox<Keys>  {
		return [ .url: url.absoluteString, .zoom: zoomLevel ]
	}
	
	var isEditing: Bool = false {
		didSet {
			editToolbar.isHidden = !isEditing
		}
	}
	
	lazy var inspectorView: NSView? = {
		let iv = InspectorView()
		let av = TextAttributeView(label: "URL")
		let t = ValueTransformer.init()
		av.textField.bind(.value, to: self, withKeyPath: "url", options: [NSBindingOption.valueTransformer: URLTransformer()])
		iv.addAttribute(view: av)
		
		let av2 = TextAttributeView(label: "Zoom")
		av2.textField.bind(.value, to: self, withKeyPath: "zoomLevel", options: nil)
		iv.addAttribute(view: av2)
		return iv
	}()
    
}

class VTransformer<From, To>: ValueTransformer {
	override func transformedValue(_ value: Any?) -> Any? {
		guard let value = value as? From else { return nil }
		return transformed(value: value)
	}
	override func reverseTransformedValue(_ value: Any?) -> Any? {
		guard let value = value as? To else { return nil }
		return transformed(value: value)
	}
	
	override class func allowsReverseTransformation() -> Bool {
		return true
	}
	
	func transformed(value: From) -> To? {
		fatalError("Abstract")
	}
	
	func transformed(value: To) -> From? {
		fatalError("Abstract")
	}
}

class URLTransformer: VTransformer<URL, String> {
	override func transformed(value: URL) -> String? {
		return value.absoluteString
	}
	override func transformed(value: String) -> URL? {
		return URL(string: value)
	}
}


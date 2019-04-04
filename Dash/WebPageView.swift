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
	
    static let processPool = WKProcessPool()
    
    var url: String
    
    let webView: WKWebView
    let button: NSButton
	public init(url: URL, zoom: CGFloat) {
        self.url = url.absoluteString
        let config = WKWebViewConfiguration()
        config.processPool = WebPageView.processPool
        
        self.webView = WKWebView.init(frame: .zero, configuration: config)
        self.button = NSButton(title: "(-)", target: nil, action: nil)
        super.init(frame: .zero)
        webView.load(URLRequest(url: url))
        addSubview(webView)
        webView.frame = bounds
        webView.autoresizingMask = [.width, .height]
        button.target = self
        button.action = #selector(didTapZoomOut)
        addSubview(button)
        button.topAnchor.constrain(equalTo: topAnchor)
        button.leftAnchor.constrain(equalTo: leftAnchor)
		button.isHidden = true
		zoomLevel = zoom
		needsLayout = true
    }
    var zoomLevel: CGFloat = 1
    @objc
    private func didTapZoomOut() {
        zoomLevel -= 0.2
        needsLayout = true
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
		let urlStr: String = try dictionary(.url)
		guard let url = URL(string: urlStr) else {
			throw InvalidValueError(key: "url", message: "Unable to create url from \(urlStr)")
		}
		let zoom: CGFloat = (try? dictionary(.zoom)) ?? 1
		self.init(url: url, zoom: zoom)
	}
	enum Keys: String {
		case url, zoom
	}
	
	var dictionary: DictionaryBox<Keys>  {
		return [ .url: url, .zoom: zoomLevel ]
	}
	
	var isEditing: Bool = false {
		didSet {
			button.isHidden = !isEditing
		}
	}
    
}


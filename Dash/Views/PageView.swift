//
//  PageView.swift
//  Dash
//
//  Created by Jonathan Bailey on 20/03/2019.
//  Copyright © 2019 jonathan. All rights reserved.
//

import Cocoa

class PageView: View {
	required convenience init() {
		self.init(pages: [], timeOnEachPage: 1, animationDuration: 1)
	}
	
	static var type: String = "PageView"
	

    private let pageCount: Int
    private let scrollView: NSScrollView
    private var timer: Timer?
	
	@objc dynamic
	private var timeOnEachPage: TimeInterval {
		didSet {
			undoManager?.registerUndo(withTarget: self) { $0.timeOnEachPage = oldValue }
			stopAutoScroll()
			startAutoScroll()
		}
	}
	@objc dynamic
	private var animationDuration: TimeInterval {
		didSet {
			undoManager?.registerUndo(withTarget: self) { $0.animationDuration = oldValue }
			stopAutoScroll()
			startAutoScroll()
		}
	}
    private let pages: [SubView]
    
    init(pages: [SubView], timeOnEachPage: TimeInterval, animationDuration: TimeInterval) {
        self.pages = pages
        let sv = NSScrollView()
        self.scrollView = sv
        let documentView = NSView()
        sv.documentView = documentView
        sv.contentView.topAnchor.constrain(equalTo: documentView.topAnchor)
        sv.contentView.leftAnchor.constrain(equalTo: documentView.leftAnchor)
        sv.contentView.bottomAnchor.constrain(equalTo: documentView.bottomAnchor)
        documentView.heightAnchor.constraint(equalTo: sv.heightAnchor).isActive = true
        var lastAnchor = documentView.leftAnchor
        self.pageCount = pages.count
        for page in pages {
            let v = page
            documentView.addSubview(v)
            v.leftAnchor.constrain(equalTo: lastAnchor)
            v.widthAnchor.constrain(equalTo: sv.widthAnchor)
            v.topAnchor.constrain(equalTo: documentView.topAnchor)
            v.bottomAnchor.constrain(equalTo: documentView.bottomAnchor)
            lastAnchor = v.rightAnchor
        }
        documentView.rightAnchor.constrain(equalTo: lastAnchor)
        sv.hasVerticalScroller = false
        sv.hasHorizontalScroller = true
        self.timeOnEachPage = timeOnEachPage
        self.animationDuration = animationDuration
        super.init(frame: .zero)
        addContainedSubview(sv)
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        startAutoScroll()
    }
    
    func startAutoScroll() {
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeOnEachPage + animationDuration), repeats: true) { _ in
			if self.pageCount == 0 { return }
            let nextPage = (self.currentPage + 1) % self.pageCount
			self.moveToPage(at: nextPage, animationDuration: self.animationDuration)
        }
    }
    
    func stopAutoScroll() {
        timer?.invalidate()
        timer = nil
    }
    
    func moveToPage(at index: Int, animationDuration: Double) {
        let p = NSPoint(x: CGFloat(index) * self.bounds.width, y: 0)
        scrollView.scroll(to: p, animationDuration: animationDuration)
    }
    
    var currentPage: Int {
        return Int(scrollView.contentView.bounds.origin.x / self.bounds.width)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
	enum Keys: String {
		case pages, timeOnEachPage, animationDuration
	}
	
	required convenience init(from dictionary: DictionaryBox<Keys>) throws {
		let pagesDicts: [[String: Any]] = try dictionary(.pages)
		let timeOnEachPage: TimeInterval = try dictionary(.timeOnEachPage)
		let animationDuration: TimeInterval = try dictionary(.animationDuration)
		let pages = try pagesDicts.map { try viewFrom(dictionary: $0) }
		self.init(pages: pages, timeOnEachPage: timeOnEachPage, animationDuration: animationDuration)
	}
    
    
    var dictionary: DictionaryBox<Keys> {
		return [ .pages: pages.map { $0.dictionary }, .timeOnEachPage: timeOnEachPage, .animationDuration: animationDuration ]
    }
	
	var children: [SubView] {
		return pages
	}
	
	lazy var inspectorView: NSView? = {
		let iv = InspectorView()
		let av = TextAttributeView(label: "Time On Each Page")
		av.textField.bind(.value, to: self, withKeyPath: "timeOnEachPage", options: nil)
		iv.addAttribute(view: av)
		
		let av2 = TextAttributeView(label: "Animation Duration")
		av2.textField.bind(.value, to: self, withKeyPath: "animationDuration", options: nil)
		iv.addAttribute(view: av2)
		return iv
	}()
    
}

extension NSScrollView {
    func scroll(to point: NSPoint, animationDuration: Double) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = animationDuration
        contentView.animator().setBoundsOrigin(point)
        reflectScrolledClipView(contentView)
        NSAnimationContext.endGrouping()
    }
}

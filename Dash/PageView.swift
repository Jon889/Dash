//
//  PageView.swift
//  Dash
//
//  Created by Jonathan Bailey on 20/03/2019.
//  Copyright © 2019 jonathan. All rights reserved.
//

import Cocoa

class PageView: View {
	static var type: String = "PageView"
	

    private let pageCount: Int
    private let scrollView: NSScrollView
    private var timer: Timer?
    
    private let timeOnEachPage: TimeInterval
    private let animationDuration: TimeInterval
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
//        sv.scrollerStyle = .legacy
        self.timeOnEachPage = timeOnEachPage
        self.animationDuration = animationDuration
        super.init(frame: .zero)
        addContainedSubview(sv)
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        startAutoScroll(timeOnEachPage: timeOnEachPage, animationDuration: animationDuration)
    }
    
    func startAutoScroll(timeOnEachPage: TimeInterval, animationDuration: TimeInterval) {
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeOnEachPage + animationDuration), repeats: true) { _ in
            let nextPage = (self.currentPage + 1) % self.pageCount
            self.moveToPage(at: nextPage, animationDuration: animationDuration)
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
	
	var isEditing: Bool = false {
		didSet {
			pages.forEach { $0.isEditing = isEditing }
		}
	}
    
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

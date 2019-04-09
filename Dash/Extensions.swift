//
//  Extensions.swift
//  Dash
//
//  Created by Jonathan Bailey on 09/04/2019.
//  Copyright © 2019 jonathan. All rights reserved.
//

import Cocoa
import Foundation


extension NSNib {
	static func loadRootViewFromNib(for owner: NSObject) -> NSView? {
		let nib = NSNib(nibNamed: owner.nibName, bundle: Bundle(for: type(of: owner)))
		return nib?.getRootView(owner: owner)
	}
	func getRootView(owner: Any? = nil) -> NSView? {
		var topLevelObjects: NSArray?
		self.instantiate(withOwner: owner, topLevelObjects: &topLevelObjects)
		if let rootView = topLevelObjects?.first(where: { $0 is NSView }) as? NSView {
			return rootView
		}
		return nil
	}
}


extension NSObject {
	var nibName: String {
		if let lastComponent = self.className.split(separator: ".").last {
			return String(lastComponent)
		}
		return self.className
	}
}

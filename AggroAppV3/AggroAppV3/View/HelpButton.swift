//
//  HelpButton.swift
//  AggroAppV3
//
//  Created by WUMBAch on 10.04.2022.
//

import UIKit

class HelpButton: UIButton {

    // MARK: - UIButton life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        fatalError("init(coder:) has not been implemented")
    }
    
    //public functions
    public func configure(text: String, boldText: String) {

        let atts: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor(white: 1, alpha: 0.87), .font: UIFont.systemFont(ofSize: 16)]
        let boldAtts: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor(white: 1, alpha: 0.87), .font: UIFont.boldSystemFont(ofSize: 16)]
        let attribtutedTitle = NSMutableAttributedString(string: text, attributes: atts)
        attribtutedTitle.append(NSAttributedString(string: boldText, attributes: boldAtts))

        setAttributedTitle(attribtutedTitle, for: .normal)
    }
}

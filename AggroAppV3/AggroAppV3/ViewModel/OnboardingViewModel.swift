//
//  OnboardingViewModel.swift
//  AggroAppV3
//
//  Created by WUMBAch on 11.04.2022.
//

struct OnboardingViewModel {
    
    private let itemCount: Int
    
    init(itemCount: Int) {
        self.itemCount = itemCount
    }
    
    func shouldShowGetStartedButton(forIndex index: Int) -> Bool {
        return index == itemCount - 1 ? true : false
    }
}

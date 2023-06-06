//////////////////////////////////////////////////////////////////////////////////
//
//  SYMBIOSE
//  Copyright 2023 Symbiose Technologies, Inc
//  All Rights Reserved.
//
//  NOTICE: This software is proprietary information.
//  Unauthorized use is prohibited.
//
// 
// Created by: Ryan Mckinney on 6/5/23
//
////////////////////////////////////////////////////////////////////////////////

import Foundation
import Combine
import RxSwift

#if os(iOS)
@available(iOS 13.0, *)
public class KeyboardHeightPublisher: ObservableObject {
    private let disposeBag = DisposeBag()
    
    @Published public var keyboardHeight: CGFloat = 0

    public init() {
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] height in
                print("Keyboard height: \(height)")
                self?.keyboardHeight = height
            })
            .disposed(by: disposeBag)
    }
}

#elseif os(macOS)
public class KeyboardHeightPublisher: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0

    public init() {
        // Do nothing on macOS, making this a "stub"
    }
}
#endif

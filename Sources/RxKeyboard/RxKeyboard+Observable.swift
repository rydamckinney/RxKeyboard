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
import SwiftUI


public extension View {
    
    func keyboardBottomPadding(addlPadding: Binding<CGFloat>? = nil,
                               ignoreAllBottomSafeArea: Bool = false,
                               includeBottomSafeAreaPadding: Bool = false) -> some View {
        self
            .modifier(KeyboardHeightPaddingModifier(addlPadding: addlPadding,
                                                    ignoreBottomSafeAreaRegion: ignoreAllBottomSafeArea ? .all : .keyboard,
                                                    includeBottomSafeAreaPadding: includeBottomSafeAreaPadding))
    }
    
    
    func keyboardBottomPadding(addlPadding: Binding<CGFloat>? = nil,
                               ignoreBottomSafeAreaRegions: SafeAreaRegions? = nil,
                               includeBottomSafeAreaPadding: Bool = false) -> some View {
        self
            .modifier(KeyboardHeightPaddingModifier(addlPadding: addlPadding,
                                                    ignoreBottomSafeAreaRegion: ignoreBottomSafeAreaRegions,
                                                    includeBottomSafeAreaPadding: includeBottomSafeAreaPadding))
    }
}

public struct KeyboardPaddingSpacer: View {
    
    public init() {
        
    }
    
    public var body: some View {
        Spacer()
            .frame(height: 1)
            .keyboardBottomPadding(ignoreAllBottomSafeArea: false)
    }
    
}



public struct KeyboardHeightPaddingModifier: ViewModifier {
    
    let heightPublisher: KeyboardHeightPublisher
    let ignoreAllBottomSafeArea: Bool
    let includeBottomSafeAreaPadding: Bool
    
    @Binding var addlPadding: CGFloat
    
    let btmSafeAreaToIgnore: SafeAreaRegions?
    
    public init(addlPadding: Binding<CGFloat>? = nil,
                ignoreBottomSafeAreaRegion: SafeAreaRegions? = nil,
                includeBottomSafeAreaPadding: Bool = true
    ) {
        self.heightPublisher = KeyboardHeightPublisher()
        
        if let additionalPadding = addlPadding {
            self._addlPadding = additionalPadding
        } else {
            self._addlPadding = .constant(0)
        }
        self.btmSafeAreaToIgnore = ignoreBottomSafeAreaRegion
        
        self.includeBottomSafeAreaPadding = includeBottomSafeAreaPadding
        
        
        self.ignoreAllBottomSafeArea = false
    }
    
    @State var kbHeight: CGFloat = .zero
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets
    
    var safeAreaRegionToIgnore: SafeAreaRegions {
        if ignoreAllBottomSafeArea {
            return .all
        } else {
            return .keyboard
        }
    }
    
    var regionToIgnore: SafeAreaRegions {
        if let region = self.btmSafeAreaToIgnore {
            return region
        } else {
            return .keyboard
        }
    }
    
    var edgesToIgnore: Edge.Set {
        if let region = self.btmSafeAreaToIgnore {
            return .bottom
        } else  {
            return .top //no-op for keyboard
        }
    }
    
    var containerSafeAreaPadding: CGFloat {
        self.includeBottomSafeAreaPadding ? safeAreaInsets.bottom : 0
    }
    
    
    public func body(content: Content) -> some View {
        content
            .padding(.bottom, max(0, kbHeight + addlPadding - safeAreaInsets.bottom))
        ///BELOW WORKS
        //            .padding(.bottom, kbHeight + addlPadding + containerSafeAreaPadding)
            .onReceive(heightPublisher.$keyboardHeight) { newKbHeight in
//                print("[KEyboardHEightPaddingModifier] Keyboard height: old: \(self.kbHeight) new: \(newKbHeight)")
                
                // calculate the delta
                let delta = abs(kbHeight - newKbHeight)

                if delta > 100 {
                    withAnimation(.easeOut(duration: 0.16)) {
                        kbHeight = newKbHeight
                    }
                } else {
                    kbHeight = newKbHeight
                }
//                if kbHeight == 0 || newKbHeight == 0 {
//                    withAnimation(.easeOut(duration: 0.16)) {
//                        kbHeight = newKbHeight
//                    }
//                } else {
//                    kbHeight = newKbHeight
//                }
            }
            .ignoresSafeArea(self.regionToIgnore, edges: self.edgesToIgnore)

        
    }
    
}

public extension View {
    func setAsPinnedKeyboardInput(_ addlPadding: Binding<CGFloat>? = nil) -> some View {
        self.modifier(KeyboardPinnedInputModifier(addlPadding: addlPadding))
    }
}
public struct KeyboardPinnedInputModifier: ViewModifier {
    
    let heightPublisher: KeyboardHeightPublisher
    
    @Binding var addlPadding: CGFloat
        
    public init(addlPadding: Binding<CGFloat>? = nil
    ) {
        self.heightPublisher = KeyboardHeightPublisher()
        if let additionalPadding = addlPadding {
            self._addlPadding = additionalPadding
        } else {
            self._addlPadding = .constant(0)
        }
    }
    
    @State var kbHeight: CGFloat = .zero
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets
    
    public func body(content: Content) -> some View {
        content
            .padding(.bottom, max(0, kbHeight + addlPadding - safeAreaInsets.bottom))
            .onReceive(heightPublisher.$keyboardHeight) { newKbHeight in
//                print("[KeyboardPinnedInputModifier] Keyboard height: old: \(self.kbHeight) new: \(newKbHeight)")
                if self.kbHeight == newKbHeight {
//                    print("[KeyboardPinnedInputModifier] keyboard height is the same, returning")
                    return
                }
                
                // calculate the delta
                let delta = abs(kbHeight - newKbHeight)

                if delta > 100 {
                    withAnimation(.easeOut(duration: 0.16)) {
                        kbHeight = newKbHeight
                    }
                } else {
                    kbHeight = newKbHeight
                }
                
//                if kbHeight == 0 || newKbHeight == 0 {
//                    withAnimation(.easeInOut(duration: 0.35)) {
//                        kbHeight = newKbHeight
//                    }
//                } else {
//                    kbHeight = newKbHeight
//                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
}


#if os(iOS)
@available(iOS 13.0, *)
public class KeyboardHeightPublisher: ObservableObject {
    private let disposeBag = DisposeBag()
    
    @Published public var keyboardHeight: CGFloat = 0

    public init() {
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] height in
//                print("Keyboard height: \(height)")
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



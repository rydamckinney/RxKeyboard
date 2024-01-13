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


#if canImport(UIKit)
import UIKit
public typealias Rx_PlatformScrollView = UIScrollView
#elseif canImport(AppKit)
import AppKit
public typealias Rx_PlatformScrollView = NSScrollView
#endif

#if canImport(UIKit)
public struct RxKeyboardHolder {
    
    let disposeBag = DisposeBag()
    public init() { }
    
    public func makeScrollViewInsetKbAware(_ scrollView: Rx_PlatformScrollView) {
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [scrollView] keyboardVisibleHeight in
                print("[RxKeyboardHolder] \n inset.bottom \(scrollView.contentInset.bottom) \n contentOffset.y \(scrollView.contentOffset.y) with keyboardVisibleHeight: \(keyboardVisibleHeight)")
                UIView.animate(withDuration: 0) {
                    scrollView.contentInset.bottom = keyboardVisibleHeight
                    scrollView.scrollIndicatorInsets.bottom = scrollView.contentInset.bottom
                    scrollView.layoutIfNeeded()
                }
                print("[RxKeyboardHolder] bottom contentInset \(scrollView.contentInset.bottom) after setting")
            })
            .disposed(by: disposeBag)
        
        RxKeyboard.instance.willShowVisibleHeight
          .drive(onNext: { keyboardVisibleHeight in
            scrollView.contentOffset.y += keyboardVisibleHeight
          })
          .disposed(by: self.disposeBag)
        
    }
    
}
#endif

public class KeyboardPaddingHolder: ObservableObject {

    @Published public var aggHeight: CGFloat
    
    
    public init(_ initialHeight: CGFloat = 0) {
        self.aggHeight = initialHeight
    }
    
    public var heightBinding: Binding<CGFloat> {
        Binding<CGFloat>(
            get: { [weak self] in
                self?.aggHeight ?? 0
            },
            set: { [weak self] in
//                print("KeyboardPaddingHolder set heightBinding: \($0) previous: \(self?.aggHeight ?? -1)")
                guard let self = self else { return }
                if self.aggHeight != $0 {
                    self.aggHeight = $0
                }
                
//                self?.aggHeight = $0
            }
        )
    }
    
}


public extension View {
    
    @ViewBuilder
    func keyboardBottomPadding(addlPadding: Binding<CGFloat>? = nil,
                               paddingHolder: KeyboardPaddingHolder? = nil,
                               ignoreBottomSafeAreaRegions: SafeAreaRegions? = nil,
                               includeBottomSafeAreaPadding: Bool = false,
                               paddingType: KeyboardHeightPaddingModifier.PaddingType = .contentMarginIfPossible,
                               skipApply: Bool = false) -> some View {
        if skipApply {
            self
        } else {
            self
                .modifier(KeyboardHeightPaddingModifier(addlPadding: addlPadding,
                                                        paddingHolder: paddingHolder,
                                                        ignoreBottomSafeAreaRegion: ignoreBottomSafeAreaRegions,
                                                        includeBottomSafeAreaPadding: includeBottomSafeAreaPadding,
                                                        paddingType: paddingType
                                                        
                                                       )
                )
            
        }
    }
}

public struct KeyboardPaddingSpacer: View {
    
    public init() {
        
    }
    
    public var body: some View {
        Spacer()
            .frame(height: 1)
            .keyboardBottomPadding(
                ignoreBottomSafeAreaRegions: .keyboard
            )
    }
    
}



public struct KeyboardHeightPaddingModifier: ViewModifier {
    public enum PaddingType {
        case padding
        case contentMarginIfPossible //falls back to padding
        case offset //uses voffset instead
    }
    
    let heightPublisher: KeyboardHeightPublisher
    let ignoreAllBottomSafeArea: Bool
    let includeBottomSafeAreaPadding: Bool
    
    @ObservedObject var paddingHolder: KeyboardPaddingHolder
    
    @Binding var addlPadding: CGFloat
    
    let btmSafeAreaToIgnore: SafeAreaRegions?
    let paddingType: PaddingType
    
    public init(addlPadding: Binding<CGFloat>? = nil,
                paddingHolder: KeyboardPaddingHolder? = nil,
                ignoreBottomSafeAreaRegion: SafeAreaRegions? = nil,
                includeBottomSafeAreaPadding: Bool = true,
                paddingType: PaddingType = .contentMarginIfPossible
    ) {
        self.heightPublisher = KeyboardHeightPublisher()
        
        self.paddingHolder = paddingHolder ?? KeyboardPaddingHolder()
        
        
        
        self.paddingType = paddingType
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
    
//    var providedAdditionalPadding: CGFloat {
//        
//    }
    
    var resolvedBottomPadding: CGFloat {
//        let safeAreaInsetAdjustment = safeAreaInsets.bottom
        let safeAreaInsetAdjustment: CGFloat = 0

        let resolved  = max(0, kbHeight + addlPadding + paddingHolder.aggHeight + safeAreaInsetAdjustment)
            print("[KeyboardHeightPaddingModifier] resolvedBottomPadding: \(resolved) ")
        return resolved
    }
//    @Environment(\.isFocused) var isFocused
    
    @ViewBuilder
    func bodyContentWithPadding(content: Content) -> some View {
        if paddingType == .offset {
            content
                .offset(y: -resolvedBottomPadding)
        } else if #available(iOS 17.0, macOS 14.0, *),
           paddingType == .contentMarginIfPossible {
            content
                .contentMargins(.bottom, resolvedBottomPadding)
//                .contentMargins(.bottom, resolvedBottomPadding, for: .scrollContent)
//                .contentMargins(.bottom, resolvedBottomPadding, for: .scrollIndicators)

        } else {
            content
                .padding(.bottom, resolvedBottomPadding)

        }
        
    }
    
    public func body(content: Content) -> some View {
        
        let _ = Self._printChanges()
        
        bodyContentWithPadding(content: content)
        
//        content
//            .padding(.bottom, max(0, kbHeight + addlPadding - safeAreaInsets.bottom))
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
            }
            .ignoresSafeArea(self.regionToIgnore, edges: self.edgesToIgnore)
    }
    
}

public extension View {
    func setAsPinnedKeyboardInput(_ addlPadding: Binding<CGFloat>? = nil, containerSafeAreaHandling: KeyboardPinnedInputModifier.ContainerSafeAreaHandling = .subtract
    ) -> some View {
        self.modifier(KeyboardPinnedInputModifier(
            addlPadding: addlPadding, containerSafeAreaHandling: containerSafeAreaHandling)
        )
    }
}
public struct KeyboardPinnedInputModifier: ViewModifier {
    public enum ContainerSafeAreaHandling {
        case add
        case subtract
        case nothing
    }
    
    let heightPublisher: KeyboardHeightPublisher
    
    @Binding var addlPadding: CGFloat
    
    let containerSafeAreaHandling: ContainerSafeAreaHandling
    
    public init(addlPadding: Binding<CGFloat>? = nil,
                containerSafeAreaHandling: ContainerSafeAreaHandling
    ) {
        self.heightPublisher = KeyboardHeightPublisher()
        
        self.containerSafeAreaHandling = containerSafeAreaHandling
        
        if let additionalPadding = addlPadding {
            self._addlPadding = additionalPadding
        } else {
            self._addlPadding = .constant(0)
        }
    }
    
    @State var kbHeight: CGFloat = .zero
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets
    
    var resolvedContainerSafeAreaAugmentation: CGFloat {
        switch self.containerSafeAreaHandling {
        case .add:
            return safeAreaInsets.bottom
        case .subtract:
            return -safeAreaInsets.bottom
        case .nothing:
            return 0
        }
    }
    
    public func body(content: Content) -> some View {
        let _ = Self._printChanges()

        content
            .padding(.bottom, max(0, kbHeight + addlPadding + resolvedContainerSafeAreaAugmentation))
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
                print("Keyboard height: \(height)")
                self?.keyboardHeight = height
            })
            .disposed(by: disposeBag)
    }
    public static var shared = KeyboardHeightPublisher()
    
}

@available(iOS 13.0, *)
public class KeyboardScrollViewManager {
    
    weak var scrollView: UIScrollView?
    
    private let disposeBag = DisposeBag()

    public init() {
        
    }
    
    public func setScrollView(_ scrollView: UIScrollView) {
        
        self.scrollView = scrollView
        print("KeyboardScrollViewManager - existing scrollView contentInset: \(scrollView.contentInset) contentOffset: \(scrollView.contentOffset)")
        
        self.setup()
        
    }
    
    private func setup() {
        RxKeyboard.instance.visibleHeight
          .drive(onNext: { [weak self] keyboardVisibleHeight in
//            self.view.setNeedsLayout()
              guard let self = self, let scrollView = self.scrollView else { return }
//              scrollView.superview?.setNeedsLayout()
            UIView.animate(withDuration: 0) {
                print("Keyboard height: \(keyboardVisibleHeight)")
                scrollView.contentInset.bottom = keyboardVisibleHeight // + self.messageInputBar.height
                scrollView.scrollIndicatorInsets.bottom = scrollView.contentInset.bottom
//              self.view.layoutIfNeeded()
                print("KeyboardScrollViewManager - scrollView contentInset: \(scrollView.contentInset) contentOffset: \(scrollView.contentOffset)")
//                scrollView.superview?.layoutIfNeeded()
            }
          })
          .disposed(by: self.disposeBag)
        
        
//        RxKeyboard.instance.willShowVisibleHeight
//          .drive(onNext: { [weak self] keyboardVisibleHeight in
//              guard let self = self, let scrollView = self.scrollView else { return }
//              scrollView.contentOffset.y += keyboardVisibleHeight
//          })
//          .disposed(by: self.disposeBag)
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



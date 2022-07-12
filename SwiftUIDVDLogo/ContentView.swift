//
//  ContentView.swift
//  SwiftUIDVDLogo
//
//  Created by Roc Zhang on 7/12/22.
//

import SwiftUI

struct DVDElementPreference: Equatable {
  
  let id: AnyHashable
  
  let size: CGSize
  
}

struct DVDElementPreferenceKey: PreferenceKey {
  
  typealias Value = [DVDElementPreference]
  
  static var defaultValue: [DVDElementPreference] = []
  
  static func reduce(value: inout [DVDElementPreference],
                     nextValue: () -> [DVDElementPreference]) {
    value.append(contentsOf: nextValue())
  }
  
}

struct DVDPreferenceSetter<ID: Hashable>: View {
  
  var id: ID
  
  var body: some View {
    GeometryReader { geometry in
      Color.clear
        .preference(key: DVDElementPreferenceKey.self,
                    value: [DVDElementPreference(id: AnyHashable(self.id),
                                                 size: geometry.size)])
    }
  }
  
}


struct ContentView: View {
  
  final class DisplayLink: ObservableObject {
    
    @Published
    var refreshTrigger = false
    
    private lazy var displayLink: CADisplayLink = {
      let link = CADisplayLink(target: self, selector: #selector(handleDisplayLinkCallback(_:)))
      return link
    }()
    
    @objc private func handleDisplayLinkCallback(_ sender: CADisplayLink) {
      refreshTrigger.toggle()
    }
    
    func startDisplayLink() {
      displayLink.add(to: .main, forMode: .common)
    }
    
    func stopDisplayLink() {
      displayLink.remove(from: .main, forMode: .common)
    }
    
  }
  
  struct ElementInfo {
    
    var position: CGPoint
    
    var objectSize: CGSize
    
    var tintColor: Color
    
    var transform: CGAffineTransform
    
  }
  
  @State
  private var elements: [(id: UUID, view: Image)] = []
  
  @State
  private var speed: CGFloat = 10
  
  @State
  private var elementsInfo: [AnyHashable: ElementInfo] = [:]
  
  @State
  private var containerSize: CGSize = .zero
  
  @ObservedObject
  private var displayLink = DisplayLink()
  
  var body: some View {
    GeometryReader { reader in
      ZStack(alignment: .topLeading) {
        Rectangle()
          .fill(Color.clear)
        
        ForEach(elements, id: \.id) { (id, view) in
          view
            .background(DVDPreferenceSetter(id: id))
            .offset(x: elementsInfo[id]?.position.x ?? 0,
                    y: elementsInfo[id]?.position.y ?? 0)
            .foregroundColor(elementsInfo[id]?.tintColor ?? .blue)
        }
      }
      .onPreferenceChange(DVDElementPreferenceKey.self, perform: { preferences in
        preferences.forEach { preference in
          self.elementsInfo[preference.id, default: ElementInfo(position: .zero, objectSize: preference.size, tintColor: .blue, transform: CGAffineTransform(translationX: speed, y: speed))].objectSize = preference.size
        }
      })
      .onAppear {
        guard containerSize != reader.size else { return }
        containerSize = reader.size
      }
    }
    .background(Color.black)
    .ignoresSafeArea()
    .onAppear {
      displayLink.startDisplayLink()
    }
    .onDisappear {
      displayLink.stopDisplayLink()
    }
    .onTapGesture {
      elements.append((
        UUID(),
        Image("dvd_logo")
          .renderingMode(.template)
      ))
    }
    .onReceive(displayLink.$refreshTrigger) { _ in
      elementsInfo.keys.forEach { key in
        guard var value = elementsInfo[key] else { return }
        
        var transform = value.transform
        let rect = CGRect(origin: value.position, size: value.objectSize)
        
        if rect.maxX >= containerSize.width {
          transform.tx = -speed
          value.tintColor = generateRandomColor()
        }
        
        if rect.maxY >= containerSize.height {
          transform.ty = -speed
          value.tintColor = generateRandomColor()
        }
        
        if rect.minX <= 0 {
          transform.tx = speed
          value.tintColor = generateRandomColor()
        }
        
        if rect.minY <= 0 {
          transform.ty = speed
          value.tintColor = generateRandomColor()
        }
        
        value.transform = transform
        value.position = value.position.applying(transform)
        elementsInfo[key] = value
      }
    }
  }
  
  private func generateRandomColor() -> Color {
    return Color(hue: Double(arc4random() % 256) / 256, saturation: 1, brightness: 1)
  }
  
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

import SwiftUI

fileprivate struct Handle : View {
	private let handleThickness = CGFloat(10.0)
	let backgroundColor: Color?
	var body: some View {
		RoundedRectangle(cornerRadius: handleThickness / 2.0)
			.frame(width: 60, height: handleThickness)
			.foregroundColor(backgroundColor ?? Color.secondary)
			.padding(5)
	}
}

struct SheetView<Content: View> : View {
	@GestureState private var dragState = DragState.inactive
	@State private var cardState = CardState.middle
	@Binding var isPresented: Bool
	let handleColor: Color?
	let backgroundColor: Color?
	private func calcSheetYPosition(in size: CGSize) -> CGFloat {
		cardState.position * size.height + dragState.translation.height
	}
	
	var content: () -> Content
	var body: some View {
		GeometryReader { geometry in
			if isPresented {
				VStack {
					Handle(backgroundColor: handleColor)
					self.content()
				}
				.frame(width: geometry.size.width,
					   height: geometry.size.height - calcSheetYPosition(in: geometry.size))
				.background(backgroundColor ?? .white)
				.cornerRadius(20.0)
				.shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.13), radius: 10.0)
				.offset(y: calcSheetYPosition(in: geometry.size))
				.animation(dragState.isDragging ? nil : .interpolatingSpring(stiffness: 300.0, damping: 30.0))
				.gesture(drag(in: geometry.size))
				.transition(.move(edge: .bottom))
			}
		}
	}
	
	private func drag(in size: CGSize) -> some Gesture {
		DragGesture()
			.updating($dragState) { drag, state, transaction in
				state = .dragging(translation: drag.translation)
			}
			.onEnded { drag in
				let verticalDirection = drag.predictedEndLocation.y - drag.location.y
				let cardTopEdgeLocation = self.cardState.position * size.height + drag.translation.height
				let stateAbove: CardState
				let stateBelow: CardState
				
				if cardTopEdgeLocation <= CardState.middle.position * size.height {
					stateAbove = .top
					stateBelow = .middle
				} else {
					stateAbove = .middle
					stateBelow = .hide
				}
							
				if verticalDirection > 0 {
					self.cardState = stateBelow
				} else if verticalDirection < 0 {
					self.cardState = stateAbove
				}
				if cardState == .hide {
					withAnimation {
						isPresented = false
					}
				}
			}
	}
	
	enum CardState {
		case top
		case middle
		case hide
		
		var position: CGFloat {
			switch self {
				case .top:
					return 0.1
				case .middle, .hide:
					return 0.5
			}
		}
	}
	
	enum DragState {
		case inactive
		case dragging(translation: CGSize)
		
		var translation: CGSize {
			switch self {
				case .inactive:
					return .zero
				case .dragging(let translation):
					return translation
			}
		}
		
		var isDragging: Bool {
			switch self {
				case .inactive:
					return false
				case .dragging:
					return true
			}
		}
	}
}


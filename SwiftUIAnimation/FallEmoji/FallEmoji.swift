import SwiftUI
import SpriteKit
import CoreHaptics
import CoreMotion

class EmojiScene: SKScene, ObservableObject {
	private var hapticEngine: CHHapticEngine?
	private let motionManager = CMMotionManager()
	var dropArea: CGRect = .zero

	override func didMove(to view: SKView) {
		self.backgroundColor = UIColor.white
		physicsBody = SKPhysicsBody(edgeLoopFrom: dropArea)
		physicsWorld.gravity = .zero

		prepareHapticEngine()
		startMotionUpdates()
	}

	func addEmoji(at position: CGPoint, size: CGFloat) {
		let emojis = ["emoji-nerd", "emoji-crazy", "emoji-happy"]
		let texture = SKTexture(imageNamed: emojis.randomElement()!)
		let emoji = SKSpriteNode(texture: texture)
		emoji.name = "emoji"
		emoji.position = position
		emoji.size = CGSize(width: size, height: size)
		emoji.physicsBody = SKPhysicsBody(circleOfRadius: size / 2)
		emoji.physicsBody?.restitution = 0.5
		emoji.physicsBody?.friction = 0.3
		addChild(emoji)
	}

	override func didSimulatePhysics() {
		super.didSimulatePhysics()

		enumerateChildNodes(withName: "emoji") { node, _ in
			if let emoji = node as? SKSpriteNode, let velocity = emoji.physicsBody?.velocity {
				if emoji.position.y < self.dropArea.minY + 50 {
					self.triggerHapticFeedback(with: velocity)
				}
			}
		}
	}

	private func prepareHapticEngine() {
		guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

		do {
			hapticEngine = try CHHapticEngine()
			try hapticEngine?.start()
		} catch {
			print("Haptic engine Creation Error: \(error)")
		}

	}

	private func triggerHapticFeedback(with velocity: CGVector) {
		guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

		let velocityMagnitude = sqrt(velocity.dy * velocity.dy + velocity.dx * velocity.dx)
		let intensity = min(1.0, velocityMagnitude / 500.0)

		// 增强震动反馈，通过多个事件叠加
		let hapticEvents = (0..<5).map { i in
			CHHapticEvent(eventType: .hapticTransient, parameters: [
				CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity)),
				CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(intensity))
			], relativeTime: TimeInterval(i) * 0.1)
		}

		do {
			let hapticPattern = try CHHapticPattern(events: hapticEvents, parameters: [])
			let hapticPlayer = try hapticEngine?.makePlayer(with: hapticPattern)
			try hapticPlayer?.start(atTime: 0)
		} catch {
			print("Haptic Playback Error: \(error)")
		}
	}

	private func startMotionUpdates() {
		MotionService.shared.startAccelerometerUpdates(to: OperationQueue.main) { [weak self] (data: CMAccelerometerData?, error: Error?) in
			guard let data = data else { return }

			let vector = CGVector(dx: data.acceleration.x * 9.8, dy: data.acceleration.y * 9.8)
			self?.physicsWorld.gravity = vector

			let accelerationMagnitude = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
			if accelerationMagnitude > 1.0 {
				self?.triggerHapticFeedback(with: vector)
			}
		}
	}

	func setDropArea(_ rect: CGRect) {
		dropArea = rect
		physicsBody = SKPhysicsBody(edgeLoopFrom: dropArea)
	}

}

struct FallEmoji: View {
	@State private var scene = EmojiScene()
	var dropArea: CGRect

	var body: some View {
		ZStack {
			SpriteView(scene: scene)
				.frame(width: dropArea.width, height: dropArea.height)
				.position(x: dropArea.midX, y: dropArea.midY)
				.clipped()

		}
		.onAppear {
			setupScene()
		}
	}


	private func setupScene() {
		scene.size = dropArea.size
		scene.scaleMode = .resizeFill

		scene.setDropArea(dropArea)

		if let skView = scene.view {
			skView.allowsTransparency = true
		}

		dropEmoji(count: 10)
	}

	func dropEmoji(count: Int) {
		for i in 0..<count {
			DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
				let randomX = CGFloat.random(in: 0...dropArea.width)
				let position = CGPoint(x: randomX, y: dropArea.height - 50)
				scene.addEmoji(at: position, size: 24)
			}
		}
	}
}


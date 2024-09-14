import Foundation
import CoreMotion

class MotionService: ObservableObject {

	static let shared = MotionService()
	private let motionManager = CMMotionManager()

	private init() {}

	func startUpdating(_ update: @escaping (CGVector) -> Void) {
		guard motionManager.isDeviceMotionAvailable else { return }
		motionManager.deviceMotionUpdateInterval = 0.1
		motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
			guard let gravity = motion?.gravity else { return }
			let gravityVector = CGVector(dx: gravity.x * 9.8, dy: gravity.y * 9.8)
			update(gravityVector)
		}
	}


	func startAccelerometerUpdates(to queue: OperationQueue, withHandler handler: @escaping CMAccelerometerHandler) {
		guard motionManager.isDeviceMotionAvailable else { return }
		motionManager.startAccelerometerUpdates(to: queue, withHandler: handler)
	}


	deinit {
		motionManager.stopDeviceMotionUpdates()
	}
}

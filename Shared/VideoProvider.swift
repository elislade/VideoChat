import AVFoundation

class VideoProvider: NSObject {
    
    private let session = AVCaptureMultiCamSession()
    
    lazy var frontLayer:AVCaptureVideoPreviewLayer = {
        let l = AVCaptureVideoPreviewLayer(sessionWithNoConnection: session)
        l.videoGravity = .resizeAspectFill
        return l
    }()
    
    lazy var backLayer:AVCaptureVideoPreviewLayer = {
        let l = AVCaptureVideoPreviewLayer(sessionWithNoConnection: session)
        l.videoGravity = .resizeAspectFill
        return l
    }()
    
    private let discover = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera],
        mediaType: .video,
        position: .unspecified
    )
    
    func setup() {
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { authed in
                if authed { self.setup() }
            })
        } else {
            guard
                let front = discover.devices.first(where: { $0.position == .front })
            else { return }
            
            session.startRunning()
            session.beginConfiguration()
          
            if let input = try? AVCaptureDeviceInput(device: front) {
                if session.canAddInput(input) {
                    session.addInputWithNoConnections(input)
                    if let port = input.ports(for: .video, sourceDeviceType: front.deviceType, sourceDevicePosition: front.position).first {
                        session.addConnection(AVCaptureConnection(inputPort: port, videoPreviewLayer: frontLayer))
                    }
                }
            }
            
            if let back = discover.devices.first(where: {$0.position == .back}) {
                if let input = try? AVCaptureDeviceInput(device: back) {
                    if session.canAddInput(input) {
                        session.addInputWithNoConnections(input)
                        if let port = input.ports(for: .video, sourceDeviceType: back.deviceType, sourceDevicePosition: back.position).first {
                            session.addConnection(AVCaptureConnection(inputPort: port, videoPreviewLayer: backLayer))
                        }
                    }
                }
            }
            
            session.commitConfiguration()
        }
    }
    
}

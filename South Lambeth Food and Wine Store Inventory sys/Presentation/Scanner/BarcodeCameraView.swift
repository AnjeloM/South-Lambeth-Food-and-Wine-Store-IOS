import SwiftUI
import AVFoundation

// MARK: - BarcodeCameraView
// UIViewRepresentable that hosts an AVCaptureSession for live barcode scanning.
// Calls onBarcodeDetected each time a new barcode value is read.
// Calls onPermissionDenied if camera access is not granted.

struct BarcodeCameraView: UIViewRepresentable {

    let isTorchOn: Bool
    let onBarcodeDetected: (String) -> Void
    let onPermissionDenied: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeDetected: onBarcodeDetected, onPermissionDenied: onPermissionDenied)
    }

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        context.coordinator.configure(previewView: view)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        context.coordinator.setTorch(on: isTorchOn)
    }

    static func dismantleUIView(_ uiView: CameraPreviewUIView, coordinator: Coordinator) {
        coordinator.stop()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {

        private let onBarcodeDetected: (String) -> Void
        private let onPermissionDenied: () -> Void

        private var session: AVCaptureSession?
        private var device: AVCaptureDevice?

        init(onBarcodeDetected: @escaping (String) -> Void,
             onPermissionDenied: @escaping () -> Void) {
            self.onBarcodeDetected = onBarcodeDetected
            self.onPermissionDenied = onPermissionDenied
        }

        func configure(previewView: CameraPreviewUIView) {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                startSession(previewView: previewView)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    DispatchQueue.main.async {
                        if granted {
                            self?.startSession(previewView: previewView)
                        } else {
                            self?.onPermissionDenied()
                        }
                    }
                }
            default:
                DispatchQueue.main.async { self.onPermissionDenied() }
            }
        }

        private func startSession(previewView: CameraPreviewUIView) {
            let session = AVCaptureSession()
            self.session = session

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device)
            else { return }

            self.device = device

            let metaOutput = AVCaptureMetadataOutput()

            guard session.canAddInput(input), session.canAddOutput(metaOutput) else { return }
            session.addInput(input)
            session.addOutput(metaOutput)

            // Support all common barcode symbologies
            let supported: [AVMetadataObject.ObjectType] = [
                .ean13, .ean8, .upce, .code128, .code39, .code93,
                .pdf417, .qr, .aztec, .dataMatrix, .itf14
            ]
            metaOutput.metadataObjectTypes = supported.filter {
                metaOutput.availableMetadataObjectTypes.contains($0)
            }

            metaOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

            // Attach preview layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewView.setPreviewLayer(previewLayer)

            // Run on background thread
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }

        func stop() {
            session?.stopRunning()
        }

        func setTorch(on: Bool) {
            guard
                let device,
                device.hasTorch,
                device.isTorchAvailable,
                (try? device.lockForConfiguration()) != nil
            else { return }
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        }

        // MARK: AVCaptureMetadataOutputObjectsDelegate

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard
                let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                let value = obj.stringValue, !value.isEmpty
            else { return }

            onBarcodeDetected(value)
        }
    }
}

// MARK: - CameraPreviewUIView

final class CameraPreviewUIView: UIView {

    private var previewLayer: AVCaptureVideoPreviewLayer?

    func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        self.previewLayer?.removeFromSuperlayer()
        self.previewLayer = layer
        layer.frame = bounds
        self.layer.insertSublayer(layer, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

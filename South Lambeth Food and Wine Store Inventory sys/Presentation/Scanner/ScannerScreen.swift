import SwiftUI

public struct ScannerScreen: View {

    public let state: ScannerUiState
    public let onEvent: (ScannerUiEvent) -> Void

    public init(state: ScannerUiState, onEvent: @escaping (ScannerUiEvent) -> Void) {
        self.state = state
        self.onEvent = onEvent
    }

    private let scanWindowWidth:  CGFloat = 260
    private let scanWindowHeight: CGFloat = 160
    // Both the overlay cutout and the viewfinder use this — one source of truth.
    private let windowYOffset: CGFloat = 0   // 0 = perfectly centred

    public var body: some View {
        // .ignoresSafeArea() on the ZStack means every child shares the same
        // full-screen coordinate space, so the overlay shape and the viewfinder
        // frame always have the same centre.
        ZStack {
            // MARK: Camera / permission fallback
            if state.permissionDenied {
                permissionDeniedView
            } else {
                BarcodeCameraView(
                    isTorchOn: state.isTorchOn,
                    onBarcodeDetected: { onEvent(.barcodeDetected($0)) },
                    onPermissionDenied: { onEvent(.permissionDenied) }
                )
            }

            // MARK: Dark overlay — cutout computed from the shape's own rect,
            // which equals the full screen when the ZStack ignores safe areas.
            ScannerOverlayShape(
                windowSize: CGSize(width: scanWindowWidth, height: scanWindowHeight),
                yOffset: windowYOffset
            )
            .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))

            // MARK: Viewfinder frame + scan line
            // ZStack centres children by default; the offset matches the shape.
            scanWindow
                .offset(y: windowYOffset)

            // MARK: Top controls
            VStack {
                topBar
                Spacer()
            }

            // MARK: Bottom result panel
            VStack {
                Spacer()
                bottomResultPanel
            }
        }
        .ignoresSafeArea()
        .onAppear { onEvent(.onAppear) }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                onEvent(.closeTapped)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }

            Spacer()

            Text("Scan Barcode")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Button {
                onEvent(.torchToggled)
            } label: {
                Image(systemName: state.isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(state.isTorchOn ? Color.yellow : .white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Scan Window

    private var scanWindow: some View {
        ZStack {
            // Corner brackets
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.85), lineWidth: 2)
                .frame(width: scanWindowWidth, height: scanWindowHeight)

            cornerBrackets

            // Animated scan line
            ScanLineView(width: scanWindowWidth - 24, height: scanWindowHeight)
        }
    }

    // Single Canvas sized exactly to the scan window — corners are drawn at
    // absolute pixel coordinates so they always align with the border.
    private var cornerBrackets: some View {
        Canvas { ctx, size in
            let len: CGFloat = 24
            let thick: CGFloat = 3.5
            let w = size.width
            let h = size.height

            var path = Path()

            // Top-left
            path.move(to: CGPoint(x: len, y: 0))
            path.addLine(to: CGPoint(x: 0,   y: 0))
            path.addLine(to: CGPoint(x: 0,   y: len))

            // Top-right
            path.move(to: CGPoint(x: w - len, y: 0))
            path.addLine(to: CGPoint(x: w,    y: 0))
            path.addLine(to: CGPoint(x: w,    y: len))

            // Bottom-left
            path.move(to: CGPoint(x: 0,   y: h - len))
            path.addLine(to: CGPoint(x: 0,   y: h))
            path.addLine(to: CGPoint(x: len, y: h))

            // Bottom-right
            path.move(to: CGPoint(x: w - len, y: h))
            path.addLine(to: CGPoint(x: w,    y: h))
            path.addLine(to: CGPoint(x: w,    y: h - len))

            ctx.stroke(
                path,
                with: .color(Color(hex: 0x00677C)),
                style: StrokeStyle(lineWidth: thick, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: scanWindowWidth, height: scanWindowHeight)
    }

    // MARK: - Bottom Result Panel

    private var bottomResultPanel: some View {
        VStack(spacing: 8) {
            if let code = state.scannedCode {
                HStack(spacing: 10) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: 0x00677C))

                    Text(code)
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            } else {
                Text("Hold barcode inside the frame to scan")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.80))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "camera.slash.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.white.opacity(0.6))
                Text("Camera Access Required")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Please enable camera access in\nSettings to scan barcodes.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(Color(hex: 0x00677C))
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .padding(.top, 8)
            }
            .padding(32)
        }
    }
}

// MARK: - Scanner Overlay Shape (even-odd fill for cutout)

private struct ScannerOverlayShape: Shape {
    let windowSize: CGSize
    let yOffset: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRect(rect)
        let wx = (rect.width  - windowSize.width)  / 2
        let wy = (rect.height - windowSize.height) / 2 + yOffset
        p.addRoundedRect(
            in: CGRect(x: wx, y: wy, width: windowSize.width, height: windowSize.height),
            cornerSize: CGSize(width: 12, height: 12)
        )
        return p
    }
}

// MARK: - Animated Scan Line

private struct ScanLineView: View {
    let width: CGFloat
    let height: CGFloat

    @State private var offset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, Color(hex: 0x00677C).opacity(0.9), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: 2)
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.6)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = height / 2 - 12
                }
            }
    }
}

//
//  QRScannerView.swift
//  cctalk
//
//  SwiftUI wrapper around AVCaptureMetadataOutput for QR detection.
//  Emits a String payload on first successful scan. The parent is responsible
//  for parsing `cctalk://config?baseUrl=...&token=...` and persisting to Keychain.
//
//  Requires: Info.plist → NSCameraUsageDescription.
//

import SwiftUI
import AVFoundation

public struct QRScannerView: View {
    public var onDetect: (String) -> Void
    public var onError: (QRScannerError) -> Void

    public init(
        onDetect: @escaping (String) -> Void,
        onError: @escaping (QRScannerError) -> Void = { _ in }
    ) {
        self.onDetect = onDetect
        self.onError = onError
    }

    @State private var authStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var flashOn = false
    @State private var flashAvailable = false
    @State private var session = AVCaptureSession()
    @State private var didDetect = false

    public var body: some View {
        ZStack {
            Color.ccBgBase.ignoresSafeArea()
            switch authStatus {
            case .authorized:
                cameraLayer
            case .notDetermined:
                permissionPlaceholder(title: "Tillad kamera for at parre",
                                      action: "Tillad",
                                      run: requestAccess)
            default:
                permissionPlaceholder(title: "Kameraadgang er slået fra",
                                      action: "Åbn Indstillinger",
                                      run: openSettings)
            }
        }
        .onAppear {
            if authStatus == .authorized { startSession() }
        }
        .onDisappear {
            stopSession()
        }
    }

    // MARK: - Camera UI

    private var cameraLayer: some View {
        ZStack {
            CameraPreview(session: session)
                .ignoresSafeArea()
            reticle
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if flashAvailable {
                        Button(action: toggleFlash) {
                            Image(systemName: flashOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.ccTextOnAccent)
                                .padding(CCSpacing.md)
                                .background(Color.black.opacity(0.45), in: Circle())
                        }
                        .accessibilityLabel(flashOn ? "Sluk lommelygte" : "Tænd lommelygte")
                        .padding(CCSpacing.lg)
                    }
                }
            }
        }
    }

    private var reticle: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * 0.7
            ZStack {
                RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous)
                    .stroke(Color.ccTextOnAccent.opacity(0.9), lineWidth: 2)
                    .frame(width: side, height: side)
                    .shadow(color: .black.opacity(0.35), radius: 6, y: 1)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
    }

    private func permissionPlaceholder(title: String, action: String, run: @escaping () -> Void) -> some View {
        VStack(spacing: CCSpacing.lg) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Color.ccTextSecondary)
            Text(title)
                .font(CCFont.titleSection)
                .foregroundStyle(Color.ccTextPrimary)
                .multilineTextAlignment(.center)
            Button(action: run) {
                Text(action)
                    .font(CCFont.bodyEmphasis)
                    .foregroundStyle(Color.ccTextOnAccent)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.ccAccent, in: RoundedRectangle(cornerRadius: CCRadius.md))
            }
            .buttonStyle(.plain)
        }
        .padding(CCSpacing.xl)
    }

    // MARK: - Actions

    private func requestAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                authStatus = AVCaptureDevice.authorizationStatus(for: .video)
                if granted { startSession() }
            }
        }
    }

    private func openSettings() {
#if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
#endif
    }

    private func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            if device.torchMode == .on {
                device.torchMode = .off
                flashOn = false
            } else {
                try device.setTorchModeOn(level: 1.0)
                flashOn = true
            }
        } catch {
            onError(.torch(error.localizedDescription))
        }
    }

    // MARK: - Session lifecycle

    private func startSession() {
        guard !session.isRunning else { return }
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        guard
            let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            onError(.cameraUnavailable)
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            onError(.cameraUnavailable)
            session.commitConfiguration()
            return
        }
        session.addOutput(output)

        let delegate = MetadataDelegate { payload in
            guard !didDetect else { return }
            didDetect = true
            Haptics.success()
            onDetect(payload)
        }
        // Retain via AssociatedObjects so delegate lives as long as the output.
        objc_setAssociatedObject(output, &MetadataDelegate.key, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        output.setMetadataObjectsDelegate(delegate, queue: .main)
        output.metadataObjectTypes = [.qr]

        session.commitConfiguration()
        flashAvailable = device.hasTorch

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func stopSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            session.stopRunning()
        }
    }
}

// MARK: - Errors

public enum QRScannerError: Error, Equatable {
    case cameraUnavailable
    case torch(String)
}

// MARK: - AVCaptureVideoPreviewLayer bridge

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let v = PreviewUIView()
        v.videoPreviewLayer.session = session
        v.videoPreviewLayer.videoGravity = .resizeAspectFill
        return v
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - Metadata delegate

private final class MetadataDelegate: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    static var key: UInt8 = 0
    let onDetect: (String) -> Void
    init(onDetect: @escaping (String) -> Void) { self.onDetect = onDetect }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        for obj in metadataObjects {
            guard
                let qr = obj as? AVMetadataMachineReadableCodeObject,
                qr.type == .qr,
                let payload = qr.stringValue
            else { continue }
            onDetect(payload)
            return
        }
    }
}

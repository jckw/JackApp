//
//  PrivateCameraView.swift
//  JackApp
//
//  Created by Jack on 18/01/2026.
//

import AVFoundation
import SwiftUI
import UIKit

struct PrivateCameraView: View {
    @Environment(\.dismiss) private var dismiss
    let referenceImage: UIImage?
    let onCapture: (UIImage) -> Void

    @State private var cameraManager = CameraManager()
    @State private var capturedImage: UIImage?
    @State private var showingPreview = false
    @State private var flashEnabled = false
    @State private var overlayOpacity: Double = 0.3
    @State private var showOverlay = true
    @State private var timerSeconds: Int = 0
    @State private var countdownRemaining: Int?
    @State private var countdownTimer: Timer?

    private let timerOptions = [0, 3, 5, 10]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if showingPreview, let image = capturedImage {
                previewView(image: image)
            } else {
                cameraView
            }
        }
        .task {
            await cameraManager.requestPermission()
            if cameraManager.isAuthorized {
                await cameraManager.startSession()
            }
        }
        .onDisappear {
            cancelTimer()
            Task {
                await cameraManager.stopSession()
            }
        }
    }

    private var cameraView: some View {
        ZStack {
            CameraPreviewView(session: cameraManager.session)
                .ignoresSafeArea()

            // Ghost overlay of reference image
            if showOverlay, let referenceImage {
                Image(uiImage: referenceImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(overlayOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Countdown display
            if let countdown = countdownRemaining {
                Text("\(countdown)")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 10)
            }

            VStack {
                HStack {
                    Button {
                        cancelTimer()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.black.opacity(0.5), in: Circle())
                    }

                    Spacer()

                    // Timer button
                    Button {
                        cycleTimer()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                            if timerSeconds > 0 {
                                Text("\(timerSeconds)s")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                        .font(.title2)
                        .foregroundStyle(timerSeconds > 0 ? .yellow : .white)
                        .padding()
                        .background(.black.opacity(0.5), in: Capsule())
                    }

                    Button {
                        flashEnabled.toggle()
                    } label: {
                        Image(systemName: flashEnabled ? "bolt.fill" : "bolt.slash.fill")
                            .font(.title2)
                            .foregroundStyle(flashEnabled ? .yellow : .white)
                            .padding()
                            .background(.black.opacity(0.5), in: Circle())
                    }

                    Button {
                        Task {
                            await cameraManager.switchCamera()
                        }
                    } label: {
                        Image(systemName: "camera.rotate")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.black.opacity(0.5), in: Circle())
                    }
                }
                .padding()

                Spacer()

                if !cameraManager.isAuthorized {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text("Camera access required")
                            .font(.headline)
                        Text("Enable camera access in Settings to take progress photos.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }

                Spacer()

                // Overlay controls (only show if we have a reference image)
                if referenceImage != nil {
                    HStack(spacing: 16) {
                        Button {
                            showOverlay.toggle()
                        } label: {
                            Image(systemName: showOverlay ? "eye.fill" : "eye.slash.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(.black.opacity(0.5), in: Circle())
                        }

                        if showOverlay {
                            Slider(value: $overlayOpacity, in: 0.1...0.7)
                                .tint(.white)
                                .frame(width: 150)
                        }
                    }
                    .padding(.bottom, 16)
                }

                HStack {
                    Spacer()

                    Button {
                        if countdownRemaining != nil {
                            cancelTimer()
                        } else if timerSeconds > 0 {
                            startTimer()
                        } else {
                            capturePhoto()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(.white, lineWidth: 4)
                                .frame(width: 70, height: 70)

                            if countdownRemaining != nil {
                                // Show cancel X during countdown
                                Image(systemName: "xmark")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            } else {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 58, height: 58)
                            }
                        }
                    }
                    .disabled(!cameraManager.isAuthorized)

                    Spacer()
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func cycleTimer() {
        if let currentIndex = timerOptions.firstIndex(of: timerSeconds) {
            let nextIndex = (currentIndex + 1) % timerOptions.count
            timerSeconds = timerOptions[nextIndex]
        }
    }

    private func startTimer() {
        countdownRemaining = timerSeconds
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let remaining = countdownRemaining {
                if remaining > 1 {
                    countdownRemaining = remaining - 1
                } else {
                    cancelTimer()
                    capturePhoto()
                }
            }
        }
    }

    private func cancelTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdownRemaining = nil
    }

    private func capturePhoto() {
        Task {
            if let image = await cameraManager.capturePhoto(flash: flashEnabled) {
                capturedImage = image
                showingPreview = true
            }
        }
    }

    private func previewView(image: UIImage) -> some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        showingPreview = false
                        capturedImage = nil
                    } label: {
                        Label("Retake", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.black.opacity(0.6), in: Capsule())
                    }

                    Spacer()

                    Button {
                        onCapture(image)
                        dismiss()
                    } label: {
                        Label("Use Photo", systemImage: "checkmark")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.white, in: Capsule())
                    }
                }
                .padding()

                Spacer()
            }
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }
}

class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@Observable
class CameraManager: NSObject {
    let session = AVCaptureSession()
    var isAuthorized = false
    private var photoOutput = AVCapturePhotoOutput()
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private var photoContinuation: CheckedContinuation<UIImage?, Never>?

    func requestPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        default:
            isAuthorized = false
        }
    }

    func startSession() async {
        guard isAuthorized else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        session.commitConfiguration()

        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
                continuation.resume()
            }
        }
    }

    func stopSession() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
                continuation.resume()
            }
        }
    }

    func switchCamera() async {
        currentCameraPosition = currentCameraPosition == .back ? .front : .back

        session.beginConfiguration()

        session.inputs.forEach { session.removeInput($0) }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        session.commitConfiguration()
    }

    func capturePhoto(flash: Bool) async -> UIImage? {
        await withCheckedContinuation { continuation in
            self.photoContinuation = continuation

            let settings = AVCapturePhotoSettings()
            settings.flashMode = flash ? .on : .off

            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            photoContinuation?.resume(returning: nil)
            photoContinuation = nil
            return
        }

        let fixedImage = fixOrientation(image)
        photoContinuation?.resume(returning: fixedImage)
        photoContinuation = nil
    }

    private func fixOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? image
    }
}

#Preview {
    PrivateCameraView(referenceImage: nil) { _ in }
}

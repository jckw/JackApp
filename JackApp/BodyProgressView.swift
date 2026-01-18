//
//  BodyProgressView.swift
//  JackApp
//
//  Created by Jack on 18/01/2026.
//

import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct BodyProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \BodyPhoto.timestamp, order: .reverse) private var photos: [BodyPhoto]

    @State private var authManager = BiometricAuthManager()
    @State private var showingCamera = false
    @State private var selectedPhoto: BodyPhoto?
    @State private var showingDeleteConfirmation = false
    @State private var photoToDelete: BodyPhoto?
    @State private var selectedPhotoItem: PhotosPickerItem?

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if authManager.isAuthenticated {
                    authenticatedView
                } else {
                    lockedView
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }

                if authManager.isAuthenticated {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            authManager.lock()
                        } label: {
                            Image(systemName: "lock.fill")
                        }
                    }
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                authManager.lock()
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            PrivateCameraView(referenceImage: photos.first?.uiImage) { image in
                savePhoto(image)
            }
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo) {
                photoToDelete = photo
                showingDeleteConfirmation = true
            }
        }
        .confirmationDialog(
            "Delete Photo",
            isPresented: $showingDeleteConfirmation,
            presenting: photoToDelete
        ) { photo in
            Button("Delete", role: .destructive) {
                deletePhoto(photo)
            }
        } message: { _ in
            Text("This photo will be permanently deleted.")
        }
    }

    private var lockedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: authManager.biometricIcon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Progress Photos Locked")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Use \(authManager.biometricName) to view your photos")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let error = authManager.authError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Button {
                Task {
                    await authManager.authenticate()
                }
            } label: {
                Label("Unlock with \(authManager.biometricName)", systemImage: authManager.biometricIcon)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }

    private var authenticatedView: some View {
        Group {
            if photos.isEmpty {
                emptyStateView
            } else {
                photoGridView
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Library", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.secondary.opacity(0.2))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showingCamera = true
                } label: {
                    Label("Camera", systemImage: "camera.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    savePhoto(uiImage)
                }
                selectedPhotoItem = nil
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Progress Photos")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Take your first photo to start tracking your progress.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    private var photoGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(photos) { photo in
                    photoThumbnail(photo)
                }
            }
        }
    }

    private func photoThumbnail(_ photo: BodyPhoto) -> some View {
        Button {
            selectedPhoto = photo
        } label: {
            Group {
                if let image = photo.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(.secondary.opacity(0.2))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(minHeight: 120)
            .clipped()
        }
        .contextMenu {
            Button(role: .destructive) {
                photoToDelete = photo
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func savePhoto(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        let photo = BodyPhoto(imageData: data)
        modelContext.insert(photo)
    }

    private func deletePhoto(_ photo: BodyPhoto) {
        selectedPhoto = nil
        modelContext.delete(photo)
    }
}

struct PhotoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let photo: BodyPhoto
    let onDelete: () -> Void

    @State private var showingInfo = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let image = photo.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.black.opacity(0.5), in: Circle())
                    }
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(photo.formattedDate)
                            .font(.headline)
                        Text(photo.formattedTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.white)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onDelete()
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                            .padding(8)
                            .background(.black.opacity(0.5), in: Circle())
                    }
                }
            }
        }
    }
}

#Preview {
    BodyProgressView()
        .modelContainer(for: BodyPhoto.self, inMemory: true)
}

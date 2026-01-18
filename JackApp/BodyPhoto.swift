//
//  BodyPhoto.swift
//  JackApp
//
//  Created by Jack on 18/01/2026.
//

import SwiftData
import SwiftUI

@Model
final class BodyPhoto {
    var id: UUID
    var timestamp: Date
    var note: String?

    @Attribute(.externalStorage)
    var imageData: Data?

    init(imageData: Data, timestamp: Date = Date(), note: String? = nil) {
        self.id = UUID()
        self.imageData = imageData
        self.timestamp = timestamp
        self.note = note
    }

    var image: Image? {
        guard let data = imageData, let uiImage = UIImage(data: data) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }

    var uiImage: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }

    var formattedDate: String {
        timestamp.formatted(date: .abbreviated, time: .omitted)
    }

    var formattedTime: String {
        timestamp.formatted(date: .omitted, time: .shortened)
    }
}

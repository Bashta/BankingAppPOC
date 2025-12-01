//
//  ActivityViewController.swift
//  BankingApp
//
//  UIViewControllerRepresentable wrapper for UIActivityViewController
//  to enable share sheet functionality on iOS 15+.
//

import SwiftUI
import UIKit

/// A SwiftUI wrapper for UIActivityViewController to enable sharing functionality.
/// Used for sharing statement download URLs and other shareable content.
struct ActivityViewController: UIViewControllerRepresentable {
    /// Items to share (URLs, strings, images, etc.)
    let activityItems: [Any]

    /// Optional application activities to include
    let applicationActivities: [UIActivity]?

    /// Optional excluded activity types
    let excludedActivityTypes: [UIActivity.ActivityType]?

    /// Completion handler called when the activity view controller is dismissed
    var completionHandler: ((UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void)?

    init(
        activityItems: [Any],
        applicationActivities: [UIActivity]? = nil,
        excludedActivityTypes: [UIActivity.ActivityType]? = nil,
        completionHandler: ((UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void)? = nil
    ) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        self.excludedActivityTypes = excludedActivityTypes
        self.completionHandler = completionHandler
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )

        if let excludedActivityTypes = excludedActivityTypes {
            controller.excludedActivityTypes = excludedActivityTypes
        }

        controller.completionWithItemsHandler = completionHandler

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

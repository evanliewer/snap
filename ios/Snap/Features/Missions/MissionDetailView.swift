import SwiftUI
import PhotosUI
import CoreLocation

struct MissionDetailView: View {
    let mission: APIMission
    var onSubmitted: (APIMission) -> Void = { _ in }

    @State private var selectedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var showCamera = false
    @State private var caption: String = ""
    @State private var submitting = false
    @State private var error: String?
    @State private var success = false
    @StateObject private var locationStore = LocationStore()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if let desc = mission.description, !desc.isEmpty {
                    Text(desc).font(.body).foregroundStyle(.secondary)
                }

                if mission.completedByTeam && !mission.repeatable {
                    Label("Your team already submitted this mission.", systemImage: "checkmark.seal.fill")
                        .padding(12)
                        .background(.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                }

                photoArea

                TextField("Add a caption (optional)", text: $caption, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)

                if mission.requiresLocation {
                    LocationCard(locationStore: locationStore)
                }

                if let error { Text(error).foregroundStyle(.red).font(.footnote) }
                if success {
                    Label("Submitted! Nice work.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        if submitting { ProgressView().tint(.white) }
                        Text(submitting ? "Submitting…" : "Submit").bold()
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(pickedImage == nil || submitting || (mission.requiresLocation && locationStore.location == nil))
            }
            .padding()
        }
        .navigationTitle(mission.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCamera) {
            CameraCaptureView { image in
                pickedImage = image
            }
            .ignoresSafeArea()
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    pickedImage = image
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let color = mission.categoryColor {
                Circle().fill(Color(hex: color)).frame(width: 14, height: 14)
            }
            VStack(alignment: .leading, spacing: 2) {
                if let cat = mission.categoryName { Text(cat).font(.caption).foregroundStyle(.secondary) }
                Text("\(mission.points) pts").font(.subheadline.bold()).foregroundStyle(.orange)
            }
            Spacer()
            Text(mission.missionType.uppercased())
                .font(.caption2.bold())
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(.thinMaterial, in: Capsule())
        }
    }

    private var photoArea: some View {
        VStack(spacing: 12) {
            if let pickedImage {
                Image(uiImage: pickedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 240)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill").font(.system(size: 36)).foregroundStyle(.secondary)
                            Text("Add a photo to submit").foregroundStyle(.secondary)
                        }
                    }
            }
            HStack(spacing: 12) {
                Button { showCamera = true } label: {
                    Label("Camera", systemImage: "camera").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Library", systemImage: "photo").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func submit() async {
        guard let pickedImage else { return }
        submitting = true
        error = nil
        success = false
        do {
            _ = try await APIClient.shared.submitPhoto(
                missionId: mission.id,
                image: pickedImage,
                caption: caption,
                latitude: locationStore.location?.coordinate.latitude,
                longitude: locationStore.location?.coordinate.longitude
            )
            success = true
            self.pickedImage = nil
            self.caption = ""
            var updated = mission
            updated = APIMission(
                id: mission.id, gameId: mission.gameId, categoryId: mission.categoryId,
                categoryName: mission.categoryName, categoryColor: mission.categoryColor,
                title: mission.title, description: mission.description, points: mission.points,
                bonusPoints: mission.bonusPoints, missionType: mission.missionType,
                position: mission.position, required: mission.required, repeatable: mission.repeatable,
                maxSubmissionsPerTeam: mission.maxSubmissionsPerTeam, requiresLocation: mission.requiresLocation,
                completedByTeam: true, teamSubmissionCount: mission.teamSubmissionCount + 1
            )
            onSubmitted(updated)
        } catch {
            self.error = error.userMessage
        }
        submitting = false
    }
}

struct LocationCard: View {
    @ObservedObject var locationStore: LocationStore
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Location required", systemImage: "location.fill").font(.subheadline.bold())
            if let loc = locationStore.location {
                Text(String(format: "%.4f, %.4f", loc.coordinate.latitude, loc.coordinate.longitude))
                    .font(.caption.monospaced())
            } else {
                Text(locationStore.statusText).font(.caption).foregroundStyle(.secondary)
                Button("Use my current location") { locationStore.request() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(12)
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

@MainActor
final class LocationStore: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var statusText: String = "Tap below to share your location."
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .denied, .restricted: statusText = "Location is disabled in Settings."
        default: manager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        Task { @MainActor in self.location = last }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.statusText = "Couldn't get your location: \(error.localizedDescription)" }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
}

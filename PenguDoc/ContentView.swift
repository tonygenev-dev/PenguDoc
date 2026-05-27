import SwiftUI
import Combine

// MARK: - Helper for Dummy Images
extension UIImage {
    static func placeholder(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 300)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}

// MARK: - Data Models
struct ScannedDoc: Identifiable {
    let id = UUID()
    var title: String
    var image: UIImage
    var isPinned: Bool
}

class DocumentStore: ObservableObject {
    @Published var documents: [ScannedDoc] = []
    
    init() {
        documents = [
            ScannedDoc(title: "GLOW Sprint Plan", image: UIImage.placeholder(color: .systemBlue), isPinned: true),
            ScannedDoc(title: "Meeting Notes - Jordi", image: UIImage.placeholder(color: .systemTeal), isPinned: true),
            ScannedDoc(title: "Ultrasonic Sensor Specs", image: UIImage.placeholder(color: .systemGray), isPinned: false),
            ScannedDoc(title: "Finland Trip Tickets", image: UIImage.placeholder(color: .systemIndigo), isPinned: false)
        ]
    }
    
    func togglePin(for doc: ScannedDoc) {
        if let index = documents.firstIndex(where: { $0.id == doc.id }) {
            documents[index].isPinned.toggle()
        }
    }
    
    func delete(doc: ScannedDoc) {
        documents.removeAll { $0.id == doc.id }
    }
}

// MARK: - Main Router
struct ContentView: View {
    @AppStorage("hasSeenTutorial") var hasSeenTutorial: Bool = false
    @StateObject var documentStore = DocumentStore()

    var body: some View {
        Group {
            if hasSeenTutorial {
                MainTabContainerView()
                    .environmentObject(documentStore)
            } else {
                TutorialView()
            }
        }
    }
}

// MARK: - Main Tab Container
struct MainTabContainerView: View {
    @State private var selectedTab: Int = 1
    @EnvironmentObject var documentStore: DocumentStore

    var body: some View {
        ZStack {
            Color(red: 0.65, green: 0.6, blue: 0.95).ignoresSafeArea()
            
            VStack {
                switch selectedTab {
                case 0:
                    CleanAndScanView(selectedTab: $selectedTab)
                case 1:
                    HomeView()
                case 2:
                    DocumentPageView()
                default:
                    HomeView()
                }
            }
            
            VStack {
                Spacer()
                GlassBottomNav(selectedTab: $selectedTab)
            }
        }
    }
}

// MARK: - Screen 1: Clean and Scan Page (Camera)
struct CleanAndScanView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var documentStore: DocumentStore
    
    @State private var isShowingCamera = true
    @State private var capturedImage: UIImage?
    @State private var documentName: String = ""
    @State private var isPinned: Bool = false
    
    var body: some View {
        VStack {
            if let image = capturedImage {
                VStack(spacing: 20) {
                    Text("Save Document")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    VStack(spacing: -15) {
                        Image("penguin_up")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .zIndex(1)
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                    
                    TextField("Enter document name...", text: $documentName)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    
                    Toggle("Pin to Top", isOn: $isPinned)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    
                    HStack(spacing: 40) {
                        Button(action: {
                            capturedImage = nil
                            isShowingCamera = true
                        }) {
                            Image(systemName: "arrow.uturn.left")
                                .font(.title).bold()
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.red.opacity(0.8))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            let newDoc = ScannedDoc(title: documentName.isEmpty ? "Untitled" : documentName, image: image, isPinned: isPinned)
                            documentStore.documents.append(newDoc)
                            
                            capturedImage = nil
                            documentName = ""
                            isPinned = false
                            selectedTab = 2
                        }) {
                            Image(systemName: "checkmark")
                                .font(.title).bold()
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.green.opacity(0.8))
                                .clipShape(Circle())
                        }
                    }
                    Spacer()
                }
            } else {
                VStack {
                    Text("Opening Camera...")
                        .foregroundColor(.white)
                        .padding()
                    Button("Tap to Open Camera Again") {
                        isShowingCamera = true
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            ImagePicker(image: $capturedImage)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Screen 2: Home Page
struct HomeView: View {
    @AppStorage("hasSeenTutorial") var hasSeenTutorial: Bool = true
    @State private var paperHeightCm: Double = 2.0
    
    var currentState: PileState {
        if paperHeightCm <= 2.0 { return .low }
        else if paperHeightCm <= 5.0 { return .medium }
        else if paperHeightCm <= 10.0 { return .high }
        else { return .critical }
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    withAnimation { hasSeenTutorial = false }
                }) {
                    Text("Tutorial ✪")
                        .font(.subheadline).bold()
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.15))
                        .cornerRadius(20)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    HStack(spacing: 4) {
                        ForEach(0..<4, id: \.self) { index in
                            Image(systemName: index < currentState.hearts ? "heart.fill" : "heart")
                                .foregroundColor(.pink)
                                .font(.body)
                        }
                    }
                    Text("Happiness").font(.system(size: 10)).bold().foregroundColor(.black.opacity(0.5))
                }
            }
            .padding()
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(currentState.messages, id: \.self) { message in
                    Text(message)
                        .font(.footnote).bold()
                        .foregroundColor(.purple)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(16)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 40)
            
            Image(currentState.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 280)
                .padding(.vertical, 20)
            
            Spacer()
            
            VStack {
                HStack {
                    Image(systemName: "tortoise.fill").foregroundColor(.black.opacity(0.3))
                    Slider(value: $paperHeightCm, in: 0...15).tint(.white)
                    Image(systemName: "hare.fill").foregroundColor(.black.opacity(0.3))
                }
                Text(String(format: "Sensor Document Height: %.1f cm", paperHeightCm))
                    .font(.caption).bold().foregroundColor(.white)
            }
            .padding(.horizontal, 30)
            
            Spacer().frame(height: 100)
        }
    }
}

// MARK: - Screen 3: Document Page
struct DocumentPageView: View {
    @EnvironmentObject var documentStore: DocumentStore
    @State private var selectedDoc: ScannedDoc? = nil
    
    var pinnedDocs: [ScannedDoc] {
        documentStore.documents.filter { $0.isPinned }
    }
    var regularDocs: [ScannedDoc] {
        documentStore.documents.filter { !$0.isPinned }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(.black)
                    Spacer()
                    
                    Image("penguin_gentleman")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                    
                    Text("Look how organized you are!")
                        .font(.caption).bold()
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                if !pinnedDocs.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Pinned Documents")
                            .font(.headline).foregroundColor(.black)
                            .padding(.leading)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(pinnedDocs) { doc in
                                    DocumentCard(doc: doc)
                                        .onTapGesture { selectedDoc = doc }
                                        .contextMenu {
                                            Button(action: { documentStore.togglePin(for: doc) }) {
                                                Label("Unpin", systemImage: "pin.slash")
                                            }
                                            Button(role: .destructive, action: { documentStore.delete(doc: doc) }) {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Documents")
                        .font(.headline).foregroundColor(.black)
                        .padding(.leading)
                    
                    if regularDocs.isEmpty {
                        Text("No regular documents yet!")
                            .foregroundColor(.white)
                            .padding(.leading)
                    } else {
                        ForEach(regularDocs) { doc in
                            DocumentRow(doc: doc)
                                .onTapGesture { selectedDoc = doc }
                                .contextMenu {
                                    Button(action: { documentStore.togglePin(for: doc) }) {
                                        Label("Pin to Top", systemImage: "pin")
                                    }
                                    Button(role: .destructive, action: { documentStore.delete(doc: doc) }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                
                Spacer().frame(height: 100)
            }
            .padding(.top)
        }
        .sheet(item: $selectedDoc) { doc in
            DocumentDetailPopup(doc: doc)
                .environmentObject(documentStore)
        }
    }
}

// MARK: - Document Detail Popup
struct DocumentDetailPopup: View {
    let doc: ScannedDoc
    @EnvironmentObject var documentStore: DocumentStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Image(uiImage: doc.image)
                    .resizable()
                    .scaledToFit()
                    .padding()
                Spacer()
            }
            .navigationTitle(doc.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            documentStore.togglePin(for: doc)
                            dismiss()
                        }) {
                            Image(systemName: doc.isPinned ? "pin.slash.fill" : "pin.fill")
                        }
                        
                        Button(action: {
                            documentStore.delete(doc: doc)
                            dismiss()
                        }) {
                            Image(systemName: "trash.fill").foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting UI Components
struct DocumentCard: View {
    let doc: ScannedDoc
    var body: some View {
        VStack(alignment: .leading) {
            Image(uiImage: doc.image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Spacer()
            Text(doc.title)
                .font(.subheadline).bold()
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding()
        .frame(width: 140, height: 130)
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
    }
}

struct DocumentRow: View {
    let doc: ScannedDoc
    var body: some View {
        HStack {
            Image(uiImage: doc.image)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(doc.title)
                    .font(.subheadline).bold()
            }
            .padding(.leading, 8)
            
            Spacer()
            
            Text(doc.isPinned ? "Pinned" : "Document")
                .font(.system(size: 8)).bold()
                .foregroundColor(.white)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(doc.isPinned ? Color.blue : Color.gray)
                .cornerRadius(4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Camera Logic (Helper)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        #if targetEnvironment(simulator)
        picker.sourceType = .photoLibrary
        #else
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        #endif
        
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Custom Working Glass Navigation Bar
struct GlassBottomNav: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            Spacer()
            NavIcon(iconName: "camera.viewfinder", isActive: selectedTab == 0)
                .onTapGesture { selectedTab = 0 }
            Spacer()
            NavIcon(iconName: "house.fill", isActive: selectedTab == 1)
                .onTapGesture { selectedTab = 1 }
            Spacer()
            NavIcon(iconName: "chart.bar.doc.horizontal", isActive: selectedTab == 2)
                .onTapGesture { selectedTab = 2 }
            Spacer()
        }
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .white.opacity(0.2), radius: 8, x: 0, y: 0)
        )
        .padding(.horizontal, 30)
        .padding(.bottom, 10)
    }
}

struct NavIcon: View {
    let iconName: String
    let isActive: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isActive ? Color.white.opacity(0.4) : Color.white.opacity(0.1))
                .frame(width: 46, height: 46)
                .shadow(color: isActive ? .white : .clear, radius: 10)
            
            Image(systemName: iconName)
                .font(.system(size: 18))
                .foregroundColor(isActive ? .white : .white.opacity(0.6))
        }
    }
}

// MARK: - Tutorial Pages
struct TutorialView: View {
    @AppStorage("hasSeenTutorial") var hasSeenTutorial: Bool = false
    var body: some View {
        TabView {
            TutorialPage(title: "Welcome!", description: "Meet your friendly assistant who will help you organize your documents! If your documents pile up I won't be happy.", imageName: "penguin_happy")
            
            // Scaled up angry penguin passing in the flag to show the floating icon
            TutorialPage(title: "The Problem", description: "As documents accumulate, it gets harder to keep track of everything. Use the scan feature to digitize your documents.", imageName: "penguin_angry", showScanIcon: true, imageSize: 360)
            
            VStack {
                TutorialPage(title: "Stay Organized", description: "All your documents are now neatly organized and easily accessible.", imageName: "penguin_gentleman")
                
                Button(action: {
                    withAnimation { hasSeenTutorial = true }
                }) {
                    HStack {
                        Text("Start").font(.subheadline).bold()
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(Color.white).cornerRadius(20).shadow(radius: 4)
                }
                .padding(.bottom, 60)
            }
        }
        .tabViewStyle(.page)
        .background(Color(red: 0.65, green: 0.6, blue: 0.95).ignoresSafeArea())
    }
}

struct TutorialPage: View {
    let title: String
    let description: String
    let imageName: String
    
    // Configurable layout properties for specific pages
    var showScanIcon: Bool = false
    var imageSize: CGFloat = 280
    
    var body: some View {
        VStack {
            Text("Tutorial")
                .font(.title3).bold().foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Color.black.opacity(0.3)).cornerRadius(16).padding()
            Spacer()
            
            // Horizontal stack places the icon perfectly at the end of the stick
            HStack(alignment: .center, spacing: 10) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: imageSize) // Controlled by the parameter above
                
                if showScanIcon {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial) // Liquid Glass look
                            .frame(width: 70, height: 70)
                            .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 0)
                        
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    // Adjusted coordinates to map precisely to the tip of the stick
                    .offset(x: -30, y: -50)
                }
            }
            
            Spacer()
            VStack(spacing: 12) {
                Text(title).font(.title3).bold().foregroundColor(Color(red: 0.65, green: 0.6, blue: 0.95))
                Text(description).font(.footnote).multilineTextAlignment(.center).foregroundColor(.purple).padding(.horizontal)
            }
            .padding().frame(maxWidth: .infinity, minHeight: 180).background(Color.white).cornerRadius(24).padding()
            Spacer()
        }
    }
}

// MARK: - State Logic Settings
enum PileState {
    case low, medium, high, critical
    
    var hearts: Int {
        switch self {
        case .low: return 4
        case .medium: return 3
        case .high: return 2
        case .critical: return 0
        }
    }
    
    var messages: [String] {
        switch self {
        case .low: return ["Hey there! You are doing amazing!"]
        case .medium: return ["The paper is starting to pile up"]
        case .high: return ["The paper is starting to pile up", "It is too much now"]
        case .critical: return ["The paper is starting to pile up", "It is too much now", "SCAN PLEASE.."]
        }
    }
    
    var imageName: String {
        switch self {
        case .low: return "penguin_happy"
        case .medium: return "penguin_pile"
        case .high: return "penguin_sad"
        case .critical: return "penguin_drowning"
        }
    }
}

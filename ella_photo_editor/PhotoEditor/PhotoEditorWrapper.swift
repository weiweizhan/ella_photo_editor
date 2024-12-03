import SwiftUI

struct PhotoEditorWrapper: UIViewControllerRepresentable {
    let image: UIImage
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = PhotoEditorViewController()
        controller.setImage(image)
        controller.onDismiss = {
            presentationMode.wrappedValue.dismiss()
        }
        
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.backgroundColor = .systemBackground
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    typealias UIViewControllerType = UINavigationController
}

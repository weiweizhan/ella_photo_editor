//
//  ContentView.swift
//  ella_photo_editor
//
//  Created by Zhan Wei wei on 2024/12/3.
//

import SwiftUI
import PhotosUI
import UIKit

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showingEditor = false
    @State private var isShowingPhotoPicker = false
    
    var body: some View {
        NavigationView {
            VStack {
                if selectedImage == nil {
                    Text("选择一张照片开始编辑")
                        .padding()
                }
                
                PhotosPicker(selection: $selectedItem,
                           matching: .images,
                           photoLibrary: .shared()) {
                    Label("选择照片", systemImage: "photo.on.rectangle.angled")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("滤镜编辑器")
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        showingEditor = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showingEditor, content: {
                if let image = selectedImage {
                    PhotoEditorWrapper(image: image)
                }
            })
            .sheet(isPresented: $isShowingPhotoPicker) {
                ImagePicker(selectedImage: $selectedImage, isPresented: $isShowingPhotoPicker)
                    .ignoresSafeArea()
                    .onDisappear {
                        if selectedImage != nil {
                            showingEditor = true
                        }
                    }
            }
        }
        .onAppear {
            isShowingPhotoPicker = true
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

#Preview {
    ContentView()
}

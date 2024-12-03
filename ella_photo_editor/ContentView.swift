//
//  ContentView.swift
//  ella_photo_editor
//
//  Created by Zhan Wei wei on 2024/12/3.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showingEditor = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .padding()
                    
                    Button("编辑照片") {
                        showingEditor = true
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                } else {
                    Text("选择一张照片开始编辑")
                        .padding()
                }
                
                PhotosPicker(selection: $selectedItem,
                           matching: .images) {
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
                    }
                }
            }
            .fullScreenCover(isPresented: $showingEditor, content: {
                if let image = selectedImage {
                    PhotoEditorWrapper(image: image)
                }
            })
        }
    }
}

#Preview {
    ContentView()
}

import UIKit

class EditHistoryManager {
    private var history: [(image: UIImage, filterName: String)] = []
    private var currentIndex: Int = -1
    
    var canUndo: Bool {
        return currentIndex > 0
    }
    
    var canRedo: Bool {
        return currentIndex < history.count - 1
    }
    
    func addEdit(image: UIImage, filterName: String) {
        // Remove any redo history when new edit is added
        if currentIndex < history.count - 1 {
            history.removeSubrange((currentIndex + 1)...)
        }
        
        history.append((image, filterName))
        currentIndex = history.count - 1
    }
    
    func undo() -> (UIImage, String)? {
        guard canUndo else { return nil }
        currentIndex -= 1
        return history[currentIndex]
    }
    
    func redo() -> (UIImage, String)? {
        guard canRedo else { return nil }
        currentIndex += 1
        return history[currentIndex]
    }
    
    func reset(with image: UIImage) {
        history = [(image, "")]
        currentIndex = 0
    }
}

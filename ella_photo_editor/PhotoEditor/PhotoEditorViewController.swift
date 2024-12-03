import UIKit
import CoreImage
import Photos

class PhotoEditorViewController: UIViewController {
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let filterCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 85, height: 110)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let adjustmentControls: AdjustmentControlsView = {
        let view = AdjustmentControlsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()
    
    private let bottomControlsContainer: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var originalImage: UIImage?
    private var currentImage: UIImage?
    private var previewImage: UIImage?  // 用于存储预览状态的图片
    private let context = CIContext()
    private let historyManager = EditHistoryManager()
    
    private var currentAdjustments: [AdjustmentType: Float] = [:]
    
    private let filters: [(name: String, filter: String, adjustments: [AdjustmentType: Float]?)] = [
        ("Original", "", nil),
        ("富士NC", "", [
            .exposure: 0.25,      // 曝光度 +25 -> 0.25
            .vibrance: 1.05,      // 鲜明度 +5 -> 1.05
            .highlights: -0.45,   // 高光 -45 -> -0.45
            .shadows: 0.30,       // 阴影 +30 -> 0.30
            .contrast: 1.10,      // 对比 +10 -> 1.10
            .saturation: 1.10,    // 自然饱和度 +10 -> 1.10
            .warmth: 10,          // 色温 +10
            .sharpness: 0.20,     // 锐度 +20 -> 0.20
            .clarity: 0.10        // 清晰度 +10 -> 0.10
        ]),
        ("富士CC", "", [
            .exposure: -0.10,     // 曝光度 -10 -> -0.10
            .vibrance: 1.10,      // 鲜明度 +10 -> 1.10
            .highlights: 0.20,    // 高光 +20 -> 0.20
            .shadows: -0.17,      // 阴影 -17 -> -0.17
            .brightness: 0.08,    // 亮度 +8 -> 0.08
            .blackPoint: 0.15,    // 黑点 +15 -> 0.15
            .saturation: 0.88,    // 自然饱和度 -12 -> 0.88
            .warmth: -15,         // 色温 -15
            .vignette: 0.12       // 晕影 +12 -> 0.12
        ]),
        ("Mono", "CIPhotoEffectMono", nil),
        ("Noir", "CIPhotoEffectNoir", nil),
        ("Fade", "CIPhotoEffectFade", nil),
        ("Chrome", "CIPhotoEffectChrome", nil),
        ("Process", "CIPhotoEffectProcess", nil),
        ("Transfer", "CIPhotoEffectTransfer", nil),
        ("Instant", "CIPhotoEffectInstant", nil),
        ("Sepia", "CISepiaTone", nil)
    ]
    
    var onDismiss: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupNavigationBar()
        setupAdjustmentControls()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 添加子视图
        view.addSubview(imageView)
        view.addSubview(bottomControlsContainer)
        bottomControlsContainer.contentView.addSubview(filterCollectionView)
        bottomControlsContainer.contentView.addSubview(adjustmentControls)
        
        // 设置初始状态
        adjustmentControls.isHidden = true
        filterCollectionView.isHidden = false
        
        // 添加阴影效果
        bottomControlsContainer.layer.shadowColor = UIColor.black.cgColor
        bottomControlsContainer.layer.shadowOffset = CGSize(width: 0, height: -2)
        bottomControlsContainer.layer.shadowOpacity = 0.1
        bottomControlsContainer.layer.shadowRadius = 10
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            bottomControlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomControlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomControlsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomControlsContainer.heightAnchor.constraint(equalToConstant: 160),
            
            filterCollectionView.topAnchor.constraint(equalTo: bottomControlsContainer.contentView.topAnchor, constant: 16),
            filterCollectionView.leadingAnchor.constraint(equalTo: bottomControlsContainer.contentView.leadingAnchor),
            filterCollectionView.trailingAnchor.constraint(equalTo: bottomControlsContainer.contentView.trailingAnchor),
            filterCollectionView.bottomAnchor.constraint(equalTo: bottomControlsContainer.contentView.bottomAnchor, constant: -16),
            
            adjustmentControls.topAnchor.constraint(equalTo: bottomControlsContainer.contentView.topAnchor, constant: 16),
            adjustmentControls.leadingAnchor.constraint(equalTo: bottomControlsContainer.contentView.leadingAnchor, constant: 16),
            adjustmentControls.trailingAnchor.constraint(equalTo: bottomControlsContainer.contentView.trailingAnchor, constant: -16),
            adjustmentControls.bottomAnchor.constraint(equalTo: bottomControlsContainer.contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupAdjustmentControls() {
        adjustmentControls.delegate = self
        // 初始化当前调整值
        for type in AdjustmentType.allCases {
            currentAdjustments[type] = type.defaultValue
        }
    }
    
    private func setupCollectionView() {
        filterCollectionView.delegate = self
        filterCollectionView.dataSource = self
        filterCollectionView.register(FilterCell.self, forCellWithReuseIdentifier: "FilterCell")
    }
    
    private func setupNavigationBar() {
        // 设置导航栏样式
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // 设置标题和自定义字体
        let titleLabel = UILabel()
        titleLabel.text = "滤镜编辑器"
        if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
            .withDesign(.rounded)?
            .withSymbolicTraits(.traitBold) {
            titleLabel.font = UIFont(descriptor: descriptor, size: 20)
        }
        titleLabel.textColor = .label
        navigationItem.titleView = titleLabel
        
        // 左侧关闭按钮
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark.circle.fill"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(closeButtonTapped))
        navigationItem.leftBarButtonItem = closeButton
        
        // 右侧按钮组
        let undoButton = UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.backward"),
                                       style: .plain,
                                       target: self,
                                       action: #selector(undoButtonTapped))
        
        let redoButton = UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.forward"),
                                       style: .plain,
                                       target: self,
                                       action: #selector(redoButtonTapped))
        
        let saveButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down"),
                                       style: .plain,
                                       target: self,
                                       action: #selector(saveButtonTapped))
        
        let adjustButton = UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.3"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(adjustButtonTapped))
        
        navigationItem.rightBarButtonItems = [saveButton, adjustButton, redoButton, undoButton]
    }
    
    @objc private func adjustButtonTapped() {
        // 切换视图显示状态
        UIView.animate(withDuration: 0.3) {
            self.adjustmentControls.isHidden.toggle()
            self.filterCollectionView.isHidden = !self.adjustmentControls.isHidden
            
            // 强制布局更新
            self.view.layoutIfNeeded()
        }
    }
    
    private func applyFilter(name: String) {
        guard let originalImage = originalImage,
              let cgImage = originalImage.cgImage else { return }
        
        var ciImage = CIImage(cgImage: cgImage)
        
        // 重置所有调整参数为默认值
        for type in AdjustmentType.allCases {
            currentAdjustments[type] = type.defaultValue
        }
        
        // 获取并应用滤镜预设的调整参数
        if let filter = filters.first(where: { $0.name == name }) {
            if let adjustments = filter.adjustments {
                // 应用预设的调整参数
                for (type, value) in adjustments {
                    currentAdjustments[type] = value
                }
            }
            
            // 应用滤镜效果（如果有）
            if !filter.filter.isEmpty {
                if let ciFilter = CIFilter(name: filter.filter) {
                    ciFilter.setValue(ciImage, forKey: kCIInputImageKey)
                    if let output = ciFilter.outputImage {
                        ciImage = output
                    }
                }
            }
        }
        
        // 应用所有调整
        ciImage = applyAdjustments(to: ciImage)
        
        // 创建最终图像
        if let cgOutputImage = context.createCGImage(ciImage, from: ciImage.extent) {
            currentImage = UIImage(cgImage: cgOutputImage)
            imageView.image = currentImage
            
            if let currentImage = currentImage {
                historyManager.addEdit(image: currentImage, filterName: name)
                updateNavigationButtons()
            }
        }
    }
    
    private func applyAdjustments(to inputImage: CIImage) -> CIImage {
        var result = inputImage
        
        // 曝光度
        if let exposure = currentAdjustments[.exposure], exposure != 0 {
            let filter = CIFilter(name: "CIExposureAdjust")
            filter?.setValue(result, forKey: kCIInputImageKey)
            filter?.setValue(exposure, forKey: kCIInputEVKey)
            if let output = filter?.outputImage {
                result = output
            }
        }
        
        // 亮度、对比度、饱和度
        let colorControls = CIFilter(name: "CIColorControls")
        colorControls?.setValue(result, forKey: kCIInputImageKey)
        if let brightness = currentAdjustments[.brightness], brightness != 0 {
            colorControls?.setValue(brightness, forKey: kCIInputBrightnessKey)
        }
        if let contrast = currentAdjustments[.contrast], contrast != 1 {
            colorControls?.setValue(contrast, forKey: kCIInputContrastKey)
        }
        if let saturation = currentAdjustments[.saturation], saturation != 1 {
            colorControls?.setValue(saturation, forKey: kCIInputSaturationKey)
        }
        if let output = colorControls?.outputImage {
            result = output
        }
        
        // 黑点调整
        if let blackPoint = currentAdjustments[.blackPoint], blackPoint != 0 {
            let filter = CIFilter(name: "CIColorControls")
            filter?.setValue(result, forKey: kCIInputImageKey)
            // 将黑点值映射到合适的范围
            let mappedValue = 1.0 + (blackPoint * 0.1)
            filter?.setValue(mappedValue, forKey: kCIInputContrastKey)
            if let output = filter?.outputImage {
                result = output
            }
        }
        
        // 高光和阴影
        let hasHighlightChanges = (currentAdjustments[.highlights] ?? 0) != 0
        let hasShadowChanges = (currentAdjustments[.shadows] ?? 0) != 0
        if hasHighlightChanges || hasShadowChanges {
            let filter = CIFilter(name: "CIHighlightShadowAdjust")
            filter?.setValue(result, forKey: kCIInputImageKey)
            filter?.setValue(1.0 + (currentAdjustments[.highlights] ?? 0), forKey: "inputHighlightAmount")
            filter?.setValue(1.0 + (currentAdjustments[.shadows] ?? 0), forKey: "inputShadowAmount")
            if let output = filter?.outputImage {
                result = output
            }
        }
        
        // 鲜明度
        if let vibrance = currentAdjustments[.vibrance], vibrance != 1 {
            let filter = CIFilter(name: "CIVibrance")
            filter?.setValue(result, forKey: kCIInputImageKey)
            filter?.setValue((vibrance - 1) * 2, forKey: "inputAmount")
            if let output = filter?.outputImage {
                result = output
            }
        }
        
        // 色温
        if let warmth = currentAdjustments[.warmth], warmth != 0 {
            let filter = CIFilter(name: "CITemperatureAndTint")
            filter?.setValue(result, forKey: kCIInputImageKey)
            filter?.setValue(CIVector(x: CGFloat(6500 + warmth * 100), y: 0), forKey: "inputTargetNeutral")
            if let output = filter?.outputImage {
                result = output
            }
        }
        
        // 晕影
        if let vignette = currentAdjustments[.vignette], vignette > 0 {
            let filter = CIFilter(name: "CIVignette")
            filter?.setValue(result, forKey: kCIInputImageKey)
            filter?.setValue(vignette * 2, forKey: "inputIntensity")
            filter?.setValue(vignette * 1.5, forKey: "inputRadius")
            if let output = filter?.outputImage {
                result = output
            }
        }
        
        // 锐度
        if let sharpness = currentAdjustments[.sharpness], sharpness > 0 {
            let filter = CIFilter(name: "CISharpenLuminance")
            filter?.setValue(result, forKey: kCIInputImageKey)
            filter?.setValue(sharpness * 0.7, forKey: "inputSharpness")
            if let output = filter?.outputImage {
                result = output
            }
        }
        
        // 清晰度（使用Unsharp Mask实现）
        if let clarity = currentAdjustments[.clarity], clarity > 0 {
            let filter = CIFilter(name: "CIUnsharpMask")
            filter?.setValue(result, forKey: kCIInputImageKey)
            filter?.setValue(3.0, forKey: "inputRadius")
            filter?.setValue(clarity * 0.7, forKey: "inputIntensity")
            if let output = filter?.outputImage {
                result = output
            }
        }
        
        return result
    }
    
    @objc private func closeButtonTapped() {
        onDismiss?()
    }
    
    @objc private func undoButtonTapped() {
        if let (image, filterName) = historyManager.undo() {
            currentImage = image
            imageView.image = image
            updateNavigationButtons()
        }
    }
    
    @objc private func redoButtonTapped() {
        if let (image, filterName) = historyManager.redo() {
            currentImage = image
            imageView.image = image
            updateNavigationButtons()
        }
    }
    
    @objc private func saveButtonTapped() {
        guard let image = currentImage else { return }
        
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    self?.showSaveError(message: "需要访问照片库的权限来保存图片")
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        self?.showSaveSuccess()
                    } else {
                        self?.showSaveError(message: error?.localizedDescription ?? "保存失败")
                    }
                }
            }
        }
    }
    
    private func showSaveSuccess() {
        let alert = UIAlertController(title: "保存成功", message: "图片已保存到相册", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func showSaveError(message: String) {
        let alert = UIAlertController(title: "保存失败", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func updateNavigationButtons() {
        navigationItem.rightBarButtonItems?[1].isEnabled = historyManager.canRedo
        navigationItem.rightBarButtonItems?[2].isEnabled = historyManager.canUndo
    }
    
    func setImage(_ image: UIImage) {
        originalImage = image
        currentImage = image
        imageView.image = image
        historyManager.reset(with: image)
        updateNavigationButtons()
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension PhotoEditorViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as? FilterCell else {
            return UICollectionViewCell()
        }
        
        let filter = filters[indexPath.item]
        cell.titleLabel.text = filter.name
        
        if let thumbnail = originalImage?.thumbnail(size: CGSize(width: 80, height: 80)) {
            if filter.adjustments == nil && filter.filter.isEmpty {
                cell.filterImageView.image = thumbnail
            } else {
                // 创建临时的调整参数
                let tempAdjustments = currentAdjustments
                
                // 如果有预设的调整参数，应用它们
                if let adjustments = filter.adjustments {
                    for (type, value) in adjustments {
                        currentAdjustments[type] = value
                    }
                }
                
                // 创建预览图
                if let cgImage = thumbnail.cgImage {
                    var ciImage = CIImage(cgImage: cgImage)
                    
                    // 应用滤镜（如果有）
                    if !filter.filter.isEmpty {
                        if let ciFilter = CIFilter(name: filter.filter) {
                            ciFilter.setValue(ciImage, forKey: kCIInputImageKey)
                            if let output = ciFilter.outputImage {
                                ciImage = output
                            }
                        }
                    }
                    
                    // 应用调整参数
                    if filter.adjustments != nil {
                        ciImage = applyAdjustments(to: ciImage)
                    }
                    
                    // 生成最终预览图
                    if let outputImage = context.createCGImage(ciImage, from: ciImage.extent) {
                        cell.filterImageView.image = UIImage(cgImage: outputImage)
                    }
                }
                
                // 恢复原来的调整参数
                currentAdjustments = tempAdjustments
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let filter = filters[indexPath.item]
        applyFilter(name: filter.name)
    }
    
    private func applyFilterToThumbnail(_ image: UIImage, filterName: String) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: filterName) else { return nil }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter.outputImage,
              let cgOutputImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgOutputImage)
    }
}

// MARK: - AdjustmentControlsViewDelegate
extension PhotoEditorViewController: AdjustmentControlsViewDelegate {
    func adjustmentValueChanged(type: AdjustmentType, value: Float) {
        currentAdjustments[type] = value
        updateImage()
    }
    
    func adjustmentSliderTouchBegan(type: AdjustmentType) {
        // 保存当前图片作为预览前的状态
        previewImage = imageView.image
        // 显示原图以供对比
        imageView.image = originalImage
    }
    
    func adjustmentSliderTouchEnded(type: AdjustmentType) {
        // 恢复到调整后的图片
        if let previewImage = previewImage {
            imageView.image = previewImage
            self.previewImage = nil
        }
    }
    
    private func updateImage() {
        guard let originalImage = originalImage,
              let ciImage = CIImage(image: originalImage) else { return }
        
        let adjustedImage = applyAdjustments(to: ciImage)
        
        if let cgImage = context.createCGImage(adjustedImage, from: adjustedImage.extent) {
            let uiImage = UIImage(cgImage: cgImage)
            imageView.image = uiImage
            currentImage = uiImage
            previewImage = uiImage
            historyManager.addEdit(image: uiImage, filterName: "")  // 添加空的滤镜名称，因为这是调整而不是滤镜
        }
    }
}

// MARK: - Filter Cell
class FilterCell: UICollectionViewCell {
    
    let filterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.layer.cornerCurve = .continuous
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.filterImageView.transform = self.isSelected ? 
                    CGAffineTransform(scaleX: 0.92, y: 0.92) : .identity
                self.titleLabel.font = self.isSelected ? 
                    .systemFont(ofSize: 13, weight: .semibold) : 
                    .systemFont(ofSize: 13, weight: .medium)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(filterImageView)
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            filterImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            filterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            filterImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            filterImageView.heightAnchor.constraint(equalTo: filterImageView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: filterImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

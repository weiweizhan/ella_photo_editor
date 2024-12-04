import UIKit

protocol AdjustmentControlsViewDelegate: AnyObject {
    func adjustmentValueChanged(type: AdjustmentType, value: Float)
    func adjustmentSliderTouchBegan(type: AdjustmentType)
    func adjustmentSliderTouchEnded(type: AdjustmentType)
}

enum AdjustmentType: String, CaseIterable {
    case exposure = "曝光度"
    case brightness = "亮度"
    case contrast = "对比度"
    case highlights = "高光"
    case shadows = "阴影"
    case saturation = "饱和度"
    case vibrance = "鲜明度"
    case warmth = "色温"
    case sharpness = "锐度"
    case clarity = "清晰度"
    case blackPoint = "黑点"
    case vignette = "晕影"
    
    var defaultValue: Float {
        switch self {
        case .exposure, .brightness, .highlights, .shadows, .blackPoint:
            return 0.0
        case .contrast, .saturation, .vibrance:
            return 1.0
        case .warmth:
            return 0.0
        case .sharpness, .clarity, .vignette:
            return 0.0
        }
    }
    
    var range: (min: Float, max: Float) {
        switch self {
        case .exposure:
            return (-2.0, 2.0)
        case .brightness:
            return (-1.0, 1.0)
        case .contrast, .saturation, .vibrance:
            return (0.0, 2.0)
        case .highlights, .shadows:
            return (-1.0, 1.0)
        case .warmth:
            return (-50.0, 50.0)
        case .sharpness, .clarity:
            return (0.0, 1.0)
        case .blackPoint:
            return (-1.0, 1.0)
        case .vignette:
            return (0.0, 1.0)
        }
    }
    
    var icon: String {
        switch self {
        case .exposure:
            return "sun.max"
        case .brightness:
            return "light.max"
        case .contrast:
            return "circle.lefthalf.filled"
        case .highlights:
            return "rays"
        case .shadows:
            return "shadow"
        case .saturation:
            return "paintpalette"
        case .vibrance:
            return "wand.and.stars"
        case .warmth:
            return "thermometer"
        case .sharpness:
            return "diamond"
        case .clarity:
            return "sparkles"
        case .blackPoint:
            return "circle.fill"
        case .vignette:
            return "camera.filters"
        }
    }
}

class AdjustmentControlsView: UIView {
    weak var delegate: AdjustmentControlsViewDelegate?
    private var sliders: [AdjustmentType: AdjustmentControl] = [:]
    private var currentActiveControl: AdjustmentControl?
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 200)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        addSubview(collectionView)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(AdjustmentCell.self, forCellWithReuseIdentifier: "AdjustmentCell")
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        setupAdjustmentControls()
    }
    
    private func setupAdjustmentControls() {
        for type in AdjustmentType.allCases {
            let control = AdjustmentControl(type: type)
            control.delegate = self
            control.onSliderVisibilityChanged = { [weak self] control, isVisible in
                self?.handleSliderVisibilityChanged(control, isVisible: isVisible)
            }
            sliders[type] = control
        }
    }
    
    private func handleSliderVisibilityChanged(_ control: AdjustmentControl, isVisible: Bool) {
        if isVisible {
            if let activeControl = currentActiveControl, activeControl != control {
                activeControl.hideSlider()
            }
            currentActiveControl = control
        } else if currentActiveControl == control {
            currentActiveControl = nil
        }
    }
    
    func updateValue(_ value: Float, for type: AdjustmentType) {
        sliders[type]?.updateValue(value)
    }
    
    func resetValues() {
        for type in AdjustmentType.allCases {
            sliders[type]?.reset()
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension AdjustmentControlsView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AdjustmentType.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AdjustmentCell", for: indexPath) as! AdjustmentCell
        let type = AdjustmentType.allCases[indexPath.item]
        cell.configure(with: sliders[type]!)
        return cell
    }
}

// MARK: - AdjustmentControlsViewDelegate
extension AdjustmentControlsView: AdjustmentControlsViewDelegate {
    func adjustmentValueChanged(type: AdjustmentType, value: Float) {
        delegate?.adjustmentValueChanged(type: type, value: value)
    }
    
    func adjustmentSliderTouchBegan(type: AdjustmentType) {
        delegate?.adjustmentSliderTouchBegan(type: type)
    }
    
    func adjustmentSliderTouchEnded(type: AdjustmentType) {
        delegate?.adjustmentSliderTouchEnded(type: type)
    }
}

class AdjustmentCell: UICollectionViewCell {
    private let containerView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with control: AdjustmentControl) {
        containerView.subviews.forEach { $0.removeFromSuperview() }
        
        control.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(control)
        
        NSLayoutConstraint.activate([
            control.topAnchor.constraint(equalTo: containerView.topAnchor),
            control.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            control.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            control.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
}

class AdjustmentControl: UIView {
    weak var delegate: AdjustmentControlsViewDelegate?
    private let type: AdjustmentType
    private var isSliderVisible = false
    var onSliderVisibilityChanged: ((AdjustmentControl, Bool) -> Void)?
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private let sliderContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let slider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    init(type: AdjustmentType) {
        self.type = type
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(sliderContainer)
        sliderContainer.addSubview(valueLabel)
        sliderContainer.addSubview(slider)
        addSubview(iconImageView)
        addSubview(nameLabel)
        
        iconImageView.image = UIImage(systemName: type.icon)
        nameLabel.text = type.rawValue
        
        slider.minimumValue = type.range.min
        slider.maximumValue = type.range.max
        slider.value = type.defaultValue
        
        updateValueLabel()
        
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderTouchBegan), for: .touchDown)
        slider.addTarget(self, action: #selector(sliderTouchEnded), for: [.touchUpInside, .touchUpOutside])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(iconTapped))
        iconImageView.addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            // 滑动条容器约束
            sliderContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            sliderContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            sliderContainer.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            sliderContainer.heightAnchor.constraint(equalToConstant: 50),
            
            // 滑动条内部约束
            valueLabel.topAnchor.constraint(equalTo: sliderContainer.topAnchor, constant: 4),
            valueLabel.centerXAnchor.constraint(equalTo: sliderContainer.centerXAnchor),
            
            slider.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 4),
            slider.leadingAnchor.constraint(equalTo: sliderContainer.leadingAnchor, constant: 4),
            slider.trailingAnchor.constraint(equalTo: sliderContainer.trailingAnchor, constant: -4),
            slider.heightAnchor.constraint(equalToConstant: 30),
            
            // 图标约束
            iconImageView.topAnchor.constraint(equalTo: sliderContainer.bottomAnchor, constant: 16),
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),
            
            // 名称标签约束
            nameLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            nameLabel.heightAnchor.constraint(equalToConstant: 16),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8)
        ])
    }
    
    @objc private func iconTapped() {
        toggleSlider()
    }
    
    func toggleSlider() {
        isSliderVisible.toggle()
        UIView.animate(withDuration: 0.3) {
            self.sliderContainer.isHidden = !self.isSliderVisible
        }
        onSliderVisibilityChanged?(self, isSliderVisible)
    }
    
    func hideSlider() {
        if isSliderVisible {
            isSliderVisible = false
            UIView.animate(withDuration: 0.3) {
                self.sliderContainer.isHidden = true
            }
            onSliderVisibilityChanged?(self, false)
        }
    }
    
    private func updateValueLabel() {
        let value = slider.value
        switch type {
        case .exposure, .brightness, .contrast, .highlights, .shadows, .saturation, .vibrance:
            valueLabel.text = String(format: "%.2f", value)
        case .warmth:
            valueLabel.text = String(format: "%.0f", value)
        case .sharpness, .clarity, .blackPoint, .vignette:
            valueLabel.text = String(format: "%.2f", value)
        }
    }
    
    @objc private func sliderValueChanged() {
        updateValueLabel()
        delegate?.adjustmentValueChanged(type: type, value: slider.value)
    }
    
    @objc private func sliderTouchBegan() {
        delegate?.adjustmentSliderTouchBegan(type: type)
    }
    
    @objc private func sliderTouchEnded() {
        delegate?.adjustmentSliderTouchEnded(type: type)
    }
    
    func updateValue(_ value: Float) {
        slider.value = value
        updateValueLabel()
    }
    
    func reset() {
        slider.value = type.defaultValue
        updateValueLabel()
    }
}

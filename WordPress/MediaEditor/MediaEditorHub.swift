import UIKit

class MediaEditorHub: UIViewController {

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var cancelIconButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIVisualEffectView!
    @IBOutlet weak var activityIndicatorLabel: UILabel!
    @IBOutlet weak var horizontalToolbar: UIView!
    @IBOutlet weak var verticalToolbar: UIView!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var thumbsToolbar: UIView!
    @IBOutlet weak var thumbsCollectionView: UICollectionView!
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var capabilitiesCollectionView: UICollectionView!

    weak var delegate: MediaEditorHubDelegate?

    var onCancel: (() -> ())?

    var numberOfThumbs = 0 {
        didSet {
            reloadImagesAndReposition()
        }
    }

    var capabilities: [(String, UIImage)] = [] {
        didSet {
            setupCapabilities()
        }
    }

    var availableThumbs: [Int: UIImage] = [:]

    var availableImages: [Int: UIImage] = [:]

    private(set) var selectedThumbIndex = 0 {
        didSet {
            highlightSelectedThumb(current: selectedThumbIndex, before: oldValue)
            showOrHideActivityIndicator()
        }
    }

    private(set) var isUserScrolling = false

    private var selectedColor: UIColor?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupForOrientation()
        thumbsCollectionView.dataSource = self
        thumbsCollectionView.delegate = self
        imagesCollectionView.dataSource = self
        imagesCollectionView.delegate = self
        capabilitiesCollectionView.dataSource = self
        capabilitiesCollectionView.delegate = self
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupForOrientation()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setupForOrientation()

        coordinator.animate(alongsideTransition: { _ in
            self.reloadImagesAndReposition()
        })
    }

    @IBAction func cancel(_ sender: Any) {
        onCancel?()
    }

    func show(image: UIImage, at index: Int) {
        availableImages[index] = image

        let imageCell = imagesCollectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? MediaEditorImageCell
        imageCell?.imageView.image = image

        showOrHideActivityIndicator()
    }

    func show(thumb: UIImage, at index: Int) {
        availableThumbs[index] = thumb

        let cell = thumbsCollectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? MediaEditorThumbCell
        cell?.thumbImageView.image = thumb

        let imageCell = imagesCollectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? MediaEditorImageCell
        imageCell?.imageView.image = availableImages[index] ?? thumb

        showOrHideActivityIndicator()
    }

    func apply(styles: MediaEditorStyles) {
        loadViewIfNeeded()

        if let cancelLabel = styles[.cancelLabel] as? String {
            cancelButton.setTitle(cancelLabel, for: .normal)
        }

        if let cancelColor = styles[.cancelColor] as? UIColor {
            cancelButton.tintColor = cancelColor
            cancelIconButton.tintColor = cancelColor
        }

        if let cancelIcon = styles[.cancelIcon] as? UIImage {
            cancelIconButton.setImage(cancelIcon, for: .normal)
        }

        if let loadingLabel = styles[.loadingLabel] as? String {
            activityIndicatorLabel.text = loadingLabel
        }

        if let color = styles[.selectedColor] as? UIColor {
            selectedColor = color
        }
    }

    func showActivityIndicator() {
        activityIndicatorView.isHidden = false
    }

    func hideActivityIndicator() {
        activityIndicatorView.isHidden = true
    }

    private func reloadImagesAndReposition() {
        thumbsCollectionView.reloadData()
        imagesCollectionView.reloadData()
        thumbsCollectionView.layoutIfNeeded()
        thumbsCollectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .left)
        imagesCollectionView.scrollToItem(at: IndexPath(row: self.selectedThumbIndex, section: 0), at: .right, animated: false)
        thumbsToolbar.isHidden = numberOfThumbs > 1 ? false : true
    }

    private func setupForOrientation() {
        let isLandscape = UIDevice.current.orientation.isLandscape
        mainStackView.axis = isLandscape ? .horizontal : .vertical
        mainStackView.semanticContentAttribute = isLandscape ? .forceRightToLeft : .unspecified
        horizontalToolbar.isHidden = isLandscape
        verticalToolbar.isHidden = !isLandscape
        if let layout = thumbsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = isLandscape ? .vertical : .horizontal
        }
        if let layout = capabilitiesCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = isLandscape ? .vertical : .horizontal
        }
        mainStackView.layoutIfNeeded()
        imagesCollectionView.scrollToItem(at: IndexPath(row: selectedThumbIndex, section: 0), at: .right, animated: false)
    }

    private func highlightSelectedThumb(current: Int, before: Int) {
        let current = thumbsCollectionView.cellForItem(at: IndexPath(row: current, section: 0)) as? MediaEditorThumbCell
        let before = thumbsCollectionView.cellForItem(at: IndexPath(row: before, section: 0)) as? MediaEditorThumbCell
        before?.hideBorder()
        current?.showBorder()
    }

    private func showOrHideActivityIndicator() {
        let imageAvailable = availableThumbs[selectedThumbIndex] ?? availableImages[selectedThumbIndex]

        imageAvailable == nil ? showActivityIndicator() : hideActivityIndicator()
    }

    private func setupCapabilities() {
        capabilitiesCollectionView.isHidden = capabilities.count > 1 || numberOfThumbs > 1 ? false : true
        capabilitiesCollectionView.reloadData()
    }

    static func initialize() -> MediaEditorHub {
        return UIStoryboard(name: "MediaEditorHub", bundle: nil).instantiateViewController(withIdentifier: "hubViewController") as! MediaEditorHub
    }

    private enum Constants {
        static var thumbCellIdentifier = "thumbCell"
        static var imageCellIdentifier = "imageCell"
        static var capabCellIdentifier = "capabilityCell"
    }
}

// MARK: - UICollectionViewDataSource

extension MediaEditorHub: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionView == capabilitiesCollectionView ? capabilities.count : numberOfThumbs
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Thumbs Collection View
        if collectionView == thumbsCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.thumbCellIdentifier, for: indexPath) as? MediaEditorThumbCell else {
                return UICollectionViewCell()
            }

            cell.thumbImageView.image = availableThumbs[indexPath.row]
            indexPath.row == selectedThumbIndex ? cell.showBorder(color: selectedColor) : cell.hideBorder()

            return cell
        } else if collectionView == imagesCollectionView {
            // Images Collection View
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.imageCellIdentifier, for: indexPath) as? MediaEditorImageCell else {
                return UICollectionViewCell()
            }

            cell.imageView.image = availableImages[indexPath.row] ?? availableThumbs[indexPath.row]

            showOrHideActivityIndicator()

            return cell
        }

        // Capability Collection View
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.capabCellIdentifier, for: indexPath) as? MediaEditorCapabilityCell else {
            return UICollectionViewCell()
        }

        let (name, icon) = capabilities[indexPath.row]
        cell.iconButton.setImage(icon, for: .normal)
        cell.iconButton.accessibilityHint = name

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MediaEditorHub: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == imagesCollectionView {
            return CGSize(width: imagesCollectionView.frame.width, height: imagesCollectionView.frame.height)
        }

        return CGSize(width: 44, height: 44)
    }
}

// MARK: - UICollectionViewDelegate

extension MediaEditorHub: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == thumbsCollectionView {
            selectedThumbIndex = indexPath.row
            imagesCollectionView.scrollToItem(at: indexPath, at: .right, animated: true)
        } else if collectionView == capabilitiesCollectionView {
            delegate?.capabilityTapped(indexPath.row)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == imagesCollectionView, isUserScrolling else {
            return
        }

        let index = Int(round(scrollView.bounds.origin.x / imagesCollectionView.frame.width))

        thumbsCollectionView.selectItem(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .right)
        selectedThumbIndex = index
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView == imagesCollectionView else {
            return
        }

        isUserScrolling = true
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == imagesCollectionView else {
            return
        }

        isUserScrolling = false
    }
}

protocol MediaEditorHubDelegate: class {
    func capabilityTapped(_ index: Int)
}

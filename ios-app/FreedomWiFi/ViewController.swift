import UIKit
import NetworkExtension

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var installButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var configDetailsView: UIView!
    @IBOutlet weak var ssidLabel: UILabel!
    @IBOutlet weak var providerLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    private let serverURL = "https://d94cb394-db1a-49a3-92c8-c2e278b17f39-00-1jrec4u5fwe6h.riker.replit.dev"
    private var wifiConfigData: WiFiConfigData?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadWiFiConfiguration()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Setup title
        titleLabel.text = "Freedom WiFi"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .systemBlue
        
        // Setup status
        statusLabel.text = "Загрузка конфигурации..."
        statusLabel.font = UIFont.systemFont(ofSize: 16)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        
        // Setup install button
        installButton.setTitle("Установить WiFi профиль", for: .normal)
        installButton.backgroundColor = .systemBlue
        installButton.layer.cornerRadius = 12
        installButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        installButton.isEnabled = false
        
        // Setup progress view
        progressView.isHidden = true
        progressView.progressTintColor = .systemBlue
        
        // Setup config details
        configDetailsView.layer.cornerRadius = 12
        configDetailsView.backgroundColor = .secondarySystemBackground
        configDetailsView.isHidden = true
        
        // Setup activity indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        // Add logo placeholder
        logoImageView.image = UIImage(systemName: "wifi.circle.fill")
        logoImageView.tintColor = .systemBlue
        logoImageView.contentMode = .scaleAspectFit
    }
    
    // MARK: - Load WiFi Configuration
    
    private func loadWiFiConfiguration() {
        let configURL = "\(serverURL)/hs20/profile.mobileconfig"
        
        guard let url = URL(string: configURL) else {
            showError("Неверный URL конфигурации")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                
                if let error = error {
                    self?.showError("Ошибка загрузки: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self?.showError("Не удалось получить данные конфигурации")
                    return
                }
                
                self?.parseConfiguration(data: data)
            }
        }.resume()
    }
    
    // MARK: - Parse Configuration
    
    private func parseConfiguration(data: Data) {
        guard let wifiConfig = WiFiConfigManager.shared.parseWiFiFromMobileConfig(data: data) else {
            showError("Не удалось распарсить конфигурацию")
            return
        }
        
        self.wifiConfigData = wifiConfig
        updateUIWithConfiguration(wifiConfig)
    }
    
    private func updateUIWithConfiguration(_ config: WiFiConfigData) {
        // Update status
        if config.isPasspoint {
            statusLabel.text = "Готов к установке Passpoint конфигурации для автоматического подключения к сети Freedom WiFi"
            providerLabel.text = "Домен: \(config.passpointDomain ?? "Не указан")"
            ssidLabel.text = "Тип: Passpoint (Hotspot 2.0)"
        } else if config.isEAP {
            statusLabel.text = "Готов к установке EAP конфигурации для сети: \(config.ssid ?? "Неизвестная")"
            ssidLabel.text = "Сеть: \(config.ssid ?? "Не указана")"
            providerLabel.text = "Пользователь: \(config.username ?? "Не указан")"
        } else {
            statusLabel.text = "Готов к установке WPA конфигурации для сети: \(config.ssid ?? "Неизвестная")"
            ssidLabel.text = "Сеть: \(config.ssid ?? "Не указана")"
            providerLabel.text = "Тип: WPA/WPA2"
        }
        
        // Show details and enable button
        configDetailsView.isHidden = false
        installButton.isEnabled = true
        installButton.backgroundColor = .systemBlue
    }
    
    // MARK: - Install WiFi Configuration
    
    @IBAction func installButtonTapped(_ sender: UIButton) {
        guard let config = wifiConfigData else {
            showError("Конфигурация не загружена")
            return
        }
        
        // Disable button and show progress
        installButton.isEnabled = false
        progressView.isHidden = false
        statusLabel.text = "Установка конфигурации..."
        
        // Choose installation method based on config type
        if config.isPasspoint, let domain = config.passpointDomain, 
           let username = config.username, let password = config.password {
            
            // Install Passpoint configuration
            WiFiConfigManager.shared.installPasspointConfiguration(
                domainName: domain,
                username: username,
                password: password,
                roamingConsortiumOIs: config.roamingConsortiumOIs
            ) { [weak self] success, error in
                self?.handleInstallationResult(success: success, error: error, type: "Passpoint")
            }
            
        } else if config.isEAP, let ssid = config.ssid, 
                  let username = config.username, let password = config.password {
            
            // Install EAP configuration
            WiFiConfigManager.shared.installEAPWiFiConfiguration(
                ssid: ssid,
                username: username,
                password: password,
                trustedServerNames: config.trustedServerNames
            ) { [weak self] success, error in
                self?.handleInstallationResult(success: success, error: error, type: "EAP")
            }
            
        } else if let ssid = config.ssid, let passphrase = config.passphrase {
            
            // Install WPA configuration
            WiFiConfigManager.shared.installWiFiConfiguration(
                ssid: ssid,
                passphrase: passphrase
            ) { [weak self] success, error in
                self?.handleInstallationResult(success: success, error: error, type: "WPA")
            }
            
        } else {
            showError("Недостаточно данных для установки конфигурации")
            installButton.isEnabled = true
            progressView.isHidden = true
        }
    }
    
    private func handleInstallationResult(success: Bool, error: Error?, type: String) {
        DispatchQueue.main.async { [weak self] in
            self?.progressView.isHidden = true
            
            if success {
                self?.statusLabel.text = "✅ \(type) конфигурация успешно установлена! Устройство автоматически подключится к доступным сетям Freedom WiFi."
                self?.statusLabel.textColor = .systemGreen
                self?.installButton.setTitle("Установлено успешно", for: .normal)
                self?.installButton.backgroundColor = .systemGreen
                
                // Show success animation
                UIView.animate(withDuration: 0.3) {
                    self?.logoImageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                } completion: { _ in
                    UIView.animate(withDuration: 0.3) {
                        self?.logoImageView.transform = .identity
                    }
                }
                
            } else {
                let errorMessage = error?.localizedDescription ?? "Неизвестная ошибка"
                self?.showError("Ошибка установки \(type): \(errorMessage)")
                self?.installButton.isEnabled = true
                self?.installButton.backgroundColor = .systemBlue
            }
        }
    }
    
    // MARK: - Show Installed Configurations
    
    @IBAction func showInstalledConfigs(_ sender: UIButton) {
        WiFiConfigManager.shared.getAppliedConfigurations { [weak self] ssids in
            let message = ssids.isEmpty ? "Нет установленных конфигураций" : 
                         "Установленные конфигурации:\n\(ssids.joined(separator: "\n"))"
            
            let alert = UIAlertController(title: "Установленные WiFi конфигурации", 
                                        message: message, 
                                        preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
    
    // MARK: - Error Handling
    
    private func showError(_ message: String) {
        statusLabel.text = "❌ \(message)"
        statusLabel.textColor = .systemRed
        
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
import Foundation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

class WiFiConfigManager: NSObject {
    
    static let shared = WiFiConfigManager()
    
    // MARK: - Install WiFi Configuration using NEHotspotConfiguration
    
    func installWiFiConfiguration(ssid: String, passphrase: String, isWPA3: Bool = true, completion: @escaping (Bool, Error?) -> Void) {
        
        guard !ssid.isEmpty else {
            completion(false, WiFiConfigError.invalidSSID)
            return
        }
        
        let configuration = NEHotspotConfiguration(ssid: ssid, passphrase: passphrase, isWEP: false)
        
        // Enable automatic joining
        configuration.joinOnce = false
        
        NEHotspotConfigurationManager.shared.apply(configuration) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to configure WiFi: \(error.localizedDescription)")
                    completion(false, error)
                } else {
                    print("WiFi configuration applied successfully for SSID: \(ssid)")
                    completion(true, nil)
                }
            }
        }
    }
    
    // MARK: - Install EAP WiFi Configuration (for Passpoint/Enterprise)
    
    func installEAPWiFiConfiguration(
        ssid: String,
        username: String,
        password: String,
        trustedServerNames: [String]? = nil,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        
        guard !ssid.isEmpty, !username.isEmpty, !password.isEmpty else {
            completion(false, WiFiConfigError.invalidCredentials)
            return
        }
        
        // EAP Settings
        let eapSettings = NEHotspotEAPSettings()
        eapSettings.username = username
        eapSettings.password = password
        eapSettings.supportedEAPTypes = [NSNumber(value: NEHotspotEAPSettings.EAPType.EAPTTLS.rawValue)]
        
        // Set trusted server names if provided
        if let serverNames = trustedServerNames, !serverNames.isEmpty {
            eapSettings.trustedServerNames = serverNames
        }
        
        // Set EAP-TTLS inner authentication to PAP
        eapSettings.ttlsInnerAuthenticationType = .eapttlsInnerAuthenticationPAP
        
        // Create configuration with EAP settings
        let configuration = NEHotspotConfiguration(ssid: ssid, eapSettings: eapSettings)
        configuration.joinOnce = false
        
        NEHotspotConfigurationManager.shared.apply(configuration) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to configure EAP WiFi: \(error.localizedDescription)")
                    completion(false, error)
                } else {
                    print("EAP WiFi configuration applied successfully for SSID: \(ssid)")
                    completion(true, nil)
                }
            }
        }
    }
    
    // MARK: - Install Passpoint Configuration
    
    func installPasspointConfiguration(
        domainName: String,
        username: String,
        password: String,
        roamingConsortiumOIs: [String]? = nil,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        
        guard !domainName.isEmpty, !username.isEmpty, !password.isEmpty else {
            completion(false, WiFiConfigError.invalidCredentials)
            return
        }
        
        // EAP Settings for Passpoint
        let eapSettings = NEHotspotEAPSettings()
        eapSettings.username = username
        eapSettings.password = password
        eapSettings.supportedEAPTypes = [NSNumber(value: NEHotspotEAPSettings.EAPType.EAPTTLS.rawValue)]
        eapSettings.ttlsInnerAuthenticationType = .eapttlsInnerAuthenticationPAP
        eapSettings.trustedServerNames = [domainName]
        
        // Create configuration with domain prefix and EAP settings
        let configuration = NEHotspotConfiguration(ssidPrefix: domainName, eapSettings: eapSettings)
        configuration.joinOnce = false
        
        NEHotspotConfigurationManager.shared.apply(configuration) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to configure Passpoint: \(error.localizedDescription)")
                    completion(false, error)
                } else {
                    print("Passpoint configuration applied successfully for domain: \(domainName)")
                    completion(true, nil)
                }
            }
        }
    }
    
    // MARK: - Remove WiFi Configuration
    
    func removeWiFiConfiguration(ssid: String, completion: @escaping (Bool, Error?) -> Void) {
        NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
        DispatchQueue.main.async {
            completion(true, nil)
        }
    }
    
    // MARK: - Get Applied Configurations
    
    func getAppliedConfigurations(completion: @escaping ([String]) -> Void) {
        NEHotspotConfigurationManager.shared.getConfiguredSSIDs { ssids in
            DispatchQueue.main.async {
                completion(ssids)
            }
        }
    }
    
    // MARK: - Parse MobileConfig Data
    
    func parseWiFiFromMobileConfig(data: Data) -> WiFiConfigData? {
        do {
            guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
                  let payloadContent = plist["PayloadContent"] as? [[String: Any]] else {
                return nil
            }
            
            for payload in payloadContent {
                if let payloadType = payload["PayloadType"] as? String,
                   payloadType == "com.apple.wifi.managed" {
                    
                    var wifiConfig = WiFiConfigData()
                    
                    // Extract SSID
                    if let ssid = payload["SSID_STR"] as? String {
                        wifiConfig.ssid = ssid
                    }
                    
                    // Extract Passpoint domain
                    if let domain = payload["HS20DomainName"] as? String {
                        wifiConfig.passpointDomain = domain
                    }
                    
                    // Extract EAP configuration
                    if let eapConfig = payload["EAPClientConfiguration"] as? [String: Any] {
                        if let username = eapConfig["UserName"] as? String {
                            wifiConfig.username = username
                        }
                        if let password = eapConfig["UserPassword"] as? String {
                            wifiConfig.password = password
                        }
                        if let serverNames = eapConfig["TLSTrustedServerNames"] as? [String] {
                            wifiConfig.trustedServerNames = serverNames
                        }
                        if let outerIdentity = eapConfig["OuterIdentity"] as? String {
                            wifiConfig.outerIdentity = outerIdentity
                        }
                    }
                    
                    // Extract roaming consortium OIs
                    if let ois = payload["HS20RoamingConsortiumOIs"] as? [String] {
                        wifiConfig.roamingConsortiumOIs = ois
                    }
                    
                    return wifiConfig
                }
            }
            
        } catch {
            print("Failed to parse mobile config: \(error)")
        }
        
        return nil
    }
}

// MARK: - WiFi Configuration Data Structure

struct WiFiConfigData {
    var ssid: String?
    var passphrase: String?
    var username: String?
    var password: String?
    var passpointDomain: String?
    var trustedServerNames: [String]?
    var outerIdentity: String?
    var roamingConsortiumOIs: [String]?
    var isEAP: Bool {
        return username != nil && password != nil
    }
    var isPasspoint: Bool {
        return passpointDomain != nil
    }
}

// MARK: - WiFi Configuration Errors

enum WiFiConfigError: LocalizedError {
    case invalidSSID
    case invalidCredentials
    case networkNotFound
    case configurationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidSSID:
            return "Invalid SSID provided"
        case .invalidCredentials:
            return "Invalid username or password"
        case .networkNotFound:
            return "WiFi network not found"
        case .configurationFailed:
            return "Failed to apply WiFi configuration"
        }
    }
}
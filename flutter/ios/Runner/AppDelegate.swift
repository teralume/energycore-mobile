import Flutter
import UIKit
import Security

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "com.teralume.energycore/secure_storage",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    let store = KeychainTokenStore()
    channel.setMethodCallHandler { call, result in
      do {
        switch call.method {
        case "read": result(try store.read())
        case "write":
          guard let args = call.arguments as? [String: Any],
                let token = args["token"] as? String, !token.isEmpty else {
            result(FlutterError(code: "SECURE_STORAGE_ERROR", message: "Missing token", details: nil))
            return
          }
          try store.write(token)
          result(nil)
        case "clear":
          try store.clear()
          result(nil)
        default: result(FlutterMethodNotImplemented)
        }
      } catch {
        result(FlutterError(code: "SECURE_STORAGE_ERROR", message: "Keychain operation failed", details: nil))
      }
    }
  }
}

/// Keeps the existing Dart storage contract; tokens never enter preferences or logs.
final class KeychainTokenStore {
  private let service: String
  init(service: String = "com.teralume.energycore.auth") { self.service = service }

  private var query: [String: Any] {
    [kSecClass as String: kSecClassGenericPassword,
     kSecAttrService as String: service,
     kSecAttrAccount as String: "session-token"]
  }

  private func check(_ status: OSStatus) throws {
    guard status == errSecSuccess else {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
  }

  func read() throws -> String? {
    var request = query
    request[kSecReturnData as String] = true
    request[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    let status = SecItemCopyMatching(request as CFDictionary, &item)
    if status == errSecItemNotFound { return nil }
    try check(status)
    guard let data = item as? Data, let token = String(data: data, encoding: .utf8) else {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(errSecDecode))
    }
    return token
  }

  func write(_ token: String) throws {
    let values: [String: Any] = [
      kSecValueData as String: Data(token.utf8),
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]
    let status = SecItemUpdate(query as CFDictionary, values as CFDictionary)
    if status == errSecItemNotFound {
      try check(SecItemAdd(query.merging(values) { _, new in new } as CFDictionary, nil))
    } else {
      try check(status)
    }
  }

  func clear() throws {
    let status = SecItemDelete(query as CFDictionary)
    if status != errSecItemNotFound { try check(status) }
  }
}

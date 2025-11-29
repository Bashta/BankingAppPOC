import Foundation

final class DependencyContainer {

    // MARK: - Service Properties (Lazy Initialization)

    // Secure Storage - MUST be declared before AuthService (dependency order)
    lazy var secureStorage: SecureStorageProtocol = KeychainSecureStorage()

    // Account Services
    lazy var accountService: AccountServiceProtocol = MockAccountService()

    // Transaction Services
    lazy var transactionService: TransactionServiceProtocol = MockTransactionService()

    // Transfer Services
    lazy var transferService: TransferServiceProtocol = MockTransferService()

    // Card Services
    lazy var cardService: CardServiceProtocol = MockCardService()

    // Beneficiary Services
    lazy var beneficiaryService: BeneficiaryServiceProtocol = MockBeneficiaryService()

    // Notification Services
    lazy var notificationService: NotificationServiceProtocol = MockNotificationService()

    // Biometric Services (real implementation)
    lazy var biometricService: BiometricServiceProtocol = BiometricService()

    // Auth Services
    lazy var authService: AuthServiceProtocol = MockAuthService()

    // MARK: - Initialization

    init() {}
}

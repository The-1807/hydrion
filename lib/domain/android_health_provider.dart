enum AndroidHealthProviderStatus {
  available,
  unavailable,
  unsupported,
  installationRequired,
  updateRequired,
  disabled,
  workProfileUnsupported,
  temporarilyUnavailable,
  configurationError,
}

enum AndroidHealthPermissionState {
  notRequested,
  partiallyGranted,
  granted,
  denied,
  revoked,
}

enum AndroidHealthConnectionState {
  disconnected,
  connected,
  connectedNoContributingSource,
  connectedRequiredMetricUnavailable,
  emptyHistory,
  synchronizationFailed,
  synchronized,
}

enum AndroidHealthIntegrationRoute {
  healthConnect,
  huaweiHealthKit,
  vendorApi,
  vendorSdk,
  companionExport,
  documentedBle,
  smartBottle,
  unknown,
}

enum AndroidHealthServiceKind { healthHub, companionApp }

enum AndroidHealthExportStatus {
  verified,
  requiresVerification,
  unavailable,
}

class AndroidHealthService {
  final String packageName;
  final String serviceName;
  final AndroidHealthServiceKind kind;
  final bool installed;
  final bool enabled;
  final AndroidHealthExportStatus exportStatus;
  final AndroidHealthIntegrationRoute route;

  const AndroidHealthService({
    required this.packageName,
    required this.serviceName,
    required this.kind,
    required this.installed,
    required this.enabled,
    required this.exportStatus,
    required this.route,
  });
}

class AndroidHealthEnvironment {
  final String phoneManufacturer;
  final String phoneModel;
  final int sdkLevel;
  final bool googleMobileServicesAvailable;
  final bool googlePlayStoreAvailable;
  final bool workProfile;
  final bool healthConnectBuiltIn;
  final bool healthConnectPackageInstalled;
  final AndroidHealthProviderStatus healthConnectStatus;
  final AndroidHealthPermissionState permissionState;
  final AndroidHealthConnectionState connectionState;
  final List<AndroidHealthService> companionServices;

  const AndroidHealthEnvironment({
    required this.phoneManufacturer,
    required this.phoneModel,
    required this.sdkLevel,
    required this.googleMobileServicesAvailable,
    required this.googlePlayStoreAvailable,
    required this.workProfile,
    required this.healthConnectBuiltIn,
    required this.healthConnectPackageInstalled,
    required this.healthConnectStatus,
    this.permissionState = AndroidHealthPermissionState.notRequested,
    this.connectionState = AndroidHealthConnectionState.disconnected,
    required this.companionServices,
  });

  bool get manualHydrationAvailable => true;

  bool get canRequestHealthConnectPermission =>
      healthConnectStatus == AndroidHealthProviderStatus.available &&
      !workProfile;
}

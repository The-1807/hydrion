package com.the1807.hydrion

import android.content.Context
import android.os.Build
import android.os.UserManager
import androidx.health.connect.client.HealthConnectClient

internal class AndroidHealthProviderDiscovery(private val context: Context) {
    private val packageManager = context.packageManager

    fun discover(): Map<String, Any?> {
        val workProfile =
            context.getSystemService(UserManager::class.java)?.isManagedProfile == true
        val googleServices = packageState(GOOGLE_PLAY_SERVICES)
        val playStore = packageState(GOOGLE_PLAY_STORE)
        val healthConnect = packageState(HEALTH_CONNECT)
        val sdkStatus = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            HealthConnectSdkStatusProbe.read(context)
        } else {
            HealthConnectSdkStatus.UNAVAILABLE
        }

        return mapOf(
            "phoneManufacturer" to Build.MANUFACTURER,
            "phoneModel" to Build.MODEL,
            "sdkLevel" to Build.VERSION.SDK_INT,
            "googleMobileServicesAvailable" to googleServices.enabled,
            "googlePlayStoreAvailable" to playStore.enabled,
            "workProfile" to workProfile,
            "healthConnectBuiltIn" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE),
            "healthConnectPackageInstalled" to healthConnect.installed,
            "healthConnectStatus" to healthConnectStatus(
                sdkStatus = sdkStatus,
                sdkLevel = Build.VERSION.SDK_INT,
                workProfile = workProfile,
                googleServicesAvailable = googleServices.enabled,
                packageState = healthConnect,
            ),
            "permissionState" to "notRequested",
            "connectionState" to "disconnected",
            "companions" to COMPANION_PACKAGES.map { candidate ->
                val state = packageState(candidate.packageName)
                mapOf(
                    "packageName" to candidate.packageName,
                    "serviceName" to candidate.serviceName,
                    "kind" to candidate.kind,
                    "installed" to state.installed,
                    "enabled" to state.enabled,
                    "exportStatus" to "requiresVerification",
                    "route" to candidate.route,
                )
            },
        )
    }

    private fun healthConnectStatus(
        sdkStatus: HealthConnectSdkStatus,
        sdkLevel: Int,
        workProfile: Boolean,
        googleServicesAvailable: Boolean,
        packageState: PackageState,
    ): String {
        if (workProfile) return "workProfileUnsupported"
        if (sdkLevel < Build.VERSION_CODES.P) return "unsupported"
        if (!googleServicesAvailable) return "unsupported"
        return when (sdkStatus) {
            HealthConnectSdkStatus.AVAILABLE -> "available"
            HealthConnectSdkStatus.PROVIDER_UPDATE_REQUIRED -> {
                when {
                    !packageState.installed -> "installationRequired"
                    !packageState.enabled -> "disabled"
                    else -> "updateRequired"
                }
            }
            HealthConnectSdkStatus.UNAVAILABLE -> "unsupported"
            HealthConnectSdkStatus.UNKNOWN -> "configurationError"
        }
    }

    private fun packageState(packageName: String): PackageState = try {
        val application = packageManager.getApplicationInfo(packageName, 0)
        PackageState(installed = true, enabled = application.enabled)
    } catch (_: Exception) {
        PackageState(installed = false, enabled = false)
    }

    private data class PackageState(val installed: Boolean, val enabled: Boolean)

    private data class CompanionCandidate(
        val packageName: String,
        val serviceName: String,
        val kind: String,
        val route: String,
    )

    private companion object {
        const val HEALTH_CONNECT = "com.google.android.apps.healthdata"
        const val GOOGLE_PLAY_SERVICES = "com.google.android.gms"
        const val GOOGLE_PLAY_STORE = "com.android.vending"

        val COMPANION_PACKAGES = listOf(
            CompanionCandidate(
                "com.sec.android.app.shealth",
                "Samsung Health",
                "healthHub",
                "healthConnect",
            ),
            CompanionCandidate(
                "com.huawei.health",
                "Huawei Health",
                "healthHub",
                "huaweiHealthKit",
            ),
            CompanionCandidate(
                "cn.xiaofengkj.fitpro",
                "FitPro",
                "companionApp",
                "unknown",
            ),
            CompanionCandidate(
                "com.transsion.healthlife",
                "Infinix HealthLife",
                "companionApp",
                "unknown",
            ),
        )
    }
}

private object HealthConnectSdkStatusProbe {
    fun read(context: Context): HealthConnectSdkStatus = when (
        HealthConnectClient.getSdkStatus(
            context,
            "com.google.android.apps.healthdata",
        )
    ) {
        HealthConnectClient.SDK_AVAILABLE -> HealthConnectSdkStatus.AVAILABLE
        HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED ->
            HealthConnectSdkStatus.PROVIDER_UPDATE_REQUIRED
        HealthConnectClient.SDK_UNAVAILABLE -> HealthConnectSdkStatus.UNAVAILABLE
        else -> HealthConnectSdkStatus.UNKNOWN
    }
}

private enum class HealthConnectSdkStatus {
    AVAILABLE,
    PROVIDER_UPDATE_REQUIRED,
    UNAVAILABLE,
    UNKNOWN,
}

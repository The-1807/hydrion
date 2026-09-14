package com.the1807.hydrion

import android.content.Intent
import android.os.Build
import android.os.RemoteException
import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.changes.DeletionChange
import androidx.health.connect.client.changes.UpsertionChange
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.DistanceRecord
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.Record
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.request.ChangesTokenRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.time.Instant
import java.io.IOException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.reflect.KClass

/** API-28-gated Health Connect boundary. No health values are logged here. */
internal class AndroidHealthConnectHost(private val activity: MainActivity) {
    private var cachedClient: HealthConnectClient? = null
    private val client: HealthConnectClient
        get() = cachedClient ?: HealthConnectClient.getOrCreate(activity).also {
            cachedClient = it
        }
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var pendingPermissionResult: MethodChannel.Result? = null
    private val permissionContract =
        PermissionController.createRequestPermissionResultContract()

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "authorizationState" -> scope.launch {
                complete(result, call.method) { authorizationPayload(parseMetrics(call)) }
            }
            "requestPermissions" -> requestPermissions(call, result)
            "readInitial" -> scope.launch { complete(result, call.method) { readInitial(call) } }
            "readChanges" -> scope.launch { complete(result, call.method) { readChanges(call) } }
            "openSettings" -> openSettings(result)
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        pendingPermissionResult?.error(
            "permission_request_cancelled",
            "The Health Connect permission request was interrupted.",
            null,
        )
        pendingPermissionResult = null
        cachedClient = null
        scope.cancel()
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        permissionContract.parseResult(resultCode, data)
        val pending = pendingPermissionResult
        pendingPermissionResult = null
        if (pending != null) {
            scope.launch { complete(pending, "permissionResult") { authorizationPayload(ALL_METRICS) } }
        }
        return true
    }

    private fun requestPermissions(call: MethodCall, result: MethodChannel.Result) {
        if (pendingPermissionResult != null) {
            result.error("permission_request_active", "A permission request is already active.", null)
            return
        }
        val requested = try {
            parseMetrics(call)
        } catch (_: Exception) {
            result.error("invalid_request", "The requested health categories are invalid.", null)
            return
        }
        pendingPermissionResult = result
        val permissions = requested.mapTo(mutableSetOf()) { permissionFor(it) }
        activity.startActivityForResult(
            permissionContract.createIntent(activity, permissions),
            PERMISSION_REQUEST_CODE,
        )
    }

    private fun openSettings(result: MethodChannel.Result) {
        try {
            val action = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                "android.health.connect.action.HEALTH_HOME_SETTINGS"
            } else {
                "androidx.health.ACTION_HEALTH_CONNECT_SETTINGS"
            }
            activity.startActivity(Intent(action))
            result.success(null)
        } catch (_: Exception) {
            result.error("settings_unavailable", "Health Connect settings are unavailable.", null)
        }
    }

    private suspend fun authorizationPayload(metrics: Set<String>): Map<String, Any> {
        val granted = client.permissionController.getGrantedPermissions()
        val grantedMetrics = metrics.filterTo(mutableSetOf()) {
            granted.contains(permissionFor(it))
        }
        val state = when {
            grantedMetrics.size == metrics.size -> "granted"
            grantedMetrics.isNotEmpty() -> "partial"
            else -> "notGranted"
        }
        return mapOf("state" to state, "grantedMetrics" to grantedMetrics.sorted())
    }

    private suspend fun readInitial(call: MethodCall): Map<String, Any?> {
        val metric = parseSingleMetric(call)
        val start = parseInstant(call, "historyStart")
        val end = parseInstant(call, "historyEnd")
        require(start.isBefore(end))
        val pageToken = call.argument<String>("pageToken")?.takeIf { it.isNotBlank() }
        val changesToken = call.argument<String>("changesToken")?.takeIf { it.isNotBlank() }
            ?: try {
                client.getChangesToken(ChangesTokenRequest(setOf(recordType(metric))))
            } catch (error: Exception) {
                Log.e(TAG, "readInitial token metric=$metric error=${error.javaClass.simpleName}")
                throw error
            }
        val response = try {
            when (metric) {
                "workout" -> readPage(ExerciseSessionRecord::class, start, end, pageToken)
                "activeEnergy" -> readPage(ActiveCaloriesBurnedRecord::class, start, end, pageToken)
                "steps" -> readPage(StepsRecord::class, start, end, pageToken)
                "distance" -> readPage(DistanceRecord::class, start, end, pageToken)
                else -> error("Unsupported metric")
            }
        } catch (error: Exception) {
            Log.e(TAG, "readInitial query metric=$metric error=${error.javaClass.simpleName}")
            throw error
        }
        Log.i(TAG, "readInitial result metric=$metric records=${response.first.size}")
        val records = try {
            response.first.map { mapRecord(it, metric) }
        } catch (error: Exception) {
            Log.e(TAG, "readInitial mapping metric=$metric error=${error.javaClass.simpleName}")
            throw error
        }
        return mapOf(
            "records" to records,
            "pageToken" to response.second,
            "changesToken" to changesToken,
        )
    }

    private suspend fun <T : Record> readPage(
        type: KClass<T>,
        start: Instant,
        end: Instant,
        pageToken: String?,
    ): Pair<List<Record>, String?> {
        val response = client.readRecords(
            ReadRecordsRequest(
                recordType = type,
                timeRangeFilter = TimeRangeFilter.between(start, end),
                ascendingOrder = true,
                pageSize = MAX_PAGE_SIZE,
                pageToken = pageToken,
            ),
        )
        return response.records to response.pageToken
    }

    private suspend fun readChanges(call: MethodCall): Map<String, Any?> {
        val metric = parseSingleMetric(call)
        val token = call.argument<String>("changesToken")
            ?.takeIf { it.isNotBlank() } ?: error("Missing changes token")
        val response = try {
            client.getChanges(token)
        } catch (_: IllegalArgumentException) {
            return mapOf(
                "records" to emptyList<Map<String, Any?>>(),
                "changesToken" to token,
                "hasMore" to false,
                "tokenExpired" to true,
            )
        }
        Log.i(TAG, "readChanges result metric=$metric changes=${response.changes.size}")
        val changes = try {
            response.changes.mapNotNull { change ->
                when (change) {
                    is UpsertionChange -> mapRecord(change.record, metric)
                    is DeletionChange -> mapOf(
                        "recordId" to bounded(change.recordId, MAX_IDENTIFIER_LENGTH),
                        "deleted" to true,
                        "metric" to metric,
                    )
                    else -> null
                }
            }
        } catch (error: Exception) {
            Log.e(TAG, "readChanges mapping metric=$metric error=${error.javaClass.simpleName}")
            throw error
        }
        return mapOf(
            "records" to changes,
            "changesToken" to response.nextChangesToken,
            "hasMore" to response.hasMore,
            "tokenExpired" to response.changesTokenExpired,
        )
    }

    private fun mapRecord(record: Record, expectedMetric: String): Map<String, Any?> {
        val actualMetric: String
        val value: Double
        val originalUnit: String
        val category: String?
        val startTime: Instant
        val endTime: Instant
        val startOffsetSeconds: Int?
        val endOffsetSeconds: Int?
        when (record) {
            is ExerciseSessionRecord -> {
                actualMetric = "workout"
                value = java.time.Duration.between(record.startTime, record.endTime).toMillis() / 60000.0
                originalUnit = "minute"
                category = record.exerciseType.toString()
                startTime = record.startTime
                endTime = record.endTime
                startOffsetSeconds = record.startZoneOffset?.totalSeconds
                endOffsetSeconds = record.endZoneOffset?.totalSeconds
            }
            is ActiveCaloriesBurnedRecord -> {
                actualMetric = "activeEnergy"
                value = record.energy.inKilocalories
                originalUnit = "kilocalorie"
                category = null
                startTime = record.startTime
                endTime = record.endTime
                startOffsetSeconds = record.startZoneOffset?.totalSeconds
                endOffsetSeconds = record.endZoneOffset?.totalSeconds
            }
            is StepsRecord -> {
                actualMetric = "steps"
                value = record.count.toDouble()
                originalUnit = "count"
                category = null
                startTime = record.startTime
                endTime = record.endTime
                startOffsetSeconds = record.startZoneOffset?.totalSeconds
                endOffsetSeconds = record.endZoneOffset?.totalSeconds
            }
            is DistanceRecord -> {
                actualMetric = "distance"
                value = record.distance.inMeters
                originalUnit = "meter"
                category = null
                startTime = record.startTime
                endTime = record.endTime
                startOffsetSeconds = record.startZoneOffset?.totalSeconds
                endOffsetSeconds = record.endZoneOffset?.totalSeconds
            }
            else -> error("Unsupported Health Connect record")
        }
        require(actualMetric == expectedMetric && value.isFinite() && value >= 0.0)
        val metadata = record.metadata
        return mapOf(
            "recordId" to bounded(metadata.id, MAX_IDENTIFIER_LENGTH),
            "metric" to actualMetric,
            "value" to value,
            "originalUnit" to originalUnit,
            "category" to category,
            "startTime" to startTime.toString(),
            "endTime" to endTime.toString(),
            "startOffsetSeconds" to startOffsetSeconds,
            "endOffsetSeconds" to endOffsetSeconds,
            "lastModifiedTime" to metadata.lastModifiedTime.toString(),
            "clientRecordVersion" to metadata.clientRecordVersion.toString(),
            "sourceApplicationId" to bounded(
                metadata.dataOrigin.packageName,
                MAX_IDENTIFIER_LENGTH,
            ),
            "deviceManufacturer" to optionalBounded(
                metadata.device?.manufacturer,
                MAX_TEXT_LENGTH,
            ),
            "deviceModel" to optionalBounded(metadata.device?.model, MAX_TEXT_LENGTH),
            "recordingMethod" to recordingMethod(metadata),
            "deleted" to false,
        )
    }

    private suspend fun complete(
        result: MethodChannel.Result,
        operationName: String,
        operation: suspend () -> Any?,
    ) {
        try {
            val value = try {
                operation()
            } catch (_: RemoteException) {
                Log.w(TAG, "$operationName retrying after RemoteException")
                cachedClient = null
                operation()
            }
            withContext(Dispatchers.Main) { result.success(value) }
        } catch (_: SecurityException) {
            withContext(Dispatchers.Main) {
                result.error("permission_denied", "Health Connect permission is required.", null)
            }
        } catch (error: IOException) {
            Log.e(TAG, "$operationName failed: IOException")
            withContext(Dispatchers.Main) {
                result.error("health_connect_io_failure", "Health Connect could not complete the request.", null)
            }
        } catch (error: IllegalArgumentException) {
            Log.e(TAG, "$operationName failed: IllegalArgumentException")
            withContext(Dispatchers.Main) {
                result.error("health_connect_invalid_request", "Health Connect could not complete the request.", null)
            }
        } catch (error: Exception) {
            Log.e(TAG, "$operationName failed: ${error.javaClass.simpleName}")
            withContext(Dispatchers.Main) {
                result.error("health_connect_failure", "Health Connect could not complete the request.", null)
            }
        }
    }

    private fun parseMetrics(call: MethodCall): Set<String> {
        val raw = call.argument<List<String>>("metrics") ?: error("Missing metrics")
        val metrics = raw.toSet()
        require(metrics.isNotEmpty() && ALL_METRICS.containsAll(metrics))
        return metrics
    }

    private fun parseSingleMetric(call: MethodCall): String {
        val metric = call.argument<String>("metric") ?: error("Missing metric")
        require(metric in ALL_METRICS)
        return metric
    }

    private fun parseInstant(call: MethodCall, key: String): Instant =
        Instant.parse(call.argument<String>(key) ?: error("Missing time"))

    private fun permissionFor(metric: String): String = when (metric) {
        "workout" -> HealthPermission.getReadPermission(ExerciseSessionRecord::class)
        "activeEnergy" -> HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class)
        "steps" -> HealthPermission.getReadPermission(StepsRecord::class)
        "distance" -> HealthPermission.getReadPermission(DistanceRecord::class)
        else -> error("Unsupported metric")
    }

    private fun recordType(metric: String): KClass<out Record> = when (metric) {
        "workout" -> ExerciseSessionRecord::class
        "activeEnergy" -> ActiveCaloriesBurnedRecord::class
        "steps" -> StepsRecord::class
        "distance" -> DistanceRecord::class
        else -> error("Unsupported metric")
    }

    private fun recordingMethod(metadata: Metadata): String = when (metadata.recordingMethod) {
        Metadata.RECORDING_METHOD_ACTIVELY_RECORDED,
        Metadata.RECORDING_METHOD_AUTOMATICALLY_RECORDED -> "sensor"
        Metadata.RECORDING_METHOD_MANUAL_ENTRY -> "manual"
        else -> "unknown"
    }

    private fun bounded(value: String, maximum: Int): String {
        require(value.isNotBlank() && value.length <= maximum)
        return value
    }

    private fun optionalBounded(value: String?, maximum: Int): String? =
        value?.takeIf { it.isNotBlank() }?.let { bounded(it, maximum) }

    private companion object {
        const val MAX_PAGE_SIZE = 250
        const val MAX_IDENTIFIER_LENGTH = 512
        const val MAX_TEXT_LENGTH = 200
        const val PERMISSION_REQUEST_CODE = 7180
        const val TAG = "HydrionHealthConnect"
        val ALL_METRICS = setOf("workout", "activeEnergy", "steps", "distance")
    }
}

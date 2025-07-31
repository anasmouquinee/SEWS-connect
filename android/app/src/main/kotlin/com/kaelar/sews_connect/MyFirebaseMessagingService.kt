package com.kaelar.sews_connect

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import android.util.Log

class MyFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "FCMService"
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        Log.d(TAG, "From: ${remoteMessage.from}")
        
        // Check if message contains a data payload
        if (remoteMessage.data.isNotEmpty()) {
            Log.d(TAG, "Message data payload: ${remoteMessage.data}")
            
            // Handle data payload
            handleDataMessage(remoteMessage.data)
        }
        
        // Check if message contains a notification payload
        remoteMessage.notification?.let {
            Log.d(TAG, "Message Notification Body: ${it.body}")
            // Handle notification payload if needed
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "Refreshed token: $token")
        
        // Send token to your app server if needed
        sendRegistrationToServer(token)
    }

    private fun handleDataMessage(data: Map<String, String>) {
        // Handle department notifications
        val department = data["department"]
        val messageType = data["type"]
        val priority = data["priority"]
        
        Log.d(TAG, "Department: $department, Type: $messageType, Priority: $priority")
        
        // You can add custom logic here for different types of messages
        when (messageType) {
            "task_assignment" -> handleTaskAssignment(data)
            "emergency" -> handleEmergency(data)
            "maintenance_alert" -> handleMaintenanceAlert(data)
            else -> Log.d(TAG, "Unknown message type: $messageType")
        }
    }

    private fun handleTaskAssignment(data: Map<String, String>) {
        Log.d(TAG, "Task assignment notification received")
        // Handle task assignment logic
    }

    private fun handleEmergency(data: Map<String, String>) {
        Log.d(TAG, "Emergency notification received")
        // Handle emergency notifications with high priority
    }

    private fun handleMaintenanceAlert(data: Map<String, String>) {
        Log.d(TAG, "Maintenance alert received")
        // Handle maintenance alerts
    }

    private fun sendRegistrationToServer(token: String) {
        Log.d(TAG, "Sending token to server: $token")
        // Implement logic to send token to your server
    }
}

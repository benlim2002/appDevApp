const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Cloud Function to send notification when item is verified
exports.sendVerificationNotification = functions.firestore
  .document("items/{itemId}")
  .onUpdate(async (change, context) => {
    const item = change.after.data();
    const itemId = context.params.itemId;

    // Check if item is verified and if it's the correct status
    if (item.verification === "yes") {
      // Get the user's FCM token (make sure it's stored in Firestore under user profile)
      const userDoc = await admin.firestore().collection('users').doc(item.userId).get();
      const fcmToken = userDoc.data().fcm_token;

      if (fcmToken != null) {
        // Send notification
        const payload = {
          notification: {
            title: 'Item Verified',
            body: 'The item you posted has been verified as secured.',
            sound: 'default',
          },
          token: fcmToken,
        };

        await admin.messaging().send(payload);
      }
    }
  });

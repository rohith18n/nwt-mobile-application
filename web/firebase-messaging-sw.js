// Import the necessary Firebase modules
importScripts('https://www.gstatic.com/firebasejs/9.6.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker
const firebaseConfig = {
  apiKey: "AIzaSyByuekHT6ISVDHhaLngcSMSz_LlAaWg64g",
  authDomain: "nwt-app-28415.firebaseapp.com",
  projectId: "nwt-app-28415",
  storageBucket: "nwt-app-28415.firebasestorage.app",
  messagingSenderId: "823813601514",
  appId: "1:823813601514:web:d75f9e956c97ab91453f93"
};

// Initialize Firebase
const app = firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging(app);

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  // Customize notification here
  const notificationTitle = payload.notification?.title || 'New Notification';
  const notificationOptions = {
    body: payload.notification?.body,
    icon: payload.notification?.icon || '/icons/icon-192x192.png',
    data: payload.data || {},
    // Add other notification options as needed
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Optional: Handle notification click events
self.addEventListener('notificationclick', (event) => {
  // Close the notification popup
  event.notification.close();
  
  // Handle the click event
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then((clientList) => {
      for (const client of clientList) {
        if (client.url === '/' && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});

// Optional: Handle push subscription change
self.addEventListener('pushsubscriptionchange', (event) => {
  event.waitUntil(
    Promise.all([
      // Your subscription change handling logic here
    ])
  );
});

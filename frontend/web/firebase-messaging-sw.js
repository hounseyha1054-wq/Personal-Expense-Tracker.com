// Firebase Cloud Messaging Service Worker for Web Push Notifications
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

// Initialize Firebase inside the Service Worker
firebase.initializeApp({
  apiKey: "AIzaSyBcBuJUyZNjWmd8oQ6Az8Pc85uX3FeWJqE",
  projectId: "personal-expense-tracker-e03ec",
  messagingSenderId: "314791280440",
  appId: "1:314791280440:web:849f90fe3457c2561c0bcd",
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message: ", payload);

  const notificationTitle = payload.notification?.title || "Expense Tracker";
  const notificationOptions = {
    body: payload.notification?.body || "You have a new update",
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    data: payload.data,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});


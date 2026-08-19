// Firebase Messaging Service Worker
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCDs7i04k42v69t-6jwkaUgM2ZDKwPbc84",
  authDomain: "edutech-smk-app.firebaseapp.com",
  projectId: "edutech-smk-app",
  storageBucket: "edutech-smk-app.firebasestorage.app",
  messagingSenderId: "646724848403",
  appId: "1:646724848403:web:9ae1f7137c736af2ebe8e6",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
  const title = payload.notification?.title || "EduTech SMK";
  const body = payload.notification?.body || "";
  self.registration.showNotification(title, { body, icon: "/icons/Icon-192.png" });
});

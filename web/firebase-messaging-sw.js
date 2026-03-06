/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

const firebaseConfig = self.CRACKZONE_FIREBASE_CONFIG || null;

if (firebaseConfig) {
  firebase.initializeApp(firebaseConfig);
}

const messaging = firebase.apps.length ? firebase.messaging() : null;

if (messaging) {
  messaging.onBackgroundMessage((payload) => {
    const notification = payload.notification || {};
    const title = notification.title || 'crackzone';
    const options = {
      body: notification.body || '',
      icon: '/icons/Icon-192.png',
    };
    self.registration.showNotification(title, options);
  });
}

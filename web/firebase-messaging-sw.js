/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDzEV6QVVQfN75455u3wonhdr4uhZHf5ao',
  authDomain: 'crackzone-472dd.firebaseapp.com',
  projectId: 'crackzone-472dd',
  storageBucket: 'crackzone-472dd.firebasestorage.app',
  messagingSenderId: '678569739060',
  appId: '1:678569739060:web:7629124a465f9ac8f01b61',
  measurementId: 'G-28WE17QEQZ',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const title = notification.title || 'crackzone';
  const options = {
    body: notification.body || '',
    icon: '/icons/Icon-192.png',
  };
  self.registration.showNotification(title, options);
});

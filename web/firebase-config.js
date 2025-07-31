// Firebase configuration for SEWS Connect Web
const firebaseConfig = {
  apiKey: "AIzaSyDjKQQQKKKKKKKKKKKKKKKKKKKKKKKKKKK",
  authDomain: "sews-connect.firebaseapp.com",
  databaseURL: "https://sews-connect-default-rtdb.firebaseio.com",
  projectId: "sews-connect",
  storageBucket: "sews-connect.appspot.com",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdefghijklmnopqr",
  measurementId: "G-ABCDEFGHIJ"
};

// Initialize Firebase
import { initializeApp } from 'firebase/app';
const app = initializeApp(firebaseConfig);

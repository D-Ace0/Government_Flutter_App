# Government Flutter App

A mobile application built with Flutter to enhance communication and services between citizens, government (municipality), and local advertisers.

## 📱 Overview

This app streamlines urban life management in neighborhoods through a centralized platform that supports:

- Government-to-citizen announcements
- Polling and voting on public matters
- Problem reporting and geolocation tagging
- Advertisements for local businesses (with government approval)
- Messaging and feedback mechanisms between users and government

## 👥 User Roles

### 🏛️ Government (Admin)
- Post public announcements with optional media (images, PDFs)
- Create and manage polls (e.g., renovations, public works)
- Read and respond to citizen messages
- Approve and manage advertisements
- Add and update official phone numbers

### 👤 Citizens
- View and comment on announcements
- Participate in polls (anonymous voting, optional anonymous comments)
- Report problems with images and map locations
- Send private messages to government
- Access emergency and public service contacts

### 📢 Advertisers
- Submit advertisements for products and services
- Ads appear to citizens only after government approval

## 🔐 Features

- Firebase Authentication for secure user accounts (1 admin account for government)
- Role-based access control: Citizens, Government, Advertisers
- Firebase Firestore for real-time online database
- Push Notifications (e.g., for new announcements or messages)
- Error handling (connectivity issues, input validation)
- Interactive UI with bottom navigation and tabs
- CRUD operations for announcements and ads
- Out-of-scope feature: AI moderation for offensive language (Arabic & English)
- UX-first design with clean navigation and accessibility

## 🧠 Bonus AI Feature
- AI-based filtering to detect and prevent posting offensive Arabic/English comments (+5 Bonus)

## 💡 Technologies Used

- Flutter & Dart
- Firebase Authentication & Firestore
- Firebase Cloud Messaging (FCM)
- Google Maps API
- AI Content Moderation (Custom logic or third-party NLP)
- Provider / Riverpod (for state management)

## 🚀 How to Run
   ```bash
   git clone https://github.com/D-Ace0/Government_Flutter_App.git
   cd Government_Flutter_App
   flutter pub get
   flutter run

#  Novel Reader -- Full-Stack Diploma Project

Novel Reader is a full-stack application for reading novels with chapter
navigation, authentication, comments, reporting system, and AI-powered
translation.

This project was developed as a diploma thesis to demonstrate full-stack
architecture, secure authentication, REST API integration,
environment-based configuration, and modern mobile UI development using
Flutter.

------------------------------------------------------------------------

# Features

## Reading System

-   Chapter-based navigation
-   Automatic scroll-to-top when switching chapters
-   Adjustable font size
-   Adjustable line height
-   Multiple reading themes:
    -   Light
    -   Soft Grey
    -   Dark Blue
    -   Dark (OLED-friendly)

## Authentication

-   User registration
-   User login
-   JWT-based authentication
-   Secure token storage
-   Automatic login after registration

## Comments

-   Add comments to chapters
-   View comments
-   Report inappropriate comments

##  Reporting System

-   Report chapters
-   Report comments

##  Translation

-   Translate chapters into multiple languages
-   Supports multiple providers:
    -   LibreTranslate
    -   DeepL
    -   OpenAI

------------------------------------------------------------------------

#  Tech Stack

## Backend

-   Node.js
-   Express
-   Prisma ORM
-   PostgreSQL
-   JWT Authentication

## Mobile App

-   Flutter
-   REST API integration
-   Custom theming system


------------------------------------------------------------------------

# ⚙️ Installation & Setup

## Clone the repository


git clone https://github.com/Xissahky/diploma.git
cd diploma


------------------------------------------------------------------------

# 🌐 Backend

The backend server is already deployed and configured.

No local setup is required. No environment configuration is required.

Simply use the existing production API.

------------------------------------------------------------------------

# 📱 Flutter App Setup

## Install Flutter dependencies


cd novel_app
flutter pub get


------------------------------------------------------------------------

## Run the app

Use the following command to start the Flutter application:


flutter run --dart-define=BASE_URL=https://diploma-kkqq.onrender.com


------------------------------------------------------------------------

# 📝 Notes

-   Backend is already deployed and maintained by the author.
-   No server configuration steps are required.
-   Make sure your device/emulator has internet access.
-   Your first call to server can have delay 30-50 seconds for server to wake up.
-   If you get some kind of problem trying to run contact me on e-mail: 68149@student.wsiz.edu.pl

------------------------------------------------------------------------

#  Security Notes

-   Environment variables are stored in `.env`
-   `.env` is excluded via `.gitignore`
-   JWT is used for secure authentication
-   Passwords are hashed before storage
-   API keys are handled server-side

------------------------------------------------------------------------

#  Academic Purpose

This project demonstrates:

-   Full-stack development
-   REST API architecture
-   Authentication and authorization
-   Secure environment configuration
-   Integration with third-party APIs
-   Clean Flutter UI architecture

Developed as a diploma thesis project.


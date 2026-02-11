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

##  Clone the repository

git clone https://github.com/Xissahky/diploma.git
cd diploma

------------------------------------------------------------------------

#  Backend Setup

## Install dependencies

cd webserver_novels\
npm install

------------------------------------------------------------------------

## Configure environment variables

Copy the example file:

cp .env.example .env

Fill in required values inside `.env`.

For evaluation purposes, the author can provide a ready-to-use `.env` configuration file upon request.

------------------------------------------------------------------------

##  Run database migrations

npx prisma migrate dev

------------------------------------------------------------------------

## Start backend server

npm run start

Server will run at:

http://localhost:3000

------------------------------------------------------------------------

#  Flutter App Setup

## Install Flutter dependencies

cd ../novel_app
flutter pub get

------------------------------------------------------------------------

##  Run the app

flutter run

If using Android emulator, backend URL should be:

http://10.0.2.2:3000

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


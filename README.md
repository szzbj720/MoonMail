# MoonMail 🌙💜

MoonMail is an iOS app I built for long-distance couples who want a softer and more personal way to stay connected. The idea came from wanting to create something more intimate than a normal messaging app. Instead of focusing only on texting, MoonMail gives two partners a private shared space where they can leave notes, share moods, save memories, send small affection signals, and keep track of important relationship dates.

I built the app with SwiftUI and Firebase, with a real shared-room flow where one partner creates a private Moon Room and the other joins using a unique Moon Code.

---

## Why I Built This

I wanted MoonMail to feel like a small digital home for two people.

A lot of relationship apps focus on messages, calendars, or generic tracking features, but I wanted to build something that felt more emotional and personal. For long-distance couples especially, staying connected is not always about having a full conversation. Sometimes it is just about sending a small signal, saving a memory, or seeing that your partner updated their mood.

That was the main reason I built MoonMail. I wanted to design an app where two people could share a private space that feels calm, warm, and intentional.

This project also gave me a chance to practice building a real iOS app with authentication, real-time shared data, image uploads, and Firebase security rules.

---

## The Problem

Long-distance couples have plenty of ways to communicate, but many of those tools are built around conversations rather than connection.

Texting apps are designed for messaging. Social media is designed for sharing with everyone. Calendar apps are designed for scheduling.

I wanted to explore a different question:

How can technology help two people feel more connected without requiring constant communication?

For many couples, especially those in long-distance relationships, small interactions often matter more than long conversations. A quick mood update, a saved memory, or a simple signal can help someone feel connected even during a busy day.

MoonMail was my attempt to build a product around those smaller moments.

---

## Overview

MoonMail lets two partners connect inside a private shared Moon Room.

One partner creates a room and receives a unique Moon Code. The second partner uses that code to join. Once both people are connected, they can see shared notes, moods, memories, signals, and relationship milestones in real time.

The app is designed around a simple idea: long-distance connection should feel easy, private, and emotionally meaningful.

---

## My Solution

I built MoonMail as a private shared space for two people.

Instead of creating another messaging platform, I focused on lightweight interactions that help couples stay connected over time. The app combines shared memories, moods, notes, signals, and relationship milestones into a single experience designed specifically for long-distance relationships.

My goal was to make the app feel less like a utility and more like a shared digital space that belongs to both partners.

---

## Screenshots
Screenshots below show the main onboarding flow, shared home screen, notes, memories, and relationship settings.

<p align="center">
  <img src="MoonMail/screenshots/Welcome.png" alt="Welcome Screen" width="220" />
  <img src="MoonMail/screenshots/CreateAccount.png" alt="Create Account Screen" width="220" />
  <img src="MoonMail/screenshots/Login.png" alt="Login Screen" width="220" />
  <img src="MoonMail/screenshots/Join.png" alt="Join Screen" width="220" />
</p>

<p align="center">
  <img src="MoonMail/screenshots/Home.png" alt="Home Screen" width="220" />
  <img src="MoonMail/screenshots/Notes.png" alt="Notes Screen" width="220" />
  <img src="MoonMail/screenshots/Memories.png" alt="Memories Screen" width="220" />
  <img src="MoonMail/screenshots/Us.png" alt="Us Screen" width="220" />
</p>

---

## How the App Works

MoonMail starts with an authentication and room-connection flow.

A user can create an account, create a Moon Room, and receive a unique Moon Code. Their partner can then create an account and join the same room using that code. Once connected, both users share the same couple document in Firestore.

I designed it this way because I wanted the app to feel private and intentional. The room code makes the experience feel more personal than simply searching for a username or adding a random contact.

Each Moon Room is limited to two people, which keeps the app focused on the couple experience.

---

## Features

### Authentication and Moon Room Flow

* Create an account with email and password
* Log in using Firebase Authentication
* Create a private Moon Room
* Generate a unique Moon Code
* Join an existing Moon Room using that code
* Limit each Moon Room to exactly two people
* Store user and couple data in Firestore

### Home

The Home screen acts as the couple’s shared dashboard.

It shows both partners’ names, relationship milestones, recent signals, and shared mood updates. I wanted this screen to feel like the center of the app, where both people can quickly see what is happening in their shared space.

Home includes:

* Real partner names loaded from Firestore
* Together Since card
* Days together calculation
* Next Moonrise reunion countdown
* Shared Moon Mood updates
* Shared Moon Signals
* Recent signal activity

### Moon Notes

Moon Notes lets partners leave shared notes for each other.

I wanted this feature to feel lighter than a full messaging system. It is meant for small thoughts, reminders, sweet messages, or anything the couple wants to keep in their shared space.

Moon Notes includes:

* Real-time shared notes
* Notes stored under the shared couple document
* Loading, success, error, and empty states
* Shared visibility between both partners

### Moon Mood

Moon Mood lets each partner update how they are feeling.

I added this because long-distance communication is not always about sending a full message. Sometimes it helps to quickly see your partner’s mood and feel more connected throughout the day.

Moon Mood includes:

* Real-time mood updates
* Cute icon-based mood selection
* Mood visibility for both partners
* Firestore-backed shared state

### Moon Signals

Moon Signals are small affection actions that partners can send to each other.

This was one of my favorite features to design because I wanted the app to support simple, low-pressure ways to connect. Instead of needing to write something, a user can send a quick emotional signal.

Signals include:

* Moon Hug
* Leave Star
* Dream of Me
* Moon Kiss

The Home screen also shows recent signal activity so the couple can see small moments of interaction over time.

### Moon Memories

Moon Memories lets partners upload and save shared photos.

Each memory includes an image, title, and caption. The image is stored in Firebase Storage, while the memory metadata is stored in Firestore. Both partners can view the shared memories, but only the person who uploaded a memory can delete it.

Moon Memories includes:

* Photo upload
* Title and caption fields
* Firebase Storage image handling
* Firestore metadata storage
* Shared memory feed
* Owner-only delete behavior
* Loading, upload, success, error, and empty states

### Us Tab

The Us tab is where the couple can manage relationship details.

I wanted this tab to feel like a quiet settings and milestone page instead of a generic profile page. It shows the Moon Code, partner connection details, and important dates.

The Us tab includes:

* Moon Code display
* Copy-code feedback
* Connected partner information
* Official relationship date
* Reunion date
* Compact expandable date rows
* Live Firestore data updates

---

## Design Process

I designed MoonMail around a soft, cozy visual style because the app is meant to feel personal rather than productivity-focused.

The main design goal was to make the app feel calm and private. I used a moon-themed concept because it fit the long-distance idea well: two people can be in different places but still feel connected through the same shared space.

I also tried to make the user flow simple. A partner should be able to create a room, share a code, and connect without needing a complicated setup process.

As I built the app, I focused on making each feature feel connected to the couple’s relationship instead of adding features just for the sake of having more screens.

---

## Product Decisions

A few product decisions shaped the direction of MoonMail:

* I limited each Moon Room to two people because the experience is designed around a single relationship.
* I used a Moon Code instead of username search to make joining feel more personal and intentional.
* I chose lightweight features like moods and signals because connection is not always about having a full conversation.
* I avoided building a traditional chat system because there are already many apps that do that well.
* I designed the Home screen as a shared dashboard so both partners immediately see what is happening in their Moon Room.
* I focused on emotional interactions rather than productivity-style features because the goal of the app is connection, not organization.

Throughout development, I tried to ask whether a feature actually strengthened the relationship experience rather than simply adding functionality.

---

## Technical Approach

I built MoonMail with SwiftUI because I wanted to practice native iOS development and create a polished mobile experience.

Firebase was used because the app depends heavily on real-time shared data. Firestore allowed both partners to see updates without manually refreshing the app, while Firebase Authentication handled account creation and login. Firebase Storage was used for memory image uploads.

The app is organized into multiple SwiftUI views and supporting logic files. I separated authentication, room creation, room joining, shared couple data, notes, moods, signals, memories, and relationship settings so the code would be easier to maintain.

I also added Firestore and Storage rules so that users can only access data connected to their own Moon Room.

---

## Tech Stack

* Swift
* SwiftUI
* Firebase Authentication
* Cloud Firestore
* Firebase Storage
* Firebase iOS SDK
* Xcode
* Git
* GitHub

---

## Technical Highlights

* Built a native iOS app with SwiftUI
* Implemented Firebase Authentication for account creation and login
* Created a private room-joining system using unique Moon Codes
* Connected two users to the same shared Firestore couple document
* Enforced a two-person room limit
* Used Cloud Firestore for real-time shared notes, moods, signals, and relationship data
* Used Firebase Storage for photo uploads
* Added owner-only deletion for uploaded memories
* Added Firestore and Storage rules for access control
* Added loading, success, error, and empty states across major features
* Added unit tests for date logic, partner-name logic, and signal time formatting
* Improved accessibility across shared UI components

---

## Firebase Setup

MoonMail uses the following Firebase services:

* Firebase Authentication with Email/Password
* Cloud Firestore
* Firebase Storage

The app is connected to Firebase using:

```text
GoogleService-Info.plist
```

For security, this file should not be committed publicly with real production credentials.

---

## Firestore Structure

MoonMail uses two main top-level collections:

```text
users
couples
```

### User Document

```text
users/{uid}
```

Each user document stores basic account and room connection information.

Example fields:

```text
uid
name
email
coupleId
createdAt
```

### Couple Document

```text
couples/{coupleId}
```

Each couple document represents one shared Moon Room.

Example fields:

```text
moonCode
memberIds
memberNames
officialDate
reunionDate
createdAt
```

Shared app data such as notes, signals, moods, and memories are connected to the couple document so both partners can access the same room data.

---

## What I Learned

MoonMail helped me understand what it takes to build a real shared mobile experience instead of a static app.

Some of the biggest things I learned were:

* How to build an authentication flow with Firebase
* How to structure shared user data in Firestore
* How to design a private two-person room system
* How to work with real-time updates in a SwiftUI app
* How to upload and display images using Firebase Storage
* How to think through access control with Firestore and Storage rules
* How to handle loading, empty, success, and error states in a user-friendly way
* How to write unit tests for important app logic
* How to design features around a real emotional use case, not just technical requirements

One challenge I worked through was making sure the Moon Room flow felt clear. At first, the relationship between account creation, room creation, and room joining was easy to make confusing. I improved the flow by separating the onboarding steps and making the Moon Code the main connection point between two users.

Another challenge was keeping shared data consistent between partners. Since both users interact with the same room, I had to think carefully about how Firestore documents should be structured and how each screen should read and update shared data.

---

## What I'd Improve Next

If I continued developing MoonMail, I would spend more time gathering feedback from real couples and observing how they naturally use the product.

Some improvements I would prioritize include:

* Push notifications for meaningful relationship moments
* More personalization and customization options
* Better onboarding for couples joining their first Moon Room
* Shared relationship timelines and milestone history
* Improved offline support
* More polished animations and transitions
* TestFlight distribution and App Store deployment

One thing this project taught me is that relationship products are highly personal. Small design decisions can have a surprisingly large impact on how users feel while using the app, which makes user feedback especially important.

---

## Future Improvements

Some features I would like to add next include:

* Push notifications for new notes, moods, and signals
* More customizable Moon Room themes
* In-app anniversary reminders
* Private voice notes
* A shared countdown widget
* More memory organization options
* Better offline support
* App Store TestFlight deployment
* More polished animations and transitions

---

## Why This Project Matters To Me

MoonMail matters to me because it was not just a technical project. I wanted to build something that felt personal and emotionally useful. Part of the reason I built MoonMail is because I have personally experienced long distance and understand how small moments of connection can matter. I wanted to build something for people like me who may not always have time for a full conversation, but still want a private and meaningful way to feel close to their partner.

It gave me a chance to practice iOS development, Firebase, real-time data, image uploads, and security rules, but it also pushed me to think more about product design. I had to ask what kind of interactions would actually help two people feel closer, instead of only thinking about what features I could add.

This project helped me grow not only as a mobile developer, but also as someone interested in product development. Building MoonMail required me to think about user emotions, feature prioritization, onboarding, and long-term engagement in addition to the technical implementation. It reinforced my interest in building products that solve real problems while creating experiences people genuinely enjoy using.
---

## Author

Selena Zhang

GitHub:
https://github.com/szzbj720

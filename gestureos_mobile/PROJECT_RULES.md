# GestureOS - Project Rules

## Project Overview

GestureOS is a premium gesture-powered productivity platform built with Flutter.

The goal is to create a beautiful, modern, scalable, production-ready application that allows users to interact with their devices naturally using hand gestures.

This is NOT a prototype.

This is intended to become a real production application.

---

# Tech Stack

Frontend
- Flutter (Latest Stable)
- Dart

State Management
- Riverpod

Navigation
- GoRouter

Architecture
- Feature First
- Clean Architecture

Backend
- FastAPI

Database
- PostgreSQL

Authentication
- Supabase Auth

Storage
- Supabase Storage

Real Time
- WebSocket

Computer Vision
- MediaPipe Hands

Version Control
- Git

---

# Architecture Rules

Always follow Feature First Architecture.

Every feature must remain independent.

Each feature should contain:

```
feature_name/

data/

domain/

presentation/

widgets/

providers/
```

Never mix feature logic.

Business logic must never be inside UI.

---

# Folder Structure

Always follow this structure.

```
lib/

app/

core/

shared/

features/

main.dart
```

Never create random folders.

---

# SOLID Principles

Always follow SOLID.

Keep classes small.

One responsibility per class.

Avoid large files.

Prefer composition over inheritance.

---

# UI Rules

Follow the provided UI design exactly.

Never redesign.

Never change colors.

Never change spacing.

Never change typography.

Never change layout.

Never invent new components.

Everything should remain visually consistent.

---

# Design Language

Theme

Dark

Premium

Minimal

Modern

Futuristic

Elegant

Glassmorphism

Purple Neon

Soft Glow

Rounded Corners

Beautiful Animations

Professional

---

# Colors

Background

#09090B

Surface

#111118

Card

#17171F

Primary

#7C3AED

Secondary

#8B5CF6

Accent

#A855F7

Success

#22C55E

Error

#EF4444

Border

#2A2A35

Primary Text

White

Secondary Text

#A1A1AA

Never introduce additional colors unless requested.

---

# Typography

Use a modern font.

Clear hierarchy.

Consistent spacing.

Large headings.

Readable body text.

---

# Components

Always create reusable components.

Examples

CustomButton

CustomTextField

CustomCard

CustomAppBar

PrimaryContainer

LoadingWidget

Never duplicate widgets.

---

# Animations

Animations should always be smooth.

Use

Fade

Scale

Slide

Hero

AnimatedContainer

AnimatedSwitcher

Keep animation duration between

200ms–350ms

Never use excessive animations.

Target 60 FPS.

---

# Performance Rules

Minimize rebuilds.

Use const widgets.

Lazy load data.

Avoid unnecessary state updates.

Never block the UI thread.

---

# Riverpod Rules

Use Riverpod for state management.

Do not use Provider.

Do not use GetX.

Do not use Bloc unless explicitly requested.

Separate

State

Controller

Repository

Use immutable state.

---

# Routing

Always use GoRouter.

Never use Navigator.push directly unless necessary.

Routes should be centralized.

---

# Networking

Use Dio.

Create a reusable API client.

No HTTP calls inside UI.

Repositories communicate with APIs.

---

# Error Handling

Never silently ignore errors.

Show user-friendly error messages.

Log exceptions.

Never crash the app.

---

# Logging

Use Logger package.

Separate

Debug Logs

Info Logs

Warning Logs

Error Logs

---

# File Naming

snake_case.dart

Examples

login_screen.dart

gesture_controller.dart

transfer_repository.dart

Never use inconsistent naming.

---

# Naming Rules

Classes

PascalCase

Variables

camelCase

Constants

camelCase

Files

snake_case

Folders

snake_case

---

# Widgets

Keep widgets small.

Maximum

250 lines

If larger

Split into widgets.

---

# Screens

Each screen should have

page/

widgets/

providers/

controller/

Never place everything inside one file.

---

# Dependency Injection

Use GetIt.

Register services.

Never instantiate services directly inside widgets.

---

# Responsiveness

Support

Android Phones

Android Tablets

iPhone

iPad

Landscape

Portrait

Never hardcode dimensions.

Use responsive layouts.

---

# Gesture Engine Rules

Gesture logic must remain isolated.

Never mix gesture code with UI.

Separate

Camera

Detection

Recognition

State Machine

Gesture Mapping

---

# File Transfer Rules

Always separate

Upload

Download

Encryption

History

WebSocket

Storage

Never place everything in one class.

---

# Code Quality

Every new file must contain documentation.

Every public class must have comments.

Avoid duplicate code.

Avoid magic numbers.

Prefer constants.

Follow Effective Dart Guidelines.

---

# Before Creating New Code

Always check whether an existing widget, service, model, helper, utility, or repository already solves the problem.

Reuse existing code whenever possible.

Never duplicate functionality.

---

# Before Editing Existing Code

Never rewrite working code unnecessarily.

Only modify files required for the requested feature.

Do not refactor unrelated code.

Do not rename existing classes unless requested.

Maintain backward compatibility.

---

# Packages

Before adding a package

Check if Flutter already provides the functionality.

Only install packages when necessary.

Avoid unnecessary dependencies.

---

# Testing

Every feature should compile.

Flutter Analyzer should report

0 Errors

0 Warnings

No deprecated APIs.

---

# Git Rules

Never change unrelated files.

Keep changes focused.

One feature per commit.

---

# Output Rules

After every implementation

Provide

1. Files created

2. Files modified

3. Folder structure

4. Explanation

5. Required packages

6. How to run

7. Analyzer status

8. Remaining TODOs

---

# DO NOT

Do not redesign UI.

Do not change architecture.

Do not create duplicate widgets.

Do not create duplicate services.

Do not create duplicate repositories.

Do not modify unrelated files.

Do not implement future phases.

Do not remove existing functionality.

Do not use placeholder architecture.

Do not leave TODO comments unless requested.

---

# Always

Write production-quality code.

Write readable code.

Write scalable code.

Write reusable code.

Keep the project maintainable.

Maintain visual consistency.

Follow Flutter best practices.

Build only what is requested.
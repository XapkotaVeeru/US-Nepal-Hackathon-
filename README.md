# US-Nepal-Hackathon-

Serenity is a Flutter-based mental-health support app built for the US-Nepal Hackathon. It is designed to give people a safer, more approachable way to reflect on their emotional state, journal privately, discover peer communities, and talk anonymously with others who may understand similar experiences.

The app combines a local-first mobile experience with an AWS-backed realtime and AI-assisted backend. On the client side, users can track moods, write journal entries, view personal insights, and use voice-assisted check-ins. On the backend side, the project includes Terraform infrastructure and AWS Lambda handlers for posting, matching, communities, messaging, and WebSocket chat.

Important: this project is a peer-support tool, not a replacement for professional medical care, therapy, or emergency services.

## Contents

- [Overview](#overview)
- [Core Features](#core-features)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [App Architecture](#app-architecture)
- [Local Persistence](#local-persistence)
- [AWS Backend](#aws-backend)
- [Getting Started](#getting-started)
- [Run the App](#run-the-app)
- [Terraform and AWS Setup](#terraform-and-aws-setup)
- [Development Workflow](#development-workflow)
- [Troubleshooting](#troubleshooting)
- [Roadmap Ideas](#roadmap-ideas)
- [Disclaimer](#disclaimer)

## Overview

This repo contains:

- A Flutter app for anonymous peer support and self-reflection.
- Local mood tracking and journaling persistence using `Provider` and `shared_preferences`.
- Insights built from real locally saved user data.
- Voice-assisted emotional check-ins using speech-to-text and a sentiment-analysis service layer.
- WebSocket-enabled chat flows and community messaging.
- AWS infrastructure as code using Terraform.
- Lambda functions that support community discovery, message flows, risk classification, and realtime chat.

The current implementation intentionally favors a local-first user experience for mood tracking and journaling so the app remains functional even before backend sync is introduced for those features.

## Core Features

### Anonymous support experience

- Anonymous user profile bootstrapping.
- Community discovery and joining.
- Group and peer-support oriented chat UI.
- Realtime messaging via WebSocket-backed infrastructure.

### Emotional wellness features

- Mood tracking with one local check-in per day.
- Optional notes attached to each mood entry.
- Voice-assisted mood and chat check-ins.
- Journaling with prompts and locally saved entries.
- Insights based on real saved mood and journal data.

### AI-assisted flows

- Voice sentiment analysis pipeline through `EmotionService`.
- Routing users toward relevant support groups based on emotional context.
- Rule-based supportive chatbot replies in chat.
- Risk-aware flow that can escalate to crisis-oriented messaging.

### Infrastructure and backend

- AWS API Gateway for HTTP and WebSocket access.
- AWS Lambda functions for app workflows.
- DynamoDB tables for backend data.
- Cognito identity configuration.
- CloudWatch, EventBridge, ECS, S3, SNS/FCM, and VPC modules via Terraform.

## Tech Stack

### Frontend

- Flutter
- Dart
- Provider
- shared_preferences
- fl_chart
- speech_to_text
- permission_handler
- web_socket_channel
- http

### Backend and Infrastructure

- AWS Lambda
- API Gateway (HTTP + WebSocket)
- DynamoDB
- Cognito
- S3
- ECS Fargate
- EventBridge
- CloudWatch
- Terraform

## Repository Structure

```text
.
├── android/                   # Android host project
├── ios/                       # iOS host project
├── lambda/                    # AWS Lambda handlers
│   ├── classify_risk/
│   ├── create_post/
│   ├── discover_communities/
│   ├── get_messages/
│   ├── join_community/
│   ├── match_users/
│   ├── send_message/
│   ├── ws_connect/
│   ├── ws_default/
│   └── ws_disconnect/
├── lib/
│   ├── config/                # App config such as AWS endpoints
│   ├── models/                # App data models
│   ├── providers/             # Provider-based state management
│   ├── screens/               # UI screens
│   ├── services/              # App services and local utilities
│   └── widgets/               # Reusable widgets
├── terraform/
│   ├── main.tf                # Root Terraform entrypoint
│   ├── outputs.tf
│   ├── providers.tf
│   ├── variables.tf
│   └── modules/               # Infrastructure modules
├── docs/
│   └── aws-backend-audit-runbook.md
├── pubspec.yaml
└── README.md
```

## App Architecture

The Flutter app uses a fairly standard layered structure:

- `models/` define serializable app data.
- `services/` handle integration concerns such as APIs, speech recognition, anonymous identity, and sentiment-analysis logic.
- `providers/` manage app state and coordinate UI with persistence or services.
- `screens/` render the app experience.
- `widgets/` hold shared UI components.

### State management

The app uses `Provider` and `ChangeNotifier`.

Currently registered app-level providers include:

- `AppStateProvider`
- `PostProvider`
- `ChatProvider`
- `NotificationProvider`
- `CommunityProvider`
- `MoodProvider`
- `JournalProvider`

### Design approach

The UI uses a calm, soft visual language centered around the `AppColors` palette defined in `lib/main.dart`. Both light and dark themes are supported.

## Local Persistence

Mood tracking and journaling are currently local-first.

### Mood data

Persisted in local storage:

- mood value
- note
- created timestamp
- one-entry-per-day behavior enforced in provider logic

Implemented through:

- `lib/models/mood_entry_model.dart`
- `lib/providers/mood_provider.dart`
- `lib/screens/mood_tracking_screen.dart`

### Journal data

Persisted in local storage:

- title
- content
- optional prompt
- created timestamp

Implemented through:

- `lib/models/journal_entry_model.dart`
- `lib/providers/journal_provider.dart`
- `lib/screens/journaling_screen.dart`

### Insights

The Insights screen now computes real values from local persisted data where available:

- total journal entries
- total mood check-ins
- current streak
- weekly mood trend
- mood distribution
- latest mood/journal summaries

## AWS Backend

The repo also contains an AWS backend defined with Terraform and Lambda handlers.

### Config

The mobile app reads AWS settings from:

- `lib/config/aws_config.dart`

This file currently stores values such as:

- AWS region
- HTTP API base URL
- WebSocket URL
- Cognito identity pool ID
- media bucket name
- ALB DNS name

If infrastructure changes after `terraform apply`, these values should be updated accordingly.

### Terraform modules

The backend is composed from modular Terraform components:

- `vpc`
- `s3`
- `dynamodb`
- `iam`
- `bedrock_iam`
- `sns_fcm`
- `cognito`
- `lambda`
- `api_gateway`
- `ecs`
- `eventbridge`
- `cloudwatch`

### Lambda handlers

Current Lambda directories include:

- `classify_risk`
- `create_post`
- `discover_communities`
- `get_messages`
- `join_community`
- `match_users`
- `send_message`
- `ws_connect`
- `ws_default`
- `ws_disconnect`

These support risk analysis, community flows, posting, matching, messaging, and realtime chat events.

## Getting Started

### Prerequisites

Install:

- Flutter SDK
- Dart SDK
- Android Studio or Xcode as needed for your target platform
- An emulator/simulator or physical device

Useful checks:

```bash
flutter --version
flutter doctor
```

### Install dependencies

```bash
flutter pub get
```

## Run the App

### Standard run

```bash
flutter run
```

### Run with hot reload

Once the app is running:

- press `r` in the terminal for hot reload
- press `R` for hot restart

You usually do not need to stop and re-run the app for normal Dart/UI changes.

### Helpful verification

```bash
dart analyze
```

or

```bash
flutter analyze
```

## Terraform and AWS Setup

The infrastructure lives under `terraform/`.

### Typical workflow

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Important notes

- Review `terraform/terraform.tfvars` before applying changes.
- Do not commit secrets or sensitive environment-specific values.
- After provisioning changes, update `lib/config/aws_config.dart` if outputs have changed.
- Check `docs/aws-backend-audit-runbook.md` for operational context around the backend.

## Development Workflow

### Recommended local loop

```bash
flutter pub get
dart analyze
flutter run
```

### Coding conventions used in this repo

- Null-safe Dart
- Provider-based state management
- Service/provider separation for business logic
- Local-first implementation where backend sync is not finalized
- UI preserved close to the project’s existing style

### When adding features

Prefer this general pattern:

1. Add or extend a model.
2. Add provider/service logic.
3. Update the screen to consume provider state.
4. Keep persistence and API concerns out of the widget layer where possible.
5. Run static analysis before committing.

## Troubleshooting

### `flutter run` does not reflect changes

- Use hot reload with `r`.
- Use hot restart with `R` if widget tree state is stuck.
- Fully restart only when dependencies or native configuration changed.

### Voice features do not work

Check:

- microphone permission on the device
- `permission_handler` integration
- `speech_to_text` platform setup
- Android and iOS microphone permission declarations

### Backend requests fail

Check:

- `lib/config/aws_config.dart`
- whether the Terraform stack is deployed
- whether the API Gateway URLs are current
- whether the required Lambda functions and permissions exist

### New Dart files are not showing up in git

The root `.gitignore` previously excluded parts of `lib/`. That has been cleaned up so source files under `lib/` should now be trackable normally.

## Roadmap Ideas

Some natural next steps for the project:

- Sync mood and journal data to backend per anonymous user
- Replace the local/rule-based chat assistant with a backend AI workflow
- Add authentication/session export improvements
- Add tests for providers and serialization models
- Improve crisis escalation with richer safety workflows
- Add media upload or attachment support
- Add analytics dashboards for moderators or community health

## Disclaimer

This project is intended for peer support and self-reflection. It is not a medical device and should not be relied on as a substitute for professional diagnosis, therapy, treatment, or emergency response.

If a user is in immediate danger or crisis, they should contact local emergency services or an appropriate crisis hotline immediately.

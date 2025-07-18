# Sequence API Client

A third party app for intereacting with [Sequnce's](https://getsequence.io) API.

Not affiliated with Sequence, just a user.

## Requirements
You must have API access enabled on your account, if you do not have it then reach out to Sequence support to enable access!

## Features
- Query Account Balances
- save api rule trigger path and secrets
- run histroy for rules

## Running Rules
when you first setup your rule, you'll need the Ruleid, this is part of the path you receive when setting up the rule in sequence specifically the value between ``/rules/`` and ``/trigger``. just copy and paste that value into the ruleid field.

## Screenshots (coming soon)

|Accounts|Rules|History|
|--|--|--|
|![alt](https://github.com/deathblade666/sequence_api_client/blob/b255a54c600fabc4506bf9492b39eefa9dbf8816/screenshots/Screenshot%20From%202025-07-18%2015-17-32.png)|![alt](https://github.com/deathblade666/sequence_api_client/blob/b255a54c600fabc4506bf9492b39eefa9dbf8816/screenshots/Screenshot%20From%202025-07-18%2015-18-44.png)|![alt](https://github.com/deathblade666/sequence_api_client/blob/b255a54c600fabc4506bf9492b39eefa9dbf8816/screenshots/Screenshot%20From%202025-07-18%2015-18-54.png)|

|Settings|Rule Settings|Edit Rules|
|--|--|--|
|![alt](https://github.com/deathblade666/sequence_api_client/blob/b255a54c600fabc4506bf9492b39eefa9dbf8816/screenshots/Screenshot%20From%202025-07-18%2015-18-14.png)|![alt](https://github.com/deathblade666/sequence_api_client/blob/b255a54c600fabc4506bf9492b39eefa9dbf8816/screenshots/Screenshot%20From%202025-07-18%2015-18-02.png)|![alt](https://github.com/deathblade666/sequence_api_client/blob/b1ec15901fac05a82d58f7300bd76113268dd0e7/screenshots/Screenshot%20From%202025-07-18%2015-25-56.png)|

## Build
1. Setup a Flutter dev env
2. Clone this repo
3. cd into where you cloned the repo
4. run ``flutter pub get``
5. then ``flutter build <platform>``

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Firestore Setup

## Goal
Generate a Firebase Admin SDK seed script based on the schema spec and dummy data.

## Rules
- Firestore is document-based, not SQL schema-based.
- Use collection names exactly as defined.
- Use documentId from schema spec for document IDs.
- Convert ISO timestamp strings to Firestore Timestamp where needed.
- Do not rename fields unless necessary.
- Keep this structure compatible with a future Swift app using Firebase.
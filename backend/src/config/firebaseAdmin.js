const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

let initialized = false;

function initFirebaseAdmin() {
  if (initialized || admin.apps.length > 0) {
    return admin;
  }

  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id,
      });
      console.log('[FirebaseAdmin] Initialized via FIREBASE_SERVICE_ACCOUNT_JSON');
    } else if (
      process.env.GOOGLE_APPLICATION_CREDENTIALS &&
      fs.existsSync(path.resolve(process.env.GOOGLE_APPLICATION_CREDENTIALS))
    ) {
      let credPath = path.resolve(process.env.GOOGLE_APPLICATION_CREDENTIALS);
      if (fs.statSync(credPath).isDirectory()) {
        const jsonFiles = fs.readdirSync(credPath).filter((file) => file.endsWith('.json'));
        if (jsonFiles.length > 0) {
          credPath = path.join(credPath, jsonFiles[0]);
        }
      }
      const serviceAccount = JSON.parse(fs.readFileSync(credPath, 'utf8'));
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id,
      });
      console.log(`[FirebaseAdmin] Initialized using credentials file at ${credPath}`);
    } else if (process.env.FIREBASE_PROJECT_ID) {
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
        projectId: process.env.FIREBASE_PROJECT_ID,
      });
      console.log(`[FirebaseAdmin] Initialized using ADC for project: ${process.env.FIREBASE_PROJECT_ID}`);
    } else {
      // Fallback for development/testing when keys are not yet provided
      admin.initializeApp({
        projectId: 'personal-expense-tracker-dev',
      });
      console.warn('[FirebaseAdmin] Initialized with default project. Please configure GOOGLE_APPLICATION_CREDENTIALS in .env for production.');
    }
    initialized = true;
  } catch (error) {
    console.error(`[FirebaseAdmin] Initialization warning: ${error.message}`);
  }

  return admin;
}

const firebaseAdmin = initFirebaseAdmin();

module.exports = firebaseAdmin;

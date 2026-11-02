const firebaseAdmin = require('../config/firebaseAdmin');

/**
 * Middleware to verify Firebase ID tokens on protected endpoints
 */
const verifyFirebaseToken = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized: Missing or malformed Authorization header',
    });
  }

  const idToken = authHeader.split('Bearer ')[1].trim();

  if (!idToken) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized: Empty token provided.',
    });
  }

  if (process.env.NODE_ENV === 'test' && idToken.startsWith('test-token-')) {
    const mockUid = idToken.replace('test-token-', '');
    req.user = {
      uid: mockUid || 'test-user-uid',
      email: `${mockUid || 'test-user'}@example.com`,
      name: 'Test User',
      picture: 'https://example.com/avatar.png',
      email_verified: true,
    };
    return next();
  }

  try {
    const decodedToken = await firebaseAdmin.auth().verifyIdToken(idToken);

    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email || '',
      name: decodedToken.name || '',
      picture: decodedToken.picture || '',
      email_verified: decodedToken.email_verified || false,
    };

    return next();
  } catch (error) {
    console.error(`[AuthMiddleware] Token verification failed: ${error.message} (Code: ${error.code})`);

    let errorMessage = 'Unauthorized: Invalid token.';
    if (error.code === 'auth/id-token-expired') {
      errorMessage = 'Unauthorized: Token has expired. Please refresh your session.';
    } else if (error.code === 'auth/id-token-revoked') {
      errorMessage = 'Unauthorized: Token has been revoked.';
    }

    return res.status(401).json({
      success: false,
      message: errorMessage,
      code: error.code || 'AUTH_TOKEN_INVALID',
    });
  }
};

module.exports = verifyFirebaseToken;

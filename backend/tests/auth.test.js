const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../src/app');
const User = require('../src/models/User');
const { Category } = require('../src/models/Category');

beforeAll(async () => {
  const mongoUri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/personal_expense_tracker_test';
  await mongoose.connect(mongoUri);
  await User.deleteMany({ firebaseUid: { $regex: /^test-/ } });
  await Category.deleteMany({ firebaseUid: { $regex: /^test-/ } });
});

afterAll(async () => {
  await User.deleteMany({ firebaseUid: { $regex: /^test-/ } });
  await Category.deleteMany({ firebaseUid: { $regex: /^test-/ } });
  await mongoose.disconnect();
});

describe('Authentication & Profile Sync API', () => {
  const testUid = 'test-uid-auth-001';
  const testToken = 'test-token-test-uid-auth-001';

  it('should return 401 when Authorization header is missing', async () => {
    const res = await request(app).get('/api/v1/auth/me');
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/Missing or malformed Authorization header/);
  });

  it('should return 401 when Authorization header is malformed', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', 'Basic 123456');
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('should synchronize verified Firebase user profile and seed default categories', async () => {
    const res = await request(app)
      .post('/api/v1/auth/sync')
      .set('Authorization', `Bearer ${testToken}`)
      .send({
        name: 'Alice Developer',
        photoURL: 'https://example.com/avatar.jpg',
        preferredCurrency: 'USD',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.firebaseUid).toBe(testUid);
    expect(res.body.data.name).toBe('Alice Developer');

    const categories = await Category.find({ firebaseUid: testUid });
    expect(categories.length).toBeGreaterThan(0);
  });

  it('should prevent duplicate user profile records when re-syncing', async () => {
    const res = await request(app)
      .post('/api/v1/auth/sync')
      .set('Authorization', `Bearer ${testToken}`)
      .send({
        name: 'Alice Updated',
      });

    expect(res.status).toBe(200);
    expect(res.body.data.name).toBe('Alice Updated');

    const userCount = await User.countDocuments({ firebaseUid: testUid });
    expect(userCount).toBe(1);
  });

  it('should return verified profile on GET /auth/me', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${testToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.firebaseUid).toBe(testUid);
  });
});

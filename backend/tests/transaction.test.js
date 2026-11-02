const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../src/app');
const User = require('../src/models/User');
const { Category } = require('../src/models/Category');
const Transaction = require('../src/models/Transaction');

beforeAll(async () => {
  const mongoUri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/personal_expense_tracker_test';
  await mongoose.connect(mongoUri);
});

afterAll(async () => {
  await User.deleteMany({ firebaseUid: { $regex: /^test-/ } });
  await Category.deleteMany({ firebaseUid: { $regex: /^test-/ } });
  await Transaction.deleteMany({ firebaseUid: { $regex: /^test-/ } });
  await mongoose.disconnect();
});

describe('Transaction API & User Data Isolation', () => {
  const user1Uid = 'test-tx-user-1';
  const user2Uid = 'test-tx-user-2';
  const tokenUser1 = `Bearer test-token-${user1Uid}`;
  const tokenUser2 = `Bearer test-token-${user2Uid}`;

  let user1ExpenseCat;
  let user1IncomeCat;
  let createdTransactionId;

  beforeAll(async () => {
    // Setup categories for User 1
    user1ExpenseCat = await Category.create({
      firebaseUid: user1Uid,
      name: 'Food & Drinks',
      type: 'expense',
      color: '#EF4444',
    });

    user1IncomeCat = await Category.create({
      firebaseUid: user1Uid,
      name: 'Salary',
      type: 'income',
      color: '#10B981',
    });
  });

  it('should create an expense transaction for user 1', async () => {
    const res = await request(app)
      .post('/api/v1/transactions')
      .set('Authorization', tokenUser1)
      .send({
        type: 'expense',
        amountMinor: 2500, // $25.00
        currency: 'USD',
        categoryId: user1ExpenseCat._id.toString(),
        description: 'Lunch at Cafe',
        paymentMethod: 'Cash',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.amountMinor).toBe(2500);
    expect(res.body.data.firebaseUid).toBe(user1Uid);
    createdTransactionId = res.body.data._id;
  });

  it('should reject invalid amountMinor (negative or non-integer)', async () => {
    const res = await request(app)
      .post('/api/v1/transactions')
      .set('Authorization', tokenUser1)
      .send({
        type: 'expense',
        amountMinor: -50,
        categoryId: user1ExpenseCat._id.toString(),
        description: 'Negative test',
      });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('should enforce user data isolation: User 2 cannot see or access User 1 transaction', async () => {
    // User 2 lists transactions
    const listRes = await request(app)
      .get('/api/v1/transactions')
      .set('Authorization', tokenUser2);

    expect(listRes.status).toBe(200);
    expect(listRes.body.data.length).toBe(0);

    // User 2 attempts to get User 1 transaction by ID
    const getRes = await request(app)
      .get(`/api/v1/transactions/${createdTransactionId}`)
      .set('Authorization', tokenUser2);

    expect(getRes.status).toBe(404);
  });

  it('should return 400 for invalid MongoDB document ID', async () => {
    const res = await request(app)
      .get('/api/v1/transactions/not-a-valid-id')
      .set('Authorization', tokenUser1);

    expect(res.status).toBe(400);
  });

  it('should update a transaction for user 1', async () => {
    const res = await request(app)
      .put(`/api/v1/transactions/${createdTransactionId}`)
      .set('Authorization', tokenUser1)
      .send({
        description: 'Deluxe Lunch at Cafe',
        amountMinor: 3000,
      });

    expect(res.status).toBe(200);
    expect(res.body.data.description).toBe('Deluxe Lunch at Cafe');
    expect(res.body.data.amountMinor).toBe(3000);
  });

  it('should delete a transaction for user 1', async () => {
    const res = await request(app)
      .delete(`/api/v1/transactions/${createdTransactionId}`)
      .set('Authorization', tokenUser1);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});

const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../src/app');
const { Category } = require('../src/models/Category');
const Transaction = require('../src/models/Transaction');

beforeAll(async () => {
  const mongoUri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/personal_expense_tracker_test';
  await mongoose.connect(mongoUri);
});

afterAll(async () => {
  await Category.deleteMany({ firebaseUid: { $regex: /^test-analytics-/ } });
  await Transaction.deleteMany({ firebaseUid: { $regex: /^test-analytics-/ } });
  await mongoose.disconnect();
});

describe('Analytics Calculations API', () => {
  const userUid = 'test-analytics-user-1';
  const token = `Bearer test-token-${userUid}`;

  beforeAll(async () => {
    const salaryCat = await Category.create({
      firebaseUid: userUid,
      name: 'Salary',
      type: 'income',
      color: '#10B981',
    });
    const billsCat = await Category.create({
      firebaseUid: userUid,
      name: 'Bills',
      type: 'expense',
      color: '#EF4444',
    });

    // Income $3000 (300000 minor)
    await Transaction.create({
      firebaseUid: userUid,
      type: 'income',
      amountMinor: 300000,
      currency: 'USD',
      categoryId: salaryCat._id,
      description: 'Monthly Salary',
      transactionDate: new Date(),
    });

    // Expense $1000 (100000 minor)
    await Transaction.create({
      firebaseUid: userUid,
      type: 'expense',
      amountMinor: 100000,
      currency: 'USD',
      categoryId: billsCat._id,
      description: 'Apartment Rent',
      transactionDate: new Date(),
    });
  });

  it('should calculate accurate balance = income - expense on GET /analytics/summary', async () => {
    const res = await request(app)
      .get('/api/v1/analytics/summary')
      .set('Authorization', token);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.totalIncomeMinor).toBe(300000);
    expect(res.body.data.totalExpenseMinor).toBe(100000);
    expect(res.body.data.totalBalanceMinor).toBe(200000); // 300000 - 100000 = 200000 ($2,000.00)
  });

  it('should return monthly breakdown and category breakdown', async () => {
    const monthlyRes = await request(app)
      .get('/api/v1/analytics/monthly?months=3')
      .set('Authorization', token);
    expect(monthlyRes.status).toBe(200);
    expect(monthlyRes.body.data.length).toBe(3);

    const catRes = await request(app)
      .get('/api/v1/analytics/categories?type=expense')
      .set('Authorization', token);
    expect(catRes.status).toBe(200);
    expect(catRes.body.data.breakdown.length).toBeGreaterThan(0);
  });
});

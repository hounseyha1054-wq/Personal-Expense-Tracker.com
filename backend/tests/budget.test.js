const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../src/app');
const { Category } = require('../src/models/Category');
const Transaction = require('../src/models/Transaction');
const Budget = require('../src/models/Budget');

beforeAll(async () => {
  const mongoUri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/personal_expense_tracker_test';
  await mongoose.connect(mongoUri);
});

afterAll(async () => {
  await Category.deleteMany({ firebaseUid: { $regex: /^test-budget-/ } });
  await Transaction.deleteMany({ firebaseUid: { $regex: /^test-budget-/ } });
  await Budget.deleteMany({ firebaseUid: { $regex: /^test-budget-/ } });
  await mongoose.disconnect();
});

describe('Budget Calculations & Alert Thresholds', () => {
  const userUid = 'test-budget-user-1';
  const token = `Bearer test-token-${userUid}`;
  let category;
  const currentMonth = new Date().toISOString().slice(0, 7);

  beforeAll(async () => {
    category = await Category.create({
      firebaseUid: userUid,
      name: 'Groceries',
      type: 'expense',
      color: '#10B981',
    });

    // Create a transaction: spent $85 (8500 minor)
    await Transaction.create({
      firebaseUid: userUid,
      type: 'expense',
      amountMinor: 8500,
      currency: 'USD',
      categoryId: category._id,
      description: 'Supermarket Groceries',
      transactionDate: new Date(),
    });
  });

  it('should create a budget of $100 (10000 minor) and trigger 80% warning when spent is 8500', async () => {
    const createRes = await request(app)
      .post('/api/v1/budgets')
      .set('Authorization', token)
      .send({
        categoryId: category._id.toString(),
        amountMinor: 10000,
        currency: 'USD',
        month: currentMonth,
      });

    expect(createRes.status).toBe(201);
    expect(createRes.body.data.amountMinor).toBe(10000);

    // List budgets to verify calculation from transactions
    const listRes = await request(app)
      .get(`/api/v1/budgets?month=${currentMonth}`)
      .set('Authorization', token);

    expect(listRes.status).toBe(200);
    const budgetItem = listRes.body.data.budgets[0];
    expect(budgetItem.spentMinor).toBe(8500);
    expect(budgetItem.remainingMinor).toBe(1500);
    expect(budgetItem.percentageUsed).toBe(85);
    expect(budgetItem.isWarning).toBe(true);
    expect(budgetItem.isOverBudget).toBe(false);
  });
});

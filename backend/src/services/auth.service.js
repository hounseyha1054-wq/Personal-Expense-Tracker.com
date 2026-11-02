const User = require('../models/User');
const { Category, DEFAULT_EXPENSE_CATEGORIES, DEFAULT_INCOME_CATEGORIES } = require('../models/Category');

class AuthService {
  /**
   * Synchronize verified Firebase user with MongoDB.
   * Creates record if not exists, updates name/photoURL if provided,
   * and initializes default user categories if first-time user.
   */
  async syncUser(firebaseUser, bodyData = {}) {
    const { uid, email, name: tokenName, picture } = firebaseUser;
    const name = bodyData.name || tokenName || '';
    const photoURL = bodyData.photoURL || picture || '';

    let user = await User.findOne({ firebaseUid: uid });

    if (!user) {
      user = await User.create({
        firebaseUid: uid,
        email: email || '',
        name: name,
        photoURL: photoURL,
        preferredCurrency: bodyData.preferredCurrency || 'USD',
      });
      console.log(`[AuthService] New MongoDB user profile created for UID: ${uid}`);

      // Seed default categories for new user
      await this.seedDefaultCategories(uid);
    } else {
      // Update fields if changed
      let updated = false;
      if (name && name !== user.name) {
        user.name = name;
        updated = true;
      }
      if (photoURL && photoURL !== user.photoURL) {
        user.photoURL = photoURL;
        updated = true;
      }
      if (email && email !== user.email) {
        user.email = email;
        updated = true;
      }
      if (updated) {
        await user.save();
      }

      // Check if user has any categories; if not, seed them
      const categoryCount = await Category.countDocuments({ firebaseUid: uid });
      if (categoryCount === 0) {
        await this.seedDefaultCategories(uid);
      }
    }

    return user;
  }

  /**
   * Seed default categories for a specific user
   */
  async seedDefaultCategories(firebaseUid) {
    const categoriesToInsert = [
      ...DEFAULT_EXPENSE_CATEGORIES.map((c) => ({ ...c, firebaseUid })),
      ...DEFAULT_INCOME_CATEGORIES.map((c) => ({ ...c, firebaseUid })),
    ];
    await Category.insertMany(categoriesToInsert, { ordered: false }).catch((err) => {
      // Ignore duplicates if any existed
      console.warn(`[AuthService] Seed categories notice: ${err.message}`);
    });
    console.log(`[AuthService] Seeded default categories for UID: ${firebaseUid}`);
  }

  /**
   * Get user profile by Firebase UID
   */
  async getUserProfile(firebaseUid) {
    const user = await User.findOne({ firebaseUid });
    return user;
  }
}

module.exports = new AuthService();

const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure upload directory exists
const uploadDir = path.resolve(__dirname, '../../uploads/avatars');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Storage configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const safeExt = ['.jpg', '.jpeg', '.png', '.webp'].includes(ext) ? ext : '.jpg';
    const userId = req.user?.uid ? req.user.uid.replace(/[^a-zA-Z0-9_-]/g, '') : 'anon';
    cb(null, `avatar-${userId}-${Date.now()}${safeExt}`);
  },
});

// File filter: accept images (check mime type or valid extension)
const fileFilter = (req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();
  const validExts = ['.jpg', '.jpeg', '.png', '.webp'];
  const mime = (file.mimetype || '').toLowerCase();
  const isImageMime = mime.startsWith('image/') || mime === 'application/octet-stream';
  const isImageExt = validExts.includes(ext);

  if (isImageExt || isImageMime) {
    cb(null, true);
  } else {
    cb(new Error('Invalid image type. Only JPEG, PNG, and WebP are allowed.'), false);
  }
};

const uploadAvatar = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter,
});

module.exports = uploadAvatar;


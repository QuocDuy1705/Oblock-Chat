const express = require('express');
const router = express.Router();
const {
  updateProfile,
  uploadAvatar,
  searchUsers,
  getUserById
} = require('../controllers/userController');
const { protect } = require('../middleware/auth');
const upload = require('../middleware/upload');

router.put('/profile', protect, updateProfile);
router.post('/avatar', protect, upload.single('avatar'), uploadAvatar);
router.get('/search', protect, searchUsers);
router.get('/:userId', protect, getUserById);

module.exports = router;

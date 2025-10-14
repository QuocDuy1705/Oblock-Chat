const express = require('express');
const router = express.Router();
const {
  getConversations,
  createDirectConversation,
  createGroupConversation,
  addGroupMembers,
  getConversationById
} = require('../controllers/conversationController');
const { protect } = require('../middleware/auth');

router.get('/', protect, getConversations);
router.post('/direct/:userId', protect, createDirectConversation);
router.post('/group', protect, createGroupConversation);
router.post('/:conversationId/members', protect, addGroupMembers);
router.get('/:conversationId', protect, getConversationById);

module.exports = router;

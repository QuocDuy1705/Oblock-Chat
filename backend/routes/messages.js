const express = require('express');
const router = express.Router();
const {
  getMessages,
  sendMessage,
  markMessagesAsSeen,
  addReaction,
  removeReaction,
  editMessage,
  deleteMessage
} = require('../controllers/messageController');
const { protect } = require('../middleware/auth');
const upload = require('../middleware/upload');

// Conversation messages routes
router.get('/conversations/:conversationId/messages', protect, getMessages);
router.post('/conversations/:conversationId/messages', protect, upload.single('messageFile'), sendMessage);
router.put('/conversations/:conversationId/messages/seen', protect, markMessagesAsSeen);

// Individual message routes
router.post('/messages/:messageId/reactions', protect, addReaction);
router.delete('/messages/:messageId/reactions/:emoji', protect, removeReaction);
router.put('/messages/:messageId', protect, editMessage);
router.delete('/messages/:messageId', protect, deleteMessage);

module.exports = router;

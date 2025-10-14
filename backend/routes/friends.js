const express = require('express');
const router = express.Router();
const {
  sendFriendRequest,
  getFriendRequests,
  acceptFriendRequest,
  declineFriendRequest,
  getFriends,
  removeFriend
} = require('../controllers/friendController');
const { protect } = require('../middleware/auth');

router.post('/request/:userId', protect, sendFriendRequest);
router.get('/requests', protect, getFriendRequests);
router.put('/request/:requestId/accept', protect, acceptFriendRequest);
router.put('/request/:requestId/decline', protect, declineFriendRequest);
router.get('/', protect, getFriends);
router.delete('/:userId', protect, removeFriend);

module.exports = router;

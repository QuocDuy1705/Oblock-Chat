const FriendRequest = require('../models/FriendRequest');
const Friend = require('../models/Friend');
const User = require('../models/User');

// @desc    Send friend request
// @route   POST /api/friends/request/:userId
// @access  Private
exports.sendFriendRequest = async (req, res) => {
  try {
    const { userId } = req.params;
    const { message } = req.body;

    // Check if trying to add self
    if (userId === req.user._id.toString()) {
      return res.status(400).json({
        success: false,
        message: 'Cannot send friend request to yourself'
      });
    }

    // Check if user exists
    const toUser = await User.findById(userId);
    if (!toUser) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if already friends
    const existingFriendship = await Friend.findOne({
      $or: [
        { userA: req.user._id, userB: userId },
        { userA: userId, userB: req.user._id }
      ]
    });

    if (existingFriendship) {
      return res.status(400).json({
        success: false,
        message: 'You are already friends with this user'
      });
    }

    // Check if request already exists
    const existingRequest = await FriendRequest.findOne({
      from: req.user._id,
      to: userId,
      status: 'pending'
    });

    if (existingRequest) {
      return res.status(400).json({
        success: false,
        message: 'Friend request already sent'
      });
    }

    // Create friend request
    const friendRequest = await FriendRequest.create({
      from: req.user._id,
      to: userId,
      message: message || ''
    });

    await friendRequest.populate('from', '-hashedPassword');
    await friendRequest.populate('to', '-hashedPassword');

    res.status(201).json({
      success: true,
      message: 'Friend request sent successfully',
      friendRequest
    });
  } catch (error) {
    console.error('Send friend request error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Get pending friend requests (received)
// @route   GET /api/friends/requests
// @access  Private
exports.getFriendRequests = async (req, res) => {
  try {
    const requests = await FriendRequest.find({
      to: req.user._id,
      status: 'pending'
    })
    .populate('from', '-hashedPassword')
    .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      requests
    });
  } catch (error) {
    console.error('Get friend requests error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Accept friend request
// @route   PUT /api/friends/request/:requestId/accept
// @access  Private
exports.acceptFriendRequest = async (req, res) => {
  try {
    const { requestId } = req.params;

    const friendRequest = await FriendRequest.findById(requestId);

    if (!friendRequest) {
      return res.status(404).json({
        success: false,
        message: 'Friend request not found'
      });
    }

    // Check if request is for current user
    if (friendRequest.to.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to accept this request'
      });
    }

    // Check if already accepted
    if (friendRequest.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Friend request already processed'
      });
    }

    // Update request status
    friendRequest.status = 'accepted';
    await friendRequest.save();

    // Create friendship (ensure userA < userB for consistency)
    const [userA, userB] = [friendRequest.from, friendRequest.to].sort();
    await Friend.create({
      userA,
      userB
    });

    res.status(200).json({
      success: true,
      message: 'Friend request accepted',
      friendRequest
    });
  } catch (error) {
    console.error('Accept friend request error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Decline friend request
// @route   PUT /api/friends/request/:requestId/decline
// @access  Private
exports.declineFriendRequest = async (req, res) => {
  try {
    const { requestId } = req.params;

    const friendRequest = await FriendRequest.findById(requestId);

    if (!friendRequest) {
      return res.status(404).json({
        success: false,
        message: 'Friend request not found'
      });
    }

    // Check if request is for current user
    if (friendRequest.to.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to decline this request'
      });
    }

    // Update request status
    friendRequest.status = 'declined';
    await friendRequest.save();

    res.status(200).json({
      success: true,
      message: 'Friend request declined',
      friendRequest
    });
  } catch (error) {
    console.error('Decline friend request error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Get friends list
// @route   GET /api/friends
// @access  Private
exports.getFriends = async (req, res) => {
  try {
    const friendships = await Friend.find({
      $or: [
        { userA: req.user._id },
        { userB: req.user._id }
      ]
    })
    .populate('userA', '-hashedPassword')
    .populate('userB', '-hashedPassword');

    // Extract friend user objects
    const friends = friendships.map(friendship => {
      const friend = friendship.userA._id.toString() === req.user._id.toString() 
        ? friendship.userB 
        : friendship.userA;
      return friend.toPublicProfile();
    });

    res.status(200).json({
      success: true,
      friends
    });
  } catch (error) {
    console.error('Get friends error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Remove friend
// @route   DELETE /api/friends/:userId
// @access  Private
exports.removeFriend = async (req, res) => {
  try {
    const { userId } = req.params;

    const friendship = await Friend.findOneAndDelete({
      $or: [
        { userA: req.user._id, userB: userId },
        { userA: userId, userB: req.user._id }
      ]
    });

    if (!friendship) {
      return res.status(404).json({
        success: false,
        message: 'Friendship not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Friend removed successfully'
    });
  } catch (error) {
    console.error('Remove friend error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

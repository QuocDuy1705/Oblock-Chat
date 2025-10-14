const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const User = require('../models/User');

// @desc    Get all conversations for user
// @route   GET /api/conversations
// @access  Private
exports.getConversations = async (req, res) => {
  try {
    const conversations = await Conversation.find({
      participants: req.user._id
    })
    .populate('participants', '-hashedPassword')
    .populate('lastMessage.sender', '-hashedPassword')
    .sort({ updatedAt: -1 });

    // Transform conversations for response
    const conversationsData = conversations.map(conv => {
      const convObj = conv.toObject();
      
      // Get unread count for current user
      const unreadCount = conv.unreadCounts.get(req.user._id.toString()) || 0;
      
      return {
        ...convObj,
        unreadCount,
        participants: convObj.participants.map(p => ({
          id: p._id,
          username: p.username,
          displayName: p.displayName,
          avatarUrl: p.avatarUrl,
          isOnline: p.isOnline,
          lastSeen: p.lastSeen
        }))
      };
    });

    res.status(200).json({
      success: true,
      conversations: conversationsData
    });
  } catch (error) {
    console.error('Get conversations error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Create or get direct conversation
// @route   POST /api/conversations/direct/:userId
// @access  Private
exports.createDirectConversation = async (req, res) => {
  try {
    const { userId } = req.params;

    // Check if user exists
    const otherUser = await User.findById(userId);
    if (!otherUser) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if conversation already exists
    let conversation = await Conversation.findOne({
      isGroup: false,
      participants: { $all: [req.user._id, userId], $size: 2 }
    })
    .populate('participants', '-hashedPassword');

    if (!conversation) {
      // Create new conversation
      conversation = await Conversation.create({
        participants: [req.user._id, userId],
        isGroup: false
      });

      await conversation.populate('participants', '-hashedPassword');
    }

    res.status(200).json({
      success: true,
      conversation
    });
  } catch (error) {
    console.error('Create direct conversation error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Create group conversation
// @route   POST /api/conversations/group
// @access  Private
exports.createGroupConversation = async (req, res) => {
  try {
    const { participantIds, groupName } = req.body;

    if (!participantIds || !Array.isArray(participantIds) || participantIds.length < 2) {
      return res.status(400).json({
        success: false,
        message: 'At least 2 other participants are required for a group'
      });
    }

    if (!groupName || groupName.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Group name is required'
      });
    }

    // Include current user in participants
    const allParticipants = [req.user._id, ...participantIds];

    // Create group conversation
    const conversation = await Conversation.create({
      participants: allParticipants,
      isGroup: true,
      groupName: groupName.trim(),
      groupAdmin: req.user._id
    });

    await conversation.populate('participants', '-hashedPassword');

    res.status(201).json({
      success: true,
      message: 'Group conversation created successfully',
      conversation
    });
  } catch (error) {
    console.error('Create group conversation error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Add members to group
// @route   POST /api/conversations/:conversationId/members
// @access  Private
exports.addGroupMembers = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { userIds } = req.body;

    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'User IDs are required'
      });
    }

    const conversation = await Conversation.findById(conversationId);

    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found'
      });
    }

    if (!conversation.isGroup) {
      return res.status(400).json({
        success: false,
        message: 'Can only add members to group conversations'
      });
    }

    // Check if user is admin
    if (conversation.groupAdmin.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Only group admin can add members'
      });
    }

    // Add new members
    const newMembers = userIds.filter(id => 
      !conversation.participants.includes(id)
    );

    conversation.participants.push(...newMembers);
    await conversation.save();
    await conversation.populate('participants', '-hashedPassword');

    res.status(200).json({
      success: true,
      message: 'Members added successfully',
      conversation
    });
  } catch (error) {
    console.error('Add group members error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Get conversation by ID
// @route   GET /api/conversations/:conversationId
// @access  Private
exports.getConversationById = async (req, res) => {
  try {
    const conversation = await Conversation.findById(req.params.conversationId)
      .populate('participants', '-hashedPassword');

    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found'
      });
    }

    // Check if user is participant
    const isParticipant = conversation.participants.some(
      p => p._id.toString() === req.user._id.toString()
    );

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to view this conversation'
      });
    }

    res.status(200).json({
      success: true,
      conversation
    });
  } catch (error) {
    console.error('Get conversation error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

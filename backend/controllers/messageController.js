const Message = require('../models/Message');
const Conversation = require('../models/Conversation');

// @desc    Get messages for conversation with pagination
// @route   GET /api/conversations/:conversationId/messages?page=1&limit=50
// @access  Private
exports.getMessages = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const skip = (page - 1) * limit;

    // Check if user is participant
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found'
      });
    }

    const isParticipant = conversation.participants.some(
      p => p.toString() === req.user._id.toString()
    );

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to view these messages'
      });
    }

    // Get messages
    const messages = await Message.find({
      conversationId,
      isDeleted: false
    })
    .populate('senderId', '-hashedPassword')
    .populate('seenBy.user', '-hashedPassword')
    .populate('reactions.user', '-hashedPassword')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);

    const total = await Message.countDocuments({
      conversationId,
      isDeleted: false
    });

    res.status(200).json({
      success: true,
      messages: messages.reverse(), // Reverse to get chronological order
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Send message
// @route   POST /api/conversations/:conversationId/messages
// @access  Private
exports.sendMessage = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { content } = req.body;

    if (!content || content.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Message content is required'
      });
    }

    // Check if conversation exists and user is participant
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found'
      });
    }

    const isParticipant = conversation.participants.some(
      p => p.toString() === req.user._id.toString()
    );

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to send messages in this conversation'
      });
    }

    // Handle file upload if present
    let imgUrl = '';
    if (req.file) {
      imgUrl = `/uploads/messages/${req.file.filename}`;
    }

    // Create message
    const message = await Message.create({
      conversationId,
      senderId: req.user._id,
      content: content.trim(),
      imgUrl,
      seenBy: [{ user: req.user._id, seenAt: new Date() }]
    });

    await message.populate('senderId', '-hashedPassword');

    // Update conversation last message and unread counts
    const unreadCounts = {};
    conversation.participants.forEach(participantId => {
      const participantIdStr = participantId.toString();
      if (participantIdStr !== req.user._id.toString()) {
        const currentCount = conversation.unreadCounts.get(participantIdStr) || 0;
        unreadCounts[participantIdStr] = currentCount + 1;
      } else {
        unreadCounts[participantIdStr] = 0;
      }
    });

    conversation.lastMessage = {
      content: content.trim(),
      sender: req.user._id,
      createdAt: message.createdAt,
      imgUrl
    };
    conversation.unreadCounts = unreadCounts;
    await conversation.save();

    res.status(201).json({
      success: true,
      message
    });
  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Mark messages as seen
// @route   PUT /api/conversations/:conversationId/messages/seen
// @access  Private
exports.markMessagesAsSeen = async (req, res) => {
  try {
    const { conversationId } = req.params;

    // Update all messages in conversation not already seen by user
    await Message.updateMany(
      {
        conversationId,
        senderId: { $ne: req.user._id },
        'seenBy.user': { $ne: req.user._id }
      },
      {
        $push: {
          seenBy: {
            user: req.user._id,
            seenAt: new Date()
          }
        }
      }
    );

    // Reset unread count for this user
    const conversation = await Conversation.findById(conversationId);
    if (conversation) {
      conversation.unreadCounts.set(req.user._id.toString(), 0);
      await conversation.save();
    }

    res.status(200).json({
      success: true,
      message: 'Messages marked as seen'
    });
  } catch (error) {
    console.error('Mark messages as seen error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Add reaction to message
// @route   POST /api/messages/:messageId/reactions
// @access  Private
exports.addReaction = async (req, res) => {
  try {
    const { messageId } = req.params;
    const { emoji } = req.body;

    if (!emoji) {
      return res.status(400).json({
        success: false,
        message: 'Emoji is required'
      });
    }

    const message = await Message.findById(messageId);
    if (!message) {
      return res.status(404).json({
        success: false,
        message: 'Message not found'
      });
    }

    // Check if user already reacted with this emoji
    const existingReaction = message.reactions.find(
      r => r.user.toString() === req.user._id.toString() && r.emoji === emoji
    );

    if (existingReaction) {
      return res.status(400).json({
        success: false,
        message: 'You already reacted with this emoji'
      });
    }

    // Add reaction
    message.reactions.push({
      user: req.user._id,
      emoji
    });

    await message.save();
    await message.populate('reactions.user', '-hashedPassword');

    res.status(200).json({
      success: true,
      message: 'Reaction added successfully',
      reactions: message.reactions
    });
  } catch (error) {
    console.error('Add reaction error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Remove reaction from message
// @route   DELETE /api/messages/:messageId/reactions/:emoji
// @access  Private
exports.removeReaction = async (req, res) => {
  try {
    const { messageId, emoji } = req.params;

    const message = await Message.findById(messageId);
    if (!message) {
      return res.status(404).json({
        success: false,
        message: 'Message not found'
      });
    }

    // Remove reaction
    message.reactions = message.reactions.filter(
      r => !(r.user.toString() === req.user._id.toString() && r.emoji === emoji)
    );

    await message.save();

    res.status(200).json({
      success: true,
      message: 'Reaction removed successfully',
      reactions: message.reactions
    });
  } catch (error) {
    console.error('Remove reaction error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Edit message
// @route   PUT /api/messages/:messageId
// @access  Private
exports.editMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    const { content } = req.body;

    if (!content || content.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Message content is required'
      });
    }

    const message = await Message.findById(messageId);
    if (!message) {
      return res.status(404).json({
        success: false,
        message: 'Message not found'
      });
    }

    // Check if user is the sender
    if (message.senderId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to edit this message'
      });
    }

    if (message.isDeleted) {
      return res.status(400).json({
        success: false,
        message: 'Cannot edit deleted message'
      });
    }

    // Update message
    message.content = content.trim();
    message.isEdited = true;
    await message.save();
    await message.populate('senderId', '-hashedPassword');

    res.status(200).json({
      success: true,
      message: 'Message edited successfully',
      data: message
    });
  } catch (error) {
    console.error('Edit message error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Delete message
// @route   DELETE /api/messages/:messageId
// @access  Private
exports.deleteMessage = async (req, res) => {
  try {
    const { messageId } = req.params;

    const message = await Message.findById(messageId);
    if (!message) {
      return res.status(404).json({
        success: false,
        message: 'Message not found'
      });
    }

    // Check if user is the sender
    if (message.senderId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this message'
      });
    }

    // Soft delete
    message.isDeleted = true;
    message.content = 'This message has been deleted';
    await message.save();

    res.status(200).json({
      success: true,
      message: 'Message deleted successfully'
    });
  } catch (error) {
    console.error('Delete message error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

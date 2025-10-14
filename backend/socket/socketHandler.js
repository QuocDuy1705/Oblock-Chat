const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Message = require('../models/Message');
const Conversation = require('../models/Conversation');

// Store active connections: userId -> socketId
const userSockets = new Map();

const setupSocketHandlers = (io) => {
  // Middleware to authenticate socket connections
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      
      if (!token) {
        return next(new Error('Authentication error'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.id).select('-hashedPassword');
      
      if (!user) {
        return next(new Error('User not found'));
      }

      socket.userId = user._id.toString();
      socket.user = user;
      next();
    } catch (error) {
      next(new Error('Authentication error'));
    }
  });

  io.on('connection', async (socket) => {
    console.log(`User connected: ${socket.userId}`);

    // Store socket connection
    userSockets.set(socket.userId, socket.id);

    // Update user online status
    await User.findByIdAndUpdate(socket.userId, {
      isOnline: true,
      lastSeen: new Date()
    });

    // Emit online status to friends
    io.emit('user:online', { userId: socket.userId, isOnline: true });

    // Join user to their conversation rooms
    const conversations = await Conversation.find({
      participants: socket.userId
    });
    
    conversations.forEach(conv => {
      socket.join(`conversation:${conv._id}`);
    });

    // Handle joining a conversation room
    socket.on('conversation:join', (conversationId) => {
      socket.join(`conversation:${conversationId}`);
      console.log(`User ${socket.userId} joined conversation ${conversationId}`);
    });

    // Handle leaving a conversation room
    socket.on('conversation:leave', (conversationId) => {
      socket.leave(`conversation:${conversationId}`);
      console.log(`User ${socket.userId} left conversation ${conversationId}`);
    });

    // Handle new message (real-time)
    socket.on('message:send', async (data) => {
      try {
        const { conversationId, content, imgUrl } = data;

        // Verify user is participant
        const conversation = await Conversation.findById(conversationId);
        if (!conversation || !conversation.participants.includes(socket.userId)) {
          return socket.emit('error', { message: 'Not authorized' });
        }

        // Create message
        const message = await Message.create({
          conversationId,
          senderId: socket.userId,
          content,
          imgUrl: imgUrl || '',
          seenBy: [{ user: socket.userId, seenAt: new Date() }]
        });

        await message.populate('senderId', '-hashedPassword');

        // Update conversation
        const unreadCounts = {};
        conversation.participants.forEach(participantId => {
          const participantIdStr = participantId.toString();
          if (participantIdStr !== socket.userId) {
            const currentCount = conversation.unreadCounts.get(participantIdStr) || 0;
            unreadCounts[participantIdStr] = currentCount + 1;
          } else {
            unreadCounts[participantIdStr] = 0;
          }
        });

        conversation.lastMessage = {
          content,
          sender: socket.userId,
          createdAt: message.createdAt,
          imgUrl: imgUrl || ''
        };
        conversation.unreadCounts = unreadCounts;
        await conversation.save();

        // Emit to conversation room
        io.to(`conversation:${conversationId}`).emit('message:new', {
          message,
          conversation: {
            id: conversationId,
            lastMessage: conversation.lastMessage,
            unreadCounts: Object.fromEntries(conversation.unreadCounts)
          }
        });

        // Emit unread count update to other participants
        conversation.participants.forEach(participantId => {
          const participantIdStr = participantId.toString();
          if (participantIdStr !== socket.userId) {
            const socketId = userSockets.get(participantIdStr);
            if (socketId) {
              io.to(socketId).emit('conversation:unread', {
                conversationId,
                unreadCount: unreadCounts[participantIdStr]
              });
            }
          }
        });

      } catch (error) {
        console.error('Socket message send error:', error);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // Handle typing indicator
    socket.on('typing:start', (conversationId) => {
      socket.to(`conversation:${conversationId}`).emit('typing:start', {
        conversationId,
        userId: socket.userId,
        displayName: socket.user.displayName
      });
    });

    socket.on('typing:stop', (conversationId) => {
      socket.to(`conversation:${conversationId}`).emit('typing:stop', {
        conversationId,
        userId: socket.userId
      });
    });

    // Handle message seen
    socket.on('message:seen', async (data) => {
      try {
        const { conversationId, messageIds } = data;

        if (messageIds && messageIds.length > 0) {
          // Update specific messages
          await Message.updateMany(
            {
              _id: { $in: messageIds },
              senderId: { $ne: socket.userId },
              'seenBy.user': { $ne: socket.userId }
            },
            {
              $push: {
                seenBy: {
                  user: socket.userId,
                  seenAt: new Date()
                }
              }
            }
          );
        } else {
          // Update all unseen messages in conversation
          await Message.updateMany(
            {
              conversationId,
              senderId: { $ne: socket.userId },
              'seenBy.user': { $ne: socket.userId }
            },
            {
              $push: {
                seenBy: {
                  user: socket.userId,
                  seenAt: new Date()
                }
              }
            }
          );
        }

        // Reset unread count
        const conversation = await Conversation.findById(conversationId);
        if (conversation) {
          conversation.unreadCounts.set(socket.userId, 0);
          await conversation.save();
        }

        // Notify other users in conversation
        socket.to(`conversation:${conversationId}`).emit('message:seen', {
          conversationId,
          userId: socket.userId,
          messageIds
        });

      } catch (error) {
        console.error('Socket message seen error:', error);
      }
    });

    // Handle message reactions
    socket.on('message:react', async (data) => {
      try {
        const { messageId, emoji } = data;

        const message = await Message.findById(messageId);
        if (!message) return;

        // Check if already reacted
        const existingReaction = message.reactions.find(
          r => r.user.toString() === socket.userId && r.emoji === emoji
        );

        if (!existingReaction) {
          message.reactions.push({
            user: socket.userId,
            emoji
          });
          await message.save();
        }

        // Emit to conversation
        io.to(`conversation:${message.conversationId}`).emit('message:reaction', {
          messageId,
          userId: socket.userId,
          emoji,
          reactions: message.reactions
        });

      } catch (error) {
        console.error('Socket message react error:', error);
      }
    });

    // Handle message edit
    socket.on('message:edit', async (data) => {
      try {
        const { messageId, content } = data;

        const message = await Message.findById(messageId);
        if (!message || message.senderId.toString() !== socket.userId) {
          return;
        }

        message.content = content;
        message.isEdited = true;
        await message.save();

        io.to(`conversation:${message.conversationId}`).emit('message:edited', {
          messageId,
          content,
          isEdited: true
        });

      } catch (error) {
        console.error('Socket message edit error:', error);
      }
    });

    // Handle message delete
    socket.on('message:delete', async (data) => {
      try {
        const { messageId } = data;

        const message = await Message.findById(messageId);
        if (!message || message.senderId.toString() !== socket.userId) {
          return;
        }

        message.isDeleted = true;
        message.content = 'This message has been deleted';
        await message.save();

        io.to(`conversation:${message.conversationId}`).emit('message:deleted', {
          messageId
        });

      } catch (error) {
        console.error('Socket message delete error:', error);
      }
    });

    // Handle disconnect
    socket.on('disconnect', async () => {
      console.log(`User disconnected: ${socket.userId}`);
      
      // Remove from active sockets
      userSockets.delete(socket.userId);

      // Update user offline status
      await User.findByIdAndUpdate(socket.userId, {
        isOnline: false,
        lastSeen: new Date()
      });

      // Emit offline status
      io.emit('user:online', { userId: socket.userId, isOnline: false });
    });
  });
};

module.exports = { setupSocketHandlers, userSockets };

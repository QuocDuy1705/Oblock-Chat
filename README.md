# Oblock Chat

A modern, real-time social networking and chat application built with the MERN stack (MongoDB, Express, React, Node.js) and Socket.IO.

## Features

### 🔐 Authentication
- User registration with comprehensive profile information
- Secure login with username and password
- Password encryption using bcryptjs
- JWT-based authentication with access and refresh tokens
- Persistent login sessions

### 👤 User Management
- Complete user profiles with display name, avatar, bio
- Avatar upload functionality
- User search functionality
- Date of birth and contact information

### 👥 Friend System
- Send friend requests with optional messages
- Accept or decline friend requests
- Friends list with real-time online/offline status
- Remove friends functionality

### 💬 Real-time Chat
- Direct messaging between friends
- Group chat creation and management (3+ members)
- Real-time message delivery via Socket.IO
- Message pagination for loading older messages
- Typing indicators
- Message seen status with timestamps
- Unread message count per conversation
- Last message preview with timestamp

### ✨ Advanced Messaging Features
- Message reactions (emoji reactions like ❤️)
- Edit messages with edited indicator
- Delete messages (soft delete)
- Image/file upload support in messages
- Real-time message updates across all connected clients

### 🎨 Modern UI/UX
- Beautiful dark theme with gradient accents
- Responsive design for mobile and desktop
- Smooth animations and transitions
- Toast notifications for user feedback
- Loading states and error handling

## Tech Stack

### Backend
- **Node.js** - Runtime environment
- **Express.js** - Web framework
- **MongoDB** - Database
- **Mongoose** - ODM for MongoDB
- **Socket.IO** - Real-time bidirectional communication
- **JWT** - Authentication tokens
- **bcryptjs** - Password hashing
- **Multer** - File upload handling

### Frontend
- **React** - UI library
- **Vite** - Build tool and dev server
- **React Router** - Client-side routing
- **Socket.IO Client** - Real-time communication
- **Axios** - HTTP client
- **React Icons** - Icon library
- **React Toastify** - Toast notifications
- **date-fns** - Date formatting

## Installation

### Prerequisites
- Node.js (v14 or higher)
- MongoDB (v4 or higher)
- npm or yarn

### Backend Setup

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file (or copy from `.env.example`):
```bash
cp .env.example .env
```

4. Update the `.env` file with your configuration:
```env
PORT=5000
MONGODB_URI=mongodb://localhost:27017/oblock-chat
JWT_SECRET=your_secret_key_here
JWT_EXPIRE=7d
JWT_REFRESH_EXPIRE=30d
NODE_ENV=development
CLIENT_URL=http://localhost:3000
```

5. Make sure MongoDB is running, then start the backend server:
```bash
# For development with auto-reload
npm run dev

# For production
npm start
```

The backend server will start on `http://localhost:5000`

### Frontend Setup

1. Navigate to the frontend directory:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm run dev
```

The frontend will start on `http://localhost:3000`

## Usage

### Registration
1. Open `http://localhost:3000` in your browser
2. Click "Sign up" to create a new account
3. Fill in the registration form with:
   - First name and last name (used to create display name)
   - Username (for login)
   - Email (for notifications)
   - Phone number (optional)
   - Date of birth
   - Password (minimum 6 characters)

### Login
1. Enter your username and password
2. Click "Sign In"
3. You'll be redirected to the dashboard

### Adding Friends
1. Click the "Friends" icon in the sidebar
2. Go to the "Add Friends" tab
3. Search for users by username or display name
4. Click "Add Friend" to send a friend request

### Accepting Friend Requests
1. Click the "Friends" icon
2. Go to the "Requests" tab
3. Click "Accept" or "Decline" on pending requests

### Starting a Conversation
1. Click the "Friends" icon
2. In the "Friends" tab, click "Message" next to a friend's name
3. Or click "Start a New Chat" on the empty state

### Creating a Group Chat
1. Click the "Friends" icon
2. Go to the "New Group" tab
3. Enter a group name
4. Select at least 2 friends
5. Click "Create Group"

### Messaging Features
- **Send Messages**: Type in the message box and press Enter or click Send
- **React to Messages**: Hover over a message and click the smile icon
- **Edit Message**: Click the edit icon on your own messages
- **Delete Message**: Click the trash icon on your own messages
- **View Seen Status**: Messages show when they've been seen by recipients
- **Typing Indicators**: See when someone is typing in real-time

## Project Structure

```
oblock-chat/
├── backend/
│   ├── config/
│   │   └── db.js                 # Database connection
│   ├── controllers/
│   │   ├── authController.js     # Authentication logic
│   │   ├── userController.js     # User management
│   │   ├── friendController.js   # Friend system
│   │   ├── conversationController.js  # Conversations
│   │   └── messageController.js  # Messaging
│   ├── middleware/
│   │   ├── auth.js              # JWT authentication
│   │   └── upload.js            # File upload handling
│   ├── models/
│   │   ├── User.js              # User schema
│   │   ├── Friend.js            # Friendship schema
│   │   ├── FriendRequest.js     # Friend request schema
│   │   ├── Conversation.js      # Conversation schema
│   │   └── Message.js           # Message schema
│   ├── routes/
│   │   ├── auth.js              # Auth routes
│   │   ├── users.js             # User routes
│   │   ├── friends.js           # Friend routes
│   │   ├── conversations.js     # Conversation routes
│   │   └── messages.js          # Message routes
│   ├── socket/
│   │   └── socketHandler.js     # Socket.IO event handlers
│   ├── .env                     # Environment variables
│   ├── .env.example             # Environment template
│   ├── package.json
│   └── server.js                # Entry point
│
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── ChatArea.jsx     # Chat interface
│   │   │   ├── ChatArea.css
│   │   │   ├── FriendsPanel.jsx # Friends management
│   │   │   ├── FriendsPanel.css
│   │   │   ├── Sidebar.jsx      # Conversations list
│   │   │   └── Sidebar.css
│   │   ├── contexts/
│   │   │   ├── AuthContext.jsx  # Auth state management
│   │   │   └── SocketContext.jsx # Socket.IO management
│   │   ├── pages/
│   │   │   ├── Dashboard.jsx    # Main dashboard
│   │   │   ├── Dashboard.css
│   │   │   ├── Login.jsx        # Login page
│   │   │   ├── Register.jsx     # Registration page
│   │   │   └── Auth.css
│   │   ├── App.jsx              # App component
│   │   ├── App.css
│   │   ├── main.jsx             # Entry point
│   │   └── index.css            # Global styles
│   ├── index.html
│   ├── package.json
│   └── vite.config.js
│
└── README.md
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user
- `POST /api/auth/refresh` - Refresh access token
- `GET /api/auth/me` - Get current user

### Users
- `GET /api/users/search?q=query` - Search users
- `GET /api/users/:userId` - Get user by ID
- `PUT /api/users/profile` - Update profile
- `POST /api/users/avatar` - Upload avatar

### Friends
- `GET /api/friends` - Get friends list
- `GET /api/friends/requests` - Get friend requests
- `POST /api/friends/request/:userId` - Send friend request
- `PUT /api/friends/request/:requestId/accept` - Accept request
- `PUT /api/friends/request/:requestId/decline` - Decline request
- `DELETE /api/friends/:userId` - Remove friend

### Conversations
- `GET /api/conversations` - Get all conversations
- `GET /api/conversations/:conversationId` - Get conversation by ID
- `POST /api/conversations/direct/:userId` - Create/get direct conversation
- `POST /api/conversations/group` - Create group conversation
- `POST /api/conversations/:conversationId/members` - Add members to group

### Messages
- `GET /api/conversations/:conversationId/messages` - Get messages (paginated)
- `POST /api/conversations/:conversationId/messages` - Send message
- `PUT /api/conversations/:conversationId/messages/seen` - Mark messages as seen
- `PUT /api/messages/:messageId` - Edit message
- `DELETE /api/messages/:messageId` - Delete message
- `POST /api/messages/:messageId/reactions` - Add reaction
- `DELETE /api/messages/:messageId/reactions/:emoji` - Remove reaction

## Socket.IO Events

### Client → Server
- `conversation:join` - Join conversation room
- `conversation:leave` - Leave conversation room
- `message:send` - Send message
- `typing:start` - Start typing
- `typing:stop` - Stop typing
- `message:seen` - Mark messages as seen
- `message:react` - React to message
- `message:edit` - Edit message
- `message:delete` - Delete message

### Server → Client
- `message:new` - New message received
- `user:online` - User online/offline status
- `typing:start` - User started typing
- `typing:stop` - User stopped typing
- `message:seen` - Messages marked as seen
- `message:reaction` - Reaction added
- `message:edited` - Message edited
- `message:deleted` - Message deleted
- `conversation:unread` - Unread count updated

## Database Schema

### User
- username, hashedPassword, displayName, email, phone
- avatarUrl, bio, dateOfBirth
- isOnline, lastSeen
- createdAt, updatedAt

### Friend
- userA, userB (sorted IDs for consistency)
- createdAt, updatedAt

### FriendRequest
- from, to, message, status (pending/accepted/declined)
- createdAt, updatedAt

### Conversation
- participants (array of user IDs)
- isGroup, groupName, groupAdmin
- lastMessage (embedded document)
- unreadCounts (map of userId → count)
- createdAt, updatedAt

### Message
- conversationId, senderId, content, imgUrl
- seenBy (array with user and seenAt)
- reactions (array with user and emoji)
- isEdited, isDeleted
- createdAt, updatedAt

## Security Features

- Password hashing with bcrypt (10 salt rounds)
- JWT authentication with access and refresh tokens
- Protected API routes with middleware
- Input validation and sanitization
- CORS configuration
- Secure file upload handling

## Future Enhancements

- Voice and video calls
- Message search functionality
- File sharing with previews
- User blocking
- Message forwarding
- Read receipts for group chats
- Push notifications
- Email notifications
- User presence (away, busy, etc.)
- Message encryption
- Admin panel
- Analytics dashboard

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Support

For issues and questions, please open an issue on GitHub.

---

Built with ❤️ using the MERN stack and Socket.IO

# Quick Setup Guide

Follow these steps to get Oblock Chat running on your machine.

## Prerequisites

Make sure you have the following installed:
- **Node.js** (v14 or higher) - [Download](https://nodejs.org/)
- **MongoDB** (v4 or higher) - [Download](https://www.mongodb.com/try/download/community)
- **npm** (comes with Node.js)

## Step-by-Step Setup

### 1. Install MongoDB

If you haven't already, install and start MongoDB:

**On macOS (using Homebrew):**
```bash
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community
```

**On Ubuntu/Debian:**
```bash
sudo apt-get install mongodb
sudo systemctl start mongodb
sudo systemctl enable mongodb
```

**On Windows:**
- Download MongoDB Community Server from [mongodb.com](https://www.mongodb.com/try/download/community)
- Install and start MongoDB as a service

Verify MongoDB is running:
```bash
mongo --version
# or
mongosh --version
```

### 2. Clone/Navigate to the Project

```bash
cd /workspace
```

### 3. Install Backend Dependencies

```bash
cd backend
npm install
```

### 4. Configure Backend Environment

The `.env` file is already created with default values. You can modify it if needed:

```bash
# Edit backend/.env if you need to change:
# - MongoDB URI (default: mongodb://localhost:27017/oblock-chat)
# - Port (default: 5000)
# - JWT Secret (change this in production!)
```

### 5. Install Frontend Dependencies

```bash
cd ../frontend
npm install
```

### 6. Start the Application

You'll need two terminal windows/tabs:

**Terminal 1 - Start Backend:**
```bash
cd backend
npm run dev
```

You should see:
```
Server running on port 5000
MongoDB Connected: localhost
```

**Terminal 2 - Start Frontend:**
```bash
cd frontend
npm run dev
```

You should see:
```
  VITE v5.x.x  ready in xxx ms

  ➜  Local:   http://localhost:3000/
```

### 7. Open the Application

Open your browser and navigate to:
```
http://localhost:3000
```

## First-Time Usage

### Create Your First Account

1. Click **"Sign up"** on the login page
2. Fill in the registration form:
   - First Name: John
   - Last Name: Doe
   - Username: johndoe
   - Email: john@example.com
   - Date of Birth: Select a date
   - Password: password123
   - Confirm Password: password123
3. Click **"Create Account"**

### Create a Second Account (for testing)

1. Logout from the first account (click logout icon in sidebar)
2. Register another user:
   - First Name: Jane
   - Last Name: Smith
   - Username: janesmith
   - Email: jane@example.com
   - Date of Birth: Select a date
   - Password: password123
   - Confirm Password: password123

### Add Friends and Start Chatting

1. Login as John
2. Click the **Friends** icon (users icon) in the sidebar
3. Go to **"Add Friends"** tab
4. Search for "janesmith"
5. Click **"Add Friend"**
6. Logout and login as Jane
7. Click **Friends** icon → **"Requests"** tab
8. Click **"Accept"** on John's friend request
9. Click **"Message"** to start chatting!

### Test Real-time Features

To see real-time messaging in action:

1. Open two browser windows side by side (or use two different browsers)
2. Login as John in window 1
3. Login as Jane in window 2
4. Start a conversation from either window
5. Watch messages appear in real-time in both windows!

## Troubleshooting

### MongoDB Connection Error

**Error:** `MongoServerError: connect ECONNREFUSED`

**Solution:**
- Make sure MongoDB is running: `brew services start mongodb-community` (macOS) or `sudo systemctl start mongodb` (Linux)
- Check if MongoDB is listening: `mongo` or `mongosh`

### Port Already in Use

**Error:** `EADDRINUSE: address already in use`

**Solution:**
- Backend (port 5000): Kill the process using port 5000
  ```bash
  # On macOS/Linux
  lsof -ti:5000 | xargs kill -9
  
  # On Windows
  netstat -ano | findstr :5000
  taskkill /PID <PID> /F
  ```
- Frontend (port 3000): Similar steps for port 3000

### Cannot Find Module Error

**Error:** `Cannot find module 'express'`

**Solution:**
- Make sure you installed dependencies:
  ```bash
  cd backend && npm install
  cd ../frontend && npm install
  ```

### Socket.IO Connection Failed

**Error:** Socket connection errors in browser console

**Solution:**
- Make sure backend is running on port 5000
- Check that `frontend/src/contexts/SocketContext.jsx` has the correct backend URL
- Clear browser cache and reload

## Development Tips

### Auto-reload on Changes

Both frontend and backend use auto-reload:
- **Backend**: Uses `nodemon` (configured in `package.json`)
- **Frontend**: Uses Vite's hot module replacement

Just save your files and changes will appear automatically!

### View Database

You can view your MongoDB data using:
- **MongoDB Compass** (GUI): [Download](https://www.mongodb.com/try/download/compass)
- **Command Line**: 
  ```bash
  mongosh
  use oblock-chat
  db.users.find()
  db.messages.find()
  ```

### Check Backend API

Test API endpoints using:
- **Postman**: [Download](https://www.postman.com/downloads/)
- **curl**: 
  ```bash
  # Health check
  curl http://localhost:5000/api/health
  ```

### Clear All Data

To start fresh:
```bash
mongosh
use oblock-chat
db.dropDatabase()
```

## Next Steps

- Read the full [README.md](README.md) for complete feature documentation
- Explore the API endpoints
- Customize the UI theme in `frontend/src/index.css`
- Add your own features!

## Getting Help

If you encounter any issues:
1. Check the browser console for errors
2. Check the backend terminal for error logs
3. Review this setup guide
4. Check MongoDB is running
5. Verify all dependencies are installed

---

Happy chatting! 🎉

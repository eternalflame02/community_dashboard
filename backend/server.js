require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '10mb' }));

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir);
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  }
});

const upload = multer({ 
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

// MongoDB Atlas Connection with improved error handling
const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    });
    console.log(`✅ MongoDB Atlas Connected: ${conn.connection.host}`);

    // Create indexes after successful connection
    await setupIndexes();
  } catch (error) {
    console.error('❌ MongoDB Connection Error:', error.message);
    process.exit(1);
  }
};

// Setup indexes function
const setupIndexes = async () => {
  try {
    console.log('Setting up database indexes...');
    
    // Create indexes for the incidents collection
    await Incident.collection.createIndexes([
      { key: { 'location': '2dsphere' }, name: 'location_2dsphere' },
      { key: { 'category': 1 }, name: 'category_1' },
      { key: { 'status': 1 }, name: 'status_1' },
      { key: { 'priority': 1 }, name: 'priority_1' },
      { key: { 'createdAt': -1 }, name: 'createdAt_-1' },
      { key: { 'reporterId': 1 }, name: 'reporterId_1' }
    ]);

    console.log('✅ Database indexes created successfully');
  } catch (error) {
    console.error('❌ Error creating indexes:', error);
    throw error;
  }
};

// Monitor MongoDB connection events
mongoose.connection.on('connected', () => {
  console.log('🟢 MongoDB connection established');
});

mongoose.connection.on('error', (err) => {
  console.error('🔴 MongoDB connection error:', err);
});

mongoose.connection.on('disconnected', () => {
  console.log('🟡 MongoDB connection disconnected');
});

// Graceful shutdown
process.on('SIGINT', async () => {
  await mongoose.connection.close();
  process.exit(0);
});

// Connect to MongoDB
connectDB();

// Basic schema for incidents
const incidentSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  location: {
    type: { type: String, enum: ['Point'], required: true },
    coordinates: { type: [Number], required: true }, // [longitude, latitude]
  },
  address: { type: String, required: true },
  category: { type: String, required: true },
  status: {
    type: String,
    enum: ['open', 'inProgress', 'resolved'],
    default: 'open',
  },
  priority: {
    type: Number,
    enum: [0, 1, 2], // 0: low, 1: medium, 2: high
    required: true,
  },
  reporterId: { type: String, required: true },
  images: [String],
  createdAt: { type: Date, default: Date.now },
  resolvedAt: Date
}, { timestamps: true });

const Incident = mongoose.model('Incident', incidentSchema);

// User schema and model
const userSchema = new mongoose.Schema({
  firebaseId: { type: String, required: true, unique: true },
  email: { type: String, required: true },
  displayName: String,
  role: { type: String, enum: ['user', 'officer'], default: 'user' },
});
const User = mongoose.model('User', userSchema);

// Routes
app.get('/health', (req, res) => {
  const status = {
    server: 'running',
    mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
    timestamp: new Date().toISOString()
  };
  res.json(status);
});

// Get all incidents
app.get('/incidents', async (req, res) => {
  try {
    const incidents = await Incident.find().sort('-createdAt');
    res.json(incidents);
  } catch (err) {
    console.error('Error fetching incidents:', err);
    res.status(500).json({ error: 'Failed to fetch incidents', details: err.message });
  }
});

// Create new incident
app.post('/incidents', async (req, res) => {
  try {
    const incident = new Incident(req.body);
    await incident.save();
    res.status(201).json(incident);
  } catch (err) {
    console.error('Error creating incident:', err);
    res.status(500).json({ error: 'Failed to create incident', details: err.message });
  }
});

// Update incident status
app.patch('/incidents/:id', async (req, res) => {
  try {
    const incident = await Incident.findByIdAndUpdate(
      req.params.id,
      { $set: req.body },
      { new: true }
    );
    if (!incident) {
      return res.status(404).json({ error: 'Incident not found' });
    }
    res.json(incident);
  } catch (err) {
    console.error('Error updating incident:', err);
    res.status(500).json({ error: 'Failed to update incident', details: err.message });
  }
});

// Sync user from frontend (create if not exists)
app.post('/users/sync', async (req, res) => {
  try {
    const { firebaseId, email, displayName } = req.body;
    let user = await User.findOne({ firebaseId });
    if (!user) {
      user = new User({ firebaseId, email, displayName, role: 'user' });
      await user.save();
    }
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: 'Failed to sync user', details: err.message });
  }
});

// Get user by firebaseId
app.get('/users/by-firebase-id/:firebaseId', async (req, res) => {
  try {
    const user = await User.findOne({ firebaseId: req.params.firebaseId });
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch user', details: err.message });
  }
});

// Promote user to officer (admin/manual)
app.patch('/users/:id/promote', async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { $set: { role: 'officer' } },
      { new: true }
    );
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: 'Failed to promote user', details: err.message });
  }
});

// Handle image uploads
app.post('/upload', upload.single('file'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }
    const imageUrl = `http://localhost:${process.env.PORT}/uploads/${req.file.filename}`;
    res.status(200).json({ url: imageUrl });
  } catch (err) {
    console.error('Error uploading file:', err);
    res.status(500).json({ error: 'Failed to upload file', details: err.message });
  }
});

// Serve uploaded files
app.use('/uploads', express.static('uploads'));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});

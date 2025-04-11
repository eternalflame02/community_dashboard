const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();

// Middleware
// Increased the size limit for JSON payloads in body-parser
app.use(bodyParser.json({ limit: '10mb' })); // Set limit to 10 MB for image uploads
// Updated CORS configuration to allow all origins for development
app.use(cors({ origin: '*' }));

// Request Logger
app.use((req, res, next) => {
  console.log(`Incoming request: ${req.method} ${req.url}`);
  console.log('Request body:', req.body);
  next();
});

// Error Logger
app.use((err, req, res, next) => {
  console.error('Error occurred:', err);
  res.status(500).json({ error: 'Internal Server Error', details: err.message });
});

// Connect to MongoDB
const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/community_dashboard';

mongoose.connect(mongoUri)
  .then(() => {
    console.log('✅ Connected to MongoDB');
  })
  .catch((err) => {
    console.error('❌ Error connecting to MongoDB:', err);
    process.exit(1); // Exit the process if MongoDB connection fails
  });

// Added MongoDB connection status logging
mongoose.connection.on('connected', () => {
  console.log('✅ MongoDB connected');
});

mongoose.connection.on('error', (err) => {
  console.error('❌ MongoDB connection error:', err);
});

mongoose.connection.on('disconnected', () => {
  console.warn('⚠️ MongoDB disconnected');
});

// Mongoose Schema & Model
// Updated `incidentSchema` to include `address`, `category`, and `description` fields
const incidentSchema = new mongoose.Schema({
  title: String,
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
}, { timestamps: true }); // Automatically adds createdAt and updatedAt

const Incident = mongoose.model('Incident', incidentSchema);

// Ensure indexes for `address`, `category`, and `description`
Incident.collection.createIndex({ address: 1 }, { name: 'address_1' });
Incident.collection.createIndex({ category: 1 }, { name: 'category_1' });
Incident.collection.createIndex({ description: 1 }, { name: 'description_1' });

// Health Check Route
app.get('/', (req, res) => {
  res.send('🚀 Backend server is up and running!');
});

// Added health check endpoint to verify MongoDB connection
app.get('/health', async (req, res) => {
  try {
    const isConnected = mongoose.connection.readyState === 1; // 1 means connected
    res.json({ status: isConnected ? 'connected' : 'disconnected' });
  } catch (err) {
    res.status(500).json({ error: 'Health check failed', details: err.message });
  }
});

// Get all incidents
app.get('/incidents', async (req, res) => {
  try {
    console.log('Fetching all incidents');
    const incidents = await Incident.find();
    console.log('Fetched incidents:', incidents);
    res.json(incidents);
  } catch (err) {
    console.error('Error fetching incidents:', err);
    res.status(500).json({ error: 'Failed to fetch incidents', details: err.message });
  }
});

// Added validation and handling for `images` and `priority` fields in POST /incidents
// Fixed mapping of numeric `status` values to string values
app.post('/incidents', async (req, res) => {
  try {
    console.log('Received data:', req.body);

    // Validate location
    if (!req.body.location || !req.body.location.coordinates || req.body.location.coordinates.length !== 2) {
      console.log('Invalid location data:', req.body.location);
      return res.status(400).json({ error: 'Invalid location data' });
    }

    // Validate priority
    if (typeof req.body.priority !== 'number' || req.body.priority < 0 || req.body.priority > 2) {
      console.log('Invalid priority value:', req.body.priority);
      return res.status(400).json({ error: 'Invalid priority value' });
    }

    // Validate images
    if (!Array.isArray(req.body.images)) {
      console.log('Invalid images data:', req.body.images);
      return res.status(400).json({ error: 'Invalid images data' });
    }

    // Map numeric status values to string values
    const statusMap = ['open', 'inProgress', 'resolved'];
    if (typeof req.body.status === 'number') {
      req.body.status = statusMap[req.body.status];
    }

    const incident = new Incident(req.body);
    await incident.save();
    console.log('Incident saved successfully:', incident);
    res.status(201).json(incident);
  } catch (err) {
    console.error('Error saving incident:', err);
    res.status(500).json({ error: 'Failed to save incident', details: err.message });
  }
});

// Added detailed logging for status updates and image handling
app.patch('/incidents/:id', async (req, res) => {
  try {
    console.log(`Updating incident with ID: ${req.params.id}`);
    console.log('Request body:', req.body);

    const updatedIncident = await Incident.findByIdAndUpdate(
      req.params.id,
      { status: req.body.status },
      { new: true }
    );

    if (!updatedIncident) {
      console.log('Incident not found');
      return res.status(404).json({ error: 'Incident not found' });
    }

    console.log('Incident updated successfully:', updatedIncident);
    res.json(updatedIncident);
  } catch (err) {
    console.error('Error updating incident:', err);
    res.status(500).json({ error: 'Failed to update incident', details: err.message });
  }
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🟢 Server running on port ${PORT}`));

const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();

// Middleware
app.use(bodyParser.json());
app.use(cors({ origin: 'http://localhost:1234' })); // Adjust as per your frontend port

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
mongoose.connect('mongodb://localhost:27017/community_dashboard')
  .then(() => {
    console.log('✅ Connected to MongoDB');
  })
  .catch((err) => {
    console.error('❌ Error connecting to MongoDB:', err);
    process.exit(1); // Exit the process if MongoDB connection fails
  });

// Mongoose Schema & Model
const incidentSchema = new mongoose.Schema({
  title: String,
  description: String,
  status: {
    type: String,
    enum: ['open', 'inProgress', 'resolved'],
    default: 'open'
  }
}, { timestamps: true }); // Automatically adds createdAt and updatedAt

const Incident = mongoose.model('Incident', incidentSchema);

// Health Check Route
app.get('/', (req, res) => {
  res.send('🚀 Backend server is up and running!');
});

// Get all incidents
app.get('/incidents', async (req, res) => {
  try {
    const incidents = await Incident.find();
    res.json(incidents);
  } catch (err) {
    console.error('Error fetching incidents:', err);
    res.status(500).json({ error: 'Failed to fetch incidents', details: err.message });
  }
});

// Add a new incident
app.post('/incidents', async (req, res) => {
  try {
    console.log('Received data:', req.body);
    const incident = new Incident(req.body);
    await incident.save();
    res.status(201).json(incident);
  } catch (err) {
    console.error('Error saving incident:', err);
    res.status(500).json({ error: 'Failed to save incident', details: err.message });
  }
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🟢 Server running on port ${PORT}`));

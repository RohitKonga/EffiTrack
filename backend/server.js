const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');
require('dotenv').config();

const app = express();

// Connect Database
connectDB();

// Middleware
app.use(cors());
app.use(express.json());

// Basic route
app.get('/', (req, res) => res.send('API Running'));

// Debug: Test if basic routes work
app.get('/test', (req, res) => res.json({ msg: 'Test route working' }));

app.use('/api/auth', require('./routes/auth'));
app.use('/api/attendance', require('./routes/attendance'));

// Debug: Log before loading task routes
console.log('Loading task routes...');
const taskRoutes = require('./routes/task');
console.log('Task routes loaded:', taskRoutes);
app.use('/api/tasks', taskRoutes);

app.use('/api/leaves', require('./routes/leave'));
app.use('/api/announcements', require('./routes/announcement'));
app.use('/api/profile', require('./routes/profile'));
app.use('/api/analytics', require('./routes/analytics'));

// Debug: Log all registered routes
console.log('All routes registered. Available routes:');
app._router.stack.forEach(function(r){
  if (r.route && r.route.path){
    console.log('Route:', Object.keys(r.route.methods), r.route.path);
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server started on port ${PORT}`)); 
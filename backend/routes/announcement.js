const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { createAnnouncement, getAnnouncements } = require('../controllers/announcementController');

// Create an announcement (Admin/Manager)
router.post('/', auth, createAnnouncement);
// List announcements (all users)
router.get('/', auth, getAnnouncements);

module.exports = router; 
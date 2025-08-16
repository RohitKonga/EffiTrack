const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { createAnnouncement, getAnnouncements, deleteAnnouncement } = require('../controllers/announcementController');

// Create an announcement (Admin/Manager)
router.post('/', auth, createAnnouncement);
// List announcements (all users)
router.get('/', auth, getAnnouncements);
// Delete an announcement (Admin/Manager)
router.delete('/:id', auth, deleteAnnouncement);

module.exports = router; 
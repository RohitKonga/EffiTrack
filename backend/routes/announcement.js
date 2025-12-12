const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { createAnnouncement, getAnnouncements, deleteAnnouncement } = require('../controllers/announcementController');

router.post('/', auth, createAnnouncement);
router.get('/', auth, getAnnouncements);
router.delete('/:id', auth, deleteAnnouncement);

module.exports = router; 
const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { getProfile, updateProfile, getAllProfiles, deleteUser } = require('../controllers/profileController');

router.get('/', auth, getProfile);
router.put('/', auth, updateProfile);
router.get('/all', auth, getAllProfiles);
router.delete('/:id', auth, deleteUser);

module.exports = router; 
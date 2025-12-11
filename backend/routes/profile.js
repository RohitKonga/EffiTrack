const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const {
  getProfile,
  updateProfile,
  updateFcmToken,
  getAllProfiles,
  deleteUser,
  getUsersByDepartment,
  updateUserStatus,
} = require('../controllers/profileController');

router.get('/', auth, getProfile);
router.put('/', auth, updateProfile);
router.post('/fcm-token', auth, updateFcmToken);
router.get('/all', auth, getAllProfiles);
router.get('/department/:department', auth, getUsersByDepartment);
router.put('/status/:id', auth, updateUserStatus);
router.delete('/:id', auth, deleteUser);

module.exports = router; 
const Announcement = require('../models/Announcement');

// Create an announcement (Admin/Manager)
exports.createAnnouncement = async (req, res) => {
  try {
    const { title, message, targetRoles } = req.body;
    const createdBy = req.user.id;
    const announcement = new Announcement({ title, message, createdBy, targetRoles });
    await announcement.save();
    res.json(announcement);
  } catch (err) {
    res.status(500).send('Server error');
  }
};

// List announcements (all users, filter by role)
exports.getAnnouncements = async (req, res) => {
  try {
    const role = req.user ? req.user.role : null;
    let query = {};
    if (role) {
      query = { $or: [ { targetRoles: role }, { targetRoles: { $size: 0 } } ] };
    }
    const announcements = await Announcement.find(query).sort({ createdAt: -1 });
    res.json(announcements);
  } catch (err) {
    res.status(500).send('Server error');
  }
};

// Delete an announcement (Admin/Manager)
exports.deleteAnnouncement = async (req, res) => {
  try {
    const announcement = await Announcement.findById(req.params.id);
    if (!announcement) {
      return res.status(404).json({ msg: 'Announcement not found' });
    }
    
    // Check if user has permission to delete (Admin or Manager)
    if (req.user.role !== 'Admin' && req.user.role !== 'Manager') {
      return res.status(403).json({ msg: 'Not authorized to delete announcements' });
    }
    
    await Announcement.findByIdAndDelete(req.params.id);
    res.json({ msg: 'Announcement deleted successfully' });
  } catch (err) {
    res.status(500).send('Server error');
  }
}; 
const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['Admin', 'Manager', 'Employee'], required: true },
  phone: { type: String },
  department: {
    type: String,
    enum: ['Design', 'Development', 'Marketing', 'Sales', 'HR'],
    required: false, 
    validate: {
      validator: function(value) {
        if (this.role === 'Admin') {
          return true; 
        }
        return value != null && value.trim() !== '';
      },
      message: 'Department is required for non-Admin users'
    }
  },
  fcmToken: { type: String },
  status: {
    type: String,
    enum: ['Pending', 'Approved', 'Rejected'],
    default: 'Pending',
  },
}, { timestamps: true });

module.exports = mongoose.model('User', UserSchema); 
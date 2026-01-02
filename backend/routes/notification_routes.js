const express = require('express');
const Notification = require('../models/notification_model');
const { auth } = require('../middleware/auth_middleware');
const router = express.Router();

// Get All Notifications for User
router.get('/', auth, async (req, res) => {
    try {
        const notifications = await Notification.find({ userId: req.user })
            .sort({ createdAt: -1 })
            .limit(50);
        res.json(notifications);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Mark Notification as Read
router.put('/:id/read', auth, async (req, res) => {
    try {
        const notification = await Notification.findOneAndUpdate(
            { _id: req.params.id, userId: req.user },
            { status: 'read' },
            { new: true }
        );

        if (!notification) {
            return res.status(404).json({ msg: 'Notification not found' });
        }

        res.json(notification);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Mark All as Read
router.put('/read-all', auth, async (req, res) => {
    try {
        await Notification.updateMany(
            { userId: req.user, status: 'unread' },
            { status: 'read' }
        );
        res.json({ msg: 'All notifications marked as read' });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

module.exports = router;

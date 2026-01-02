const express = require('express');
const User = require('../models/user_model');
const Product = require('../models/product_model');
const bcrypt = require('bcryptjs');
const { auth } = require('../middleware/auth_middleware');
const router = express.Router();

// Get Profile
router.get('/profile', auth, async (req, res) => {
    try {
        const user = await User.findById(req.user);
        if (!user) {
            return res.status(404).json({ msg: "User not found" });
        }
        const userObj = user.toObject();
        delete userObj.password;
        res.json(userObj);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Update Profile
router.put('/profile', auth, async (req, res) => {
    try {
        const { name, phone, address, password } = req.body;
        let user = await User.findById(req.user);

        if (!user) {
            return res.status(404).json({ msg: "User not found" });
        }

        if (name) user.name = name;
        if (phone) user.phone = phone;
        if (address) user.address = address;
        if (password) {
            user.password = await bcrypt.hash(password, 8);
        }

        await user.save();

        // Return updated user (excluding password)
        const userObj = user.toObject();
        delete userObj.password;
        res.json(userObj);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Toggle Favorite
router.post('/favorites', auth, async (req, res) => {
    try {
        const { productId } = req.body;
        let user = await User.findById(req.user);

        if (user.favorites.includes(productId)) {
            user.favorites = user.favorites.filter(id => id.toString() !== productId);
        } else {
            user.favorites.push(productId);
        }

        await user.save();
        res.json(user.favorites);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Get Favorites
router.get('/favorites', auth, async (req, res) => {
    try {
        const user = await User.findById(req.user).populate('favorites');
        res.json(user.favorites);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Add to Cart
router.post('/cart', auth, async (req, res) => {
    try {
        const { productId, quantity, selectedColor, selectedSize } = req.body;
        let user = await User.findById(req.user);

        // Find if the exact variant is already in cart
        const existingItem = user.cart.find(item =>
            item.product.equals(productId) &&
            item.selectedColor === selectedColor &&
            item.selectedSize === selectedSize
        );

        if (existingItem) {
            existingItem.quantity += quantity;
        } else {
            user.cart.push({
                product: productId,
                quantity,
                selectedColor: selectedColor || '',
                selectedSize: selectedSize || ''
            });
        }

        await user.save();
        res.json(user.cart);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Remove from Cart
router.delete('/cart/:id', auth, async (req, res) => {
    try {
        let user = await User.findById(req.user);
        user.cart = user.cart.filter(item => !item._id.equals(req.params.id));
        await user.save();
        res.json(user.cart);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Get Cart
router.get('/cart', auth, async (req, res) => {
    try {
        const user = await User.findById(req.user).populate('cart.product');
        res.json(user.cart);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

module.exports = router;

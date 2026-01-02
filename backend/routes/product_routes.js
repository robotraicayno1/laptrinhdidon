const express = require('express');
const Product = require('../models/product_model');
const { admin, auth } = require('../middleware/auth_middleware');
const router = express.Router();

// Get All Products (with Filters & Search)
router.get('/', async (req, res) => {
    try {
        const { category, isFeatured, isBestSeller, search, minPrice, maxPrice, gender } = req.query;
        let query = {};

        if (search) {
            query.name = { $regex: search, $options: "i" }; // Case-insensitive search
        }
        if (category && category !== 'All') query.category = category;
        if (isFeatured === 'true') query.isFeatured = true;
        if (isBestSeller === 'true') query.isBestSeller = true;

        if (gender && gender !== 'All') {
            query.gender = gender;
        }

        if (minPrice || maxPrice) {
            query.price = {};
            if (minPrice) query.price.$gte = Number(minPrice);
            if (maxPrice) query.price.$lte = Number(maxPrice);
        }

        const products = await Product.find(query);
        res.json(products);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Get Inventory Overview (Admin Only)
router.get('/inventory', auth, admin, async (req, res) => {
    try {
        const products = await Product.find({}).sort({ name: 1 });
        res.json(products);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Get Product by ID
router.get('/:id', async (req, res) => {
    try {
        const product = await Product.findById(req.params.id);
        if (!product) {
            return res.status(404).json({ msg: 'Product not found' });
        }
        res.json(product);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Create Product (Admin Only)
router.post('/', auth, admin, async (req, res) => {
    try {
        const { name, description, price, imageUrl, category, isFeatured, isBestSeller, gender, variants } = req.body;

        let product = new Product({
            name,
            description,
            price,
            imageUrl,
            category,
            isFeatured,
            isBestSeller,
            gender,
            variants,
        });

        product = await product.save();
        res.status(201).json(product);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Update Product (Admin Only)
router.put('/:id', auth, admin, async (req, res) => {
    try {
        const { name, description, price, imageUrl, category, isFeatured, isBestSeller, gender, variants } = req.body;

        const product = await Product.findByIdAndUpdate(
            req.params.id,
            { name, description, price, imageUrl, category, isFeatured, isBestSeller, gender, variants },
            { new: true, runValidators: true }
        );

        if (!product) return res.status(404).json({ msg: "Product not found" });
        res.json(product);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Get Recommendations (Same Category)
router.get('/recommendations/:id', async (req, res) => {
    try {
        const product = await Product.findById(req.params.id);
        if (!product) return res.status(404).json({ msg: "Product not found" });

        const recommendations = await Product.find({
            category: product.category,
            _id: { $ne: product._id }
        }).limit(6);

        res.json(recommendations);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Delete Product (Admin Only)
router.delete('/:id', auth, admin, async (req, res) => {
    try {
        const product = await Product.findByIdAndDelete(req.params.id);
        if (!product) {
            return res.status(404).json({ msg: 'Product not found' });
        }
        res.json({ msg: 'Product removed' });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

module.exports = router;

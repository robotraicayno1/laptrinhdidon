const express = require('express');
const Review = require('../models/review_model');
const Product = require('../models/product_model');
const { auth, admin } = require('../middleware/auth_middleware');
const router = express.Router();

// Get All Reviews for a Product
router.get('/products/:productId/reviews', async (req, res) => {
    try {
        const reviews = await Review.find({ productId: req.params.productId })
            .sort({ createdAt: -1 }); // Newest first
        res.json(reviews);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Add a Review (Authenticated Users Only)
router.post('/products/:productId/reviews', auth, async (req, res) => {
    try {
        const { rating, comment } = req.body;
        const productId = req.params.productId;

        // Check if product exists
        const product = await Product.findById(productId);
        if (!product) {
            return res.status(404).json({ msg: 'Product not found' });
        }

        // Check if user already reviewed this product
        const existingReview = await Review.findOne({ productId, userId: req.user });
        if (existingReview) {
            return res.status(400).json({ msg: 'You have already reviewed this product' });
        }

        // Create new review
        let review = new Review({
            productId,
            userId: req.user,
            userName: req.userName,
            rating,
            comment,
        });

        review = await review.save();

        // Update product's average rating and review count
        await updateProductRating(productId);

        res.status(201).json(review);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Delete a Review (Admin or Review Owner)
router.delete('/reviews/:reviewId', auth, async (req, res) => {
    try {
        const review = await Review.findById(req.params.reviewId);

        if (!review) {
            return res.status(404).json({ msg: 'Review not found' });
        }

        // Check if user is admin or the review owner
        const isAdmin = req.userType === 'admin';
        const isOwner = review.userId.toString() === req.user;

        if (!isAdmin && !isOwner) {
            return res.status(403).json({ msg: 'Not authorized to delete this review' });
        }

        const productId = review.productId;
        await Review.findByIdAndDelete(req.params.reviewId);

        // Update product's average rating and review count
        await updateProductRating(productId);

        res.json({ msg: 'Review deleted successfully' });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Helper function to update product rating
async function updateProductRating(productId) {
    const reviews = await Review.find({ productId });

    if (reviews.length === 0) {
        await Product.findByIdAndUpdate(productId, {
            averageRating: 0,
            reviewCount: 0,
        });
    } else {
        const totalRating = reviews.reduce((sum, review) => sum + review.rating, 0);
        const averageRating = totalRating / reviews.length;

        await Product.findByIdAndUpdate(productId, {
            averageRating: parseFloat(averageRating.toFixed(1)),
            reviewCount: reviews.length,
        });
    }
}

module.exports = router;

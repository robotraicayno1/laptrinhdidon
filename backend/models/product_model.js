const mongoose = require('mongoose');

const variantSchema = new mongoose.Schema({
    color: { type: String, required: true },
    size: { type: String, required: true },
    stock: { type: Number, default: 0, min: 0 },
    purchasePrice: { type: Number, default: 0 }, // Giá nhập
    sellingPrice: { type: Number, default: 0 },  // Giá bán
});

const productSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true,
    },
    description: {
        type: String,
        required: true,
        trim: true,
    },
    price: {
        type: Number,
        required: false,
    },
    imageUrl: {
        type: String,
        required: true,
    },
    category: {
        type: String,
        required: true,
        enum: ['Men', 'Women', 'Pants', 'Shirts', 'Accessories'],
    },
    gender: {
        type: String,
        enum: ['Men', 'Women', 'Unisex', 'Kids'],
        default: 'Unisex',
    },
    variants: [variantSchema],
    isFeatured: {
        type: Boolean,
        default: false,
    },
    isBestSeller: {
        type: Boolean,
        default: false,
    },
    averageRating: {
        type: Number,
        default: 0,
    },
    reviewCount: {
        type: Number,
        default: 0,
    },
    createdAt: {
        type: Date,
        default: Date.now,
    }
});

const Product = mongoose.model('Product', productSchema);
module.exports = Product;

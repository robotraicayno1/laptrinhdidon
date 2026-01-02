const mongoose = require('mongoose');

const orderSchema = mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: 'User',
    },
    address: {
        type: String,
        required: true,
    },
    products: [
        {
            product: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'Product',
                required: true,
            },
            quantity: {
                type: Number,
                required: true,
            },
            selectedColor: {
                type: String,
                required: true,
            },
            selectedSize: {
                type: String,
                required: true,
            },
        }
    ],
    totalPrice: {
        type: Number,
        required: true,
    },
    voucherCode: {
        type: String,
        default: '',
    },
    discountAmount: {
        type: Number,
        default: 0,
    },
    shippingFee: {
        type: Number,
        default: 0,
    },
    appTransId: {
        type: String,
        default: '',
    },
    trackingNumber: {
        type: String,
        default: '',
    },
    status: {
        type: Number,
        default: 0,
        // 0: Pending/Chờ xác nhận
        // 1: Confirmed/Đã xác nhận
        // 2: Shipped/Đang giao
        // 3: Delivered/Đã giao
        // 4: Cancelled/Đã hủy
    },
    createdAt: {
        type: Number, // Storing as timestamp for consistency with other parts if any, or just easy sorting
        default: () => Date.now(),
    }
});

const Order = mongoose.model('Order', orderSchema);
module.exports = Order;

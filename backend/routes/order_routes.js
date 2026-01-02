const express = require('express');
const orderRouter = express.Router();
const { auth } = require('../middleware/auth_middleware');
const { admin } = require('../middleware/auth_middleware');
const Order = require('../models/order_model');
const User = require('../models/user_model');
const Product = require('../models/product_model');
const Notification = require('../models/notification_model');
const crypto = require('crypto');

// Utility to create notifications
const createNotification = async (userId, title, message, orderId) => {
    try {
        const notification = new Notification({
            userId,
            title,
            message,
            orderId
        });
        await notification.save();
    } catch (e) {
        console.error('Notification Error:', e.message);
    }
};

// Create Order (Checkout)
orderRouter.post('/', auth, async (req, res) => {
    try {
        const { totalPrice, cart, voucherCode, discountAmount, shippingFee, address } = req.body;

        let products = [];
        for (let i = 0; i < cart.length; i++) {
            const item = cart[i];
            const productDoc = await Product.findById(item.product._id);

            if (!productDoc) {
                return res.status(404).json({ msg: `Sản phẩm ${item.product.name} không tồn tại` });
            }

            const variant = productDoc.variants.find(
                v => v.color === item.selectedColor && v.size === item.selectedSize
            );

            if (!variant || variant.stock < item.quantity) {
                return res.status(400).json({
                    msg: `Sản phẩm ${productDoc.name} (Màu: ${item.selectedColor}, Size: ${item.selectedSize}) không đủ hàng trong kho`
                });
            }

            variant.stock -= item.quantity;
            await productDoc.save();

            products.push({
                product: item.product._id,
                quantity: item.quantity,
                selectedColor: item.selectedColor,
                selectedSize: item.selectedSize,
            });
        }

        let order = new Order({
            userId: req.user,
            products: products,
            totalPrice: totalPrice,
            address: address,
            voucherCode: voucherCode || '',
            discountAmount: discountAmount || 0,
            shippingFee: shippingFee || 0,
            status: 0,
        });

        order = await order.save();

        // Clear user cart
        let user = await User.findById(req.user);
        user.cart = [];
        await user.save();

        // Create notification
        await createNotification(
            req.user,
            'Đặt hàng thành công',
            `Đơn hàng #${order._id.toString().slice(-6).toUpperCase()} đã được tiếp nhận.`,
            order._id
        );

        res.json(order);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Get My Orders
orderRouter.get('/my-orders', auth, async (req, res) => {
    try {
        const orders = await Order.find({ userId: req.user })
            .populate('products.product')
            .sort({ createdAt: -1 });
        res.json(orders);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Get All Orders (Admin)
orderRouter.get('/', auth, admin, async (req, res) => {
    try {
        const orders = await Order.find({})
            .sort({ createdAt: -1 })
            .populate('products.product')
            .populate('userId', 'name email');
        res.json(orders);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Update Order Status
orderRouter.put('/:id/status', auth, async (req, res) => {
    try {
        const { status } = req.body;
        let order = await Order.findById(req.params.id);

        if (!order) {
            return res.status(404).json({ msg: "Order not found" });
        }

        const user = await User.findById(req.user);
        const isAdmin = user && user.type === 'admin';

        let oldStatus = order.status;
        const newStatus = Number(status);

        if (isAdmin) {
            if (status !== undefined) order.status = newStatus;
            if (req.body.trackingNumber !== undefined) {
                order.trackingNumber = req.body.trackingNumber;
            } else if (newStatus === 2 && !order.trackingNumber) {
                // Simulate GHN/GHTK Tracking ID
                const randomId = crypto.randomBytes(4).toString('hex').toUpperCase();
                order.trackingNumber = `GHN${randomId}`;
            }
        } else {
            const isOwner = order.userId.toString() === req.user;
            if (newStatus === 3 && order.status === 2 && isOwner) {
                order.status = 3;
            } else if (newStatus === 4 && (order.status === 0 || order.status === 1) && isOwner) {
                order.status = 4;
            } else {
                console.log(`Update Rejected: user=${req.user}, order=${order._id}, target=${newStatus}, current=${order.status}, isOwner=${isOwner}`);
                return res.status(403).json({
                    msg: isOwner
                        ? "Không thể hủy đơn hàng ở trạng thái hiện tại."
                        : "Bạn không có quyền cập nhật đơn hàng này."
                });
            }
        }

        // Restore stock if cancelled
        if (order.status === 4 && oldStatus !== 4) {
            console.log(`Restoring stock for cancelled order: ${order._id}`);
            for (const item of order.products) {
                const product = await Product.findById(item.product);
                if (product) {
                    const variant = product.variants.find(
                        v => v.color === item.selectedColor && v.size === item.selectedSize
                    );
                    if (variant) {
                        variant.stock += item.quantity;
                        await product.save();
                    }
                }
            }
        }

        await order.save();

        // Notify user if status changed
        if (oldStatus !== order.status) {
            let title = '';
            let message = '';
            const orderIdShort = order._id.toString().slice(-6).toUpperCase();

            switch (order.status) {
                case 1:
                    title = 'Đã xác nhận thanh toán';
                    message = `Đơn hàng #${orderIdShort} của bạn đã được xác nhận và đang được chuẩn bị.`;
                    break;
                case 2:
                    title = 'Đang giao hàng';
                    message = `Đơn hàng #${orderIdShort} đã được giao cho đơn vị vận chuyển. Mã vận đơn: ${order.trackingNumber}`;
                    break;
                case 3:
                    title = 'Giao hàng thành công';
                    message = `Đơn hàng #${orderIdShort} đã được giao thành công. Cảm ơn bạn đã mua sắm!`;
                    break;
                case 4:
                    title = 'Đơn hàng đã hủy';
                    message = `Đơn hàng #${orderIdShort} của bạn đã được hủy thành công.`;
                    break;
            }

            if (title) {
                await createNotification(order.userId, title, message, order._id);
            }
        }

        res.json(order);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

module.exports = orderRouter;

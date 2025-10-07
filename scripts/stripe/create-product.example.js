// Example script: create a test product and price in Stripe
// Usage: STRIPE_SECRET_KEY=sk_test_xxx node scripts/stripe/create-product.example.js

const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY || '');

async function createProductAndPrice() {
  if (!process.env.STRIPE_SECRET_KEY) {
    console.error('Missing STRIPE_SECRET_KEY in environment');
    process.exit(1);
  }

  try {
    const product = await stripe.products.create({
      name: 'Test Product',
      description: 'A test product for $1',
    });

    const price = await stripe.prices.create({
      unit_amount: 100,
      currency: 'usd',
      product: product.id,
    });

    console.log('Product created:', product.id);
    console.log('Price created:', price.id);
  } catch (error) {
    console.error('Error creating product and price:', error);
    process.exit(1);
  }
}

createProductAndPrice();

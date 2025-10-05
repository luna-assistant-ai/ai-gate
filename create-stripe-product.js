const stripe = require('stripe')('sk_test_YOUR_SECRET_KEY');

async function createProductAndPrice() {
  try {
    // Create a product
    const product = await stripe.products.create({
      name: 'Test Product',
      description: 'A test product for $1',
    });

    // Create a price for the product
    const price = await stripe.prices.create({
      unit_amount: 100, // $1.00
      currency: 'usd',
      product: product.id,
    });

    console.log('Product created:', product.id);
    console.log('Price created:', price.id);
  } catch (error) {
    console.error('Error creating product and price:', error);
  }
}

createProductAndPrice();

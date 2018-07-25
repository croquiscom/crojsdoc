const express = require('express');
const app = express();

/**
 * Get list of users
 * @restapi GET /users
 * @return {Array<Object>} list of users
 * @returnprop {String} name user's name
 * @returnprop {Number} age user's age
 */
app.get('/users', (req, res) => {
  res.json([
    { name: 'John Doe', age: 30 },
    { name: 'Bill Smith', age: 23 },
  ]);
});

/**
 * Create a new user
 * @restapi POST /users
 * @param {String} name user's name
 * @param {Number} age user's age
 * @return {Object} information of created user
 * @returnprop {Number} id user record ID
 */
app.post('/users', (req, res) => {
  res.json({ id: 1 });
});

app.listen(3000);

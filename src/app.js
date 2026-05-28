const express    = require('express');
const todoRoutes = require('./routes/todos');

const app = express();
app.use(express.json());
app.use('/api/todos', todoRoutes);

module.exports = app;

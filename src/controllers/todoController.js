let todos  = [];
let nextId = 1;

exports.getAll = (req, res) => res.json(todos);

exports.create = (req, res) => {
  const todo = { id: nextId++, text: req.body.text, done: false };
  todos.push(todo);
  res.status(201).json(todo);
};

exports.remove = (req, res) => {
  todos = todos.filter(t => t.id !== +req.params.id);
  res.status(204).send();
};

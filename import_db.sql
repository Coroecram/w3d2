CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  f_name VARCHAR(255) NOT NULL,
  l_name VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body VARCHAR(255) NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  body VARCHAR(255) NOT NULL,
  question_id INTEGER NOT NULL,
  parent_id INTEGER,
  user_id INTEGER NOT NULL,


  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users (f_name, l_name)
VALUES
('Guy', 'Jones'), ('Lady', 'Here'), ('Third', 'Cat');

INSERT INTO
  questions (title, body, user_id)
VALUES
  ('Meow?', 'Meow, meow?', (SELECT id FROM users WHERE f_name = 'Third')),
  ('Where?', 'Where am I?', (SELECT id FROM users WHERE f_name = 'Guy')),
  ('Why?', 'Why?!?!?', (SELECT id FROM users WHERE f_name = 'Lady'));

INSERT INTO
  question_follows (user_id, question_id)
VALUES
  ((SELECT id FROM users WHERE f_name = 'Lady'), (SELECT id FROM questions WHERE title = 'Where?')),
  ((SELECT id FROM users WHERE f_name = 'Third'), (SELECT id FROM questions WHERE title = 'Where?')),
  ((SELECT id FROM users WHERE f_name = 'Guy'), (SELECT id FROM questions WHERE title = 'Meow?'));

INSERT INTO
  replies (body, question_id, parent_id, user_id)
VALUES
  ("HISS", (SELECT id FROM questions WHERE title = 'Meow?'), NULL,  (SELECT id FROM users WHERE f_name = 'Lady'));

INSERT INTO
  replies (body, question_id, parent_id, user_id)
VALUES
  ("What's your problem?", (SELECT id FROM questions WHERE title = 'Meow?'), (SELECT id FROM replies WHERE body = 'HISS'),  (SELECT id FROM users WHERE f_name = 'Guy')),
  ("HISSHISS", (SELECT id FROM questions WHERE title = 'Meow?'), (SELECT id FROM replies WHERE body = 'HISS'),  (SELECT id FROM users WHERE f_name = 'Third'));

INSERT INTO
  question_likes (user_id, question_id)
VALUES
  ((SELECT id FROM users WHERE f_name = 'Third'), (SELECT id FROM questions WHERE body = 'Why?!?!?')),
  ((SELECT id FROM users WHERE f_name = 'Lady'), (SELECT id FROM questions WHERE body = 'Why?!?!?')),
  ((SELECT id FROM users WHERE f_name = 'Guy'), (SELECT id FROM questions WHERE title = 'Meow?'));

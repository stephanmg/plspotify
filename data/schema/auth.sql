create table if not exists users (
  id integer primary key autoincrement,
  user string not null,
  pass string not null,
  email string,
  about string
);

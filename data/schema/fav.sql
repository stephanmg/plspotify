create table if not exists favorites (
  id integer primary key autoincrement,
  name string not null,
  user string not null,
  red integer not null,
  green integer not null,
  blue integer not null
);

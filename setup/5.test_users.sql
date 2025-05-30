--  ---------------------------------
--  -       MIKROTIK USERS          -
--  ---------------------------------

INSERT INTO radgroupreply (groupname, attribute, op, value) values ("MikrotikFull", "Mikrotik-Group", ":=", "full");
INSERT INTO radgroupreply (groupname, attribute, op, value) values ("MikrotikWrite", "Mikrotik-Group", ":=", "write");
INSERT INTO radgroupreply (groupname, attribute, op, value) values ("MikrotikRead", "Mikrotik-Group", ":=", "read");
INSERT INTO radcheck (UserName, Attribute, op, Value) values("bob", "Cleartext-Password", ":=", "hello");
INSERT INTO radcheck (UserName, Attribute, op, Value) values("alice", "Cleartext-Password", ":=", "hello");
INSERT INTO radcheck (UserName, Attribute, op, Value) values("peter", "Cleartext-Password", ":=", "hello");
INSERT INTO radusergroup (username, groupname, priority) values ("bob", "MikrotikFull", 10);
INSERT INTO radusergroup (username, groupname, priority) values ("alice", "MikrotikWrite", 10);
INSERT INTO radusergroup (username, groupname, priority) values ("peter", "MikrotikRead", 10);

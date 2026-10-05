-- Ambuscade, custom wave run (modules/custom/ambuscade/): the private instance, one wing of
-- Maquette Abdhaljs-Legion B (zone 287), entered from the Ambuscade Tome in Mhaura (zone 249).
-- time_limit is unused (each run keeps its own clock); the instance closes when nobody is inside.
-- Re-run by dbtool on every update, and sql/instance_list.sql re-imports drop the table, so REPLACE keeps it safe.
REPLACE INTO `instance_list` VALUES (30100,'ambuscade_waves',287,249,NULL,240,142.000,12.000,-142.000,32,NULL,NULL,NULL,NULL);

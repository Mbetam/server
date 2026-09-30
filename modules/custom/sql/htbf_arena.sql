-- Boss arenas for Rem's Tales (modules/custom/htbf/): the private arena instance, one wing of
-- Maquette Abdhaljs-Legion A (zone 183), entered from the Battle Archivist in Western Adoulin (zone 256).
-- time_limit is unused (each boss has its own 30 minutes); the arena closes when nobody is inside.
-- Re-run by dbtool on every update, and sql/instance_list.sql re-imports drop the table, so REPLACE keeps it safe.
REPLACE INTO `instance_list` VALUES (18300,'htbf_arena',183,256,NULL,240,142.000,12.000,-142.000,32,NULL,NULL,NULL,NULL);

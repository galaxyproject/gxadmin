--- ---
--- added_in: 1
--- contributors: hexylena
--- description: 40 recently registered users
--- ---
--- Returns 40 most recently registered users
---
---     $ gxadmin query latest-users
---      id |          create_time          | disk_usage | username |     email      |              groups               | active
---     ----+-------------------------------+------------+----------+----------------+-----------------------------------+--------
---       3 | 2019-03-07 13:06:37.945403+00 |            | beverly  | b@example.com  |                                   | t
---       2 | 2019-03-07 13:06:23.369201+00 | 826 bytes  | alice    | a@example.com  |                                   | t
---       1 | 2018-11-19 14:54:30.969713+00 | 869 MB     | helena   | hxr@local.host | training-asdf training-hogeschool | t
---     (3 rows)

SELECT
	id,
	create_time AT TIME ZONE 'UTC' as create_time,
	pg_size_pretty(disk_usage) as disk_usage,
	$username,
	$email,
	array_to_string(ARRAY(
		select galaxy_group.name from galaxy_group where id in (
			select group_id from user_group_association where user_group_association.user_id = galaxy_user.id
		)
	), ' ') as groups,
	active
FROM galaxy_user
ORDER BY create_time desc
LIMIT 40

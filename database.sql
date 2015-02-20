DROP TABLE IF EXISTS `groups`;
CREATE TABLE `groups` (
	`id` INT NOT NULL PRIMARY KEY,
    `name` VARCHAR(20) NOT NULL,
    `displayName` VARCHAR(50) NOT NULL
) ENGINE = MyISAM CHARSET = utf8;
INSERT INTO `groups` VALUES(0, 'haixiuzu', '请不要害羞');
INSERT INTO `groups` VALUES(1, 'Xsz', '不羞射小组');

-- STATE: 0(downloading), 1(error), 2(done), 3(removed)
DROP TABLE IF EXISTS `topics`;
CREATE TABLE `topics` (
	`id` INT NOT NULL PRIMARY KEY,
	`group` INT NOT NULL,
	`author` VARCHAR(50) NOT NULL,
	`timestamp` INT NOT NULL,
	`state` INT NOT NULL,
	`pictures` INT NOT NULL,
	`title` VARCHAR(100),
	`thumbUrl` VARCHAR(100)
) ENGINE = InnoDB CHARSET = utf8;
CREATE INDEX `group_state` ON `topics`(`group`, `state`);

DROP TABLE  IF EXISTS `contents`;
CREATE TABLE `contents` (
	`id` INT NOT NULL PRIMARY KEY,
	`content` TEXT
) ENGINE = MyISAM CHARSET = utf8;

DROP TABLE IF EXISTS `people`;
CREATE TABLE `people` (
	`id` varchar(50) NOT NULL PRIMARY KEY,
	`name` VARCHAR(100) NOT NULL
) ENGINE = InnoDB CHARSET = utf8;

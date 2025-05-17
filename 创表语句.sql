/*
 Navicat Premium Dump SQL

 Source Server         : Edu_Sphere
 Source Server Type    : MySQL
 Source Server Version : 80037 (8.0.37)
 Source Host           : 10.168.89.204:3306
 Source Schema         : Edu_Sphere

 Target Server Type    : MySQL
 Target Server Version : 80037 (8.0.37)
 File Encoding         : 65001

 Date: 17/05/2025 23:01:10
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for class_students
-- ----------------------------
DROP TABLE IF EXISTS `class_students`;
CREATE TABLE `class_students`  (
                                   `id` int NOT NULL AUTO_INCREMENT COMMENT '关联id',
                                   `class_id` int NULL DEFAULT NULL COMMENT '班级id',
                                   `student_id` bigint NULL DEFAULT NULL COMMENT '学生id',
                                   PRIMARY KEY (`id`) USING BTREE,
                                   INDEX `fk_cs_class`(`class_id` ASC) USING BTREE,
                                   INDEX `fk_cs_student`(`student_id` ASC) USING BTREE,
                                   CONSTRAINT `fk_cs_class` FOREIGN KEY (`class_id`) REFERENCES `classes` (`class_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
                                   CONSTRAINT `fk_cs_student` FOREIGN KEY (`student_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '班级学生关联表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of class_students
-- ----------------------------
INSERT INTO `class_students` VALUES (1, 1, 3);
INSERT INTO `class_students` VALUES (2, 1, 4);
INSERT INTO `class_students` VALUES (3, 1, 5);
INSERT INTO `class_students` VALUES (4, 2, 6);
INSERT INTO `class_students` VALUES (5, 2, 7);
INSERT INTO `class_students` VALUES (6, 2, 8);
INSERT INTO `class_students` VALUES (7, 3, 3);
INSERT INTO `class_students` VALUES (8, 3, 4);
INSERT INTO `class_students` VALUES (9, 4, 5);
INSERT INTO `class_students` VALUES (10, 4, 6);
INSERT INTO `class_students` VALUES (13, 1, 6);
INSERT INTO `class_students` VALUES (14, 1, 7);
INSERT INTO `class_students` VALUES (15, 1, 8);

-- ----------------------------
-- Table structure for class_teachers
-- ----------------------------
DROP TABLE IF EXISTS `class_teachers`;
CREATE TABLE `class_teachers`  (
                                   `id` int NOT NULL AUTO_INCREMENT COMMENT '关联id',
                                   `class_id` int NULL DEFAULT NULL COMMENT '班级id',
                                   `teacher_id` bigint NULL DEFAULT NULL COMMENT '教师id',
                                   `subject_id` int NULL DEFAULT NULL COMMENT '学科id',
                                   PRIMARY KEY (`id`) USING BTREE,
                                   INDEX `fk_ct_class`(`class_id` ASC) USING BTREE,
                                   INDEX `fk_ct_teacher`(`teacher_id` ASC) USING BTREE,
                                   INDEX `fk_ct_subject`(`subject_id` ASC) USING BTREE,
                                   CONSTRAINT `fk_ct_class` FOREIGN KEY (`class_id`) REFERENCES `classes` (`class_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
                                   CONSTRAINT `fk_ct_subject` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`subject_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
                                   CONSTRAINT `fk_ct_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 35 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '班级教师关联表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of class_teachers
-- ----------------------------
INSERT INTO `class_teachers` VALUES (1, 1, 2, 1);
INSERT INTO `class_teachers` VALUES (2, 1, 1, 2);
INSERT INTO `class_teachers` VALUES (7, 1, 2, 3);
INSERT INTO `class_teachers` VALUES (31, 4, 1, 2);
INSERT INTO `class_teachers` VALUES (32, 3, 2, 2);
INSERT INTO `class_teachers` VALUES (33, 2, 1, 3);
INSERT INTO `class_teachers` VALUES (34, 2, 2, 1);

-- ----------------------------
-- Table structure for classes
-- ----------------------------
DROP TABLE IF EXISTS `classes`;
CREATE TABLE `classes`  (
                            `class_id` int NOT NULL AUTO_INCREMENT COMMENT '班级id',
                            `class_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '班级名称',
                            `grade` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '年级',
                            `head_teacher_id` bigint NULL DEFAULT NULL COMMENT '班主任id',
                            `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                            PRIMARY KEY (`class_id`) USING BTREE,
                            INDEX `fk_class_teacher`(`head_teacher_id` ASC) USING BTREE,
                            CONSTRAINT `fk_class_teacher` FOREIGN KEY (`head_teacher_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 15 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '班级表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of classes
-- ----------------------------
INSERT INTO `classes` VALUES (1, '高一(1)班', '高一', 2, '2025-05-14 10:19:41');
INSERT INTO `classes` VALUES (2, '高一(2)班', '高一', 2, '2025-05-14 10:19:41');
INSERT INTO `classes` VALUES (3, '高二(1)班', '高二', 1, '2025-05-14 10:19:41');
INSERT INTO `classes` VALUES (4, '高二(2)班', '高二', 1, '2025-05-14 10:19:41');

-- ----------------------------
-- Table structure for exam_scores
-- ----------------------------
DROP TABLE IF EXISTS `exam_scores`;
CREATE TABLE `exam_scores`  (
                                `score_id` bigint NOT NULL AUTO_INCREMENT COMMENT '成绩id',
                                `class_id` int NULL DEFAULT NULL COMMENT '班级id',
                                `student_id` bigint NULL DEFAULT NULL COMMENT '学生id',
                                `subject_id` int NULL DEFAULT NULL COMMENT '学科id',
                                `exam_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '考试名称',
                                `exam_date` date NULL DEFAULT NULL COMMENT '考试日期',
                                `score` decimal(5, 2) NULL DEFAULT NULL COMMENT '分数',
                                `grader_id` bigint NULL DEFAULT NULL COMMENT '批改教师id',
                                `comment` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '评语',
                                `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                                `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
                                PRIMARY KEY (`score_id`) USING BTREE,
                                INDEX `fk_es_class`(`class_id` ASC) USING BTREE,
                                INDEX `fk_es_student`(`student_id` ASC) USING BTREE,
                                INDEX `fk_es_subject`(`subject_id` ASC) USING BTREE,
                                INDEX `fk_es_grader`(`grader_id` ASC) USING BTREE,
                                CONSTRAINT `fk_es_class` FOREIGN KEY (`class_id`) REFERENCES `classes` (`class_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
                                CONSTRAINT `fk_es_grader` FOREIGN KEY (`grader_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
                                CONSTRAINT `fk_es_student` FOREIGN KEY (`student_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
                                CONSTRAINT `fk_es_subject` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`subject_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 29 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '考试成绩表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of exam_scores
-- ----------------------------
INSERT INTO `exam_scores` VALUES (1, 1, 3, 1, '第一次月考', '2023-09-30', 85.50, 2, '作文写得不错', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (2, 1, 4, 1, '第一次月考', '2023-09-30', 78.00, 2, '阅读理解有待提高', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (3, 1, 5, 1, '第一次月考', '2023-09-30', 92.00, 2, '表现优秀', '2025-05-14 10:19:41', '2025-05-17 21:57:30');
INSERT INTO `exam_scores` VALUES (4, 1, 3, 1, '期中考试', '2023-11-15', 88.00, 2, '进步明显', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (5, 1, 4, 1, '期中考试', '2023-11-15', 82.50, 2, '继续努力', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (6, 1, 5, 1, '期中考试', '2023-11-15', 90.50, 2, '保持稳定', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (7, 1, 3, 2, '第一次月考', '2023-09-30', 72.00, 1, '基础题要加强', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (8, 1, 4, 2, '第一次月考', '2023-09-30', 95.00, 1, '数学思维很好', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (9, 1, 5, 2, '第一次月考', '2023-09-30', 68.50, 1, '需要多练习', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (10, 1, 3, 2, '期中考试', '2023-11-15', 80.00, 1, '进步很大', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (11, 1, 4, 2, '期中考试', '2023-11-15', 98.00, 1, '非常优秀', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (12, 1, 5, 2, '期中考试', '2023-11-15', 75.00, 1, '有所进步', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (13, 2, 6, 1, '第一次月考', '2023-09-30', 90.00, 2, '文笔优美', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (14, 2, 7, 1, '第一次月考', '2023-09-30', 85.00, 2, '思路清晰', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (15, 2, 8, 1, '第一次月考', '2023-09-30', 78.20, 2, '字迹工整', '2025-05-14 10:19:41', '2025-05-14 15:40:39');
INSERT INTO `exam_scores` VALUES (16, 3, 3, 2, '期末考试', '2023-12-20', 87.00, 1, '古文理解深刻', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (17, 3, 4, 2, '期末考试', '2023-12-20', 91.00, 1, '作文有创意', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (18, 4, 5, 2, '模拟考试', '2023-10-15', 85.00, 1, '解题思路清晰', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (19, 4, 6, 2, '模拟考试', '2023-10-15', 92.00, 1, '发挥稳定', '2025-05-14 10:19:41', '2025-05-14 10:19:41');
INSERT INTO `exam_scores` VALUES (20, 2, 7, 3, '期末考', '2025-05-14', 65.00, 1, '加油哥们', '2025-05-14 15:48:17', '2025-05-14 15:48:17');
INSERT INTO `exam_scores` VALUES (23, 1, 3, 1, '五一前一考', '2025-04-24', 100.00, 2, '张三评语', '2025-05-17 22:56:16', '2025-05-17 22:56:16');
INSERT INTO `exam_scores` VALUES (24, 1, 4, 1, '五一前一考', '2025-04-24', 80.00, 2, '李四评语', '2025-05-17 22:56:16', '2025-05-17 22:56:16');
INSERT INTO `exam_scores` VALUES (25, 1, 5, 1, '五一前一考', '2025-04-24', 40.00, 2, '王五评语', '2025-05-17 22:56:17', '2025-05-17 22:56:17');
INSERT INTO `exam_scores` VALUES (26, 1, 6, 1, '五一前一考', '2025-04-24', 50.00, 2, '赵六评语', '2025-05-17 22:56:17', '2025-05-17 22:56:17');
INSERT INTO `exam_scores` VALUES (27, 1, 7, 1, '五一前一考', '2025-04-24', 60.00, 2, '钱七评语', '2025-05-17 22:56:17', '2025-05-17 22:56:17');
INSERT INTO `exam_scores` VALUES (28, 1, 8, 1, '五一前一考', '2025-04-24', 70.00, 2, '孙八评语', '2025-05-17 22:56:17', '2025-05-17 22:56:17');

-- ----------------------------
-- Table structure for powers
-- ----------------------------
DROP TABLE IF EXISTS `powers`;
CREATE TABLE `powers`  (
                           `power_id` int NOT NULL AUTO_INCREMENT COMMENT '权限id',
                           `power_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '中文名',
                           PRIMARY KEY (`power_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 35 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '权限的名字' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of powers
-- ----------------------------
INSERT INTO `powers` VALUES (1, '学生端进入');
INSERT INTO `powers` VALUES (2, '教师端进入');
INSERT INTO `powers` VALUES (3, '管理员端进入');
INSERT INTO `powers` VALUES (4, '查看所有用户信息');
INSERT INTO `powers` VALUES (5, '修改用户基础信息');
INSERT INTO `powers` VALUES (6, '修改用户密码');
INSERT INTO `powers` VALUES (7, '增加角色');
INSERT INTO `powers` VALUES (8, '查看所有角色信息');
INSERT INTO `powers` VALUES (9, '更新角色信息');
INSERT INTO `powers` VALUES (10, '删除角色');
INSERT INTO `powers` VALUES (11, '查看所有权限列表');
INSERT INTO `powers` VALUES (12, '增加角色');
INSERT INTO `powers` VALUES (13, '修改用户角色');
INSERT INTO `powers` VALUES (14, '删除用户');
INSERT INTO `powers` VALUES (15, '查看学生信息');
INSERT INTO `powers` VALUES (16, '查看教师信息');
INSERT INTO `powers` VALUES (17, '查看班级信息');
INSERT INTO `powers` VALUES (18, '管理学生成绩');
INSERT INTO `powers` VALUES (19, '查看成绩');
INSERT INTO `powers` VALUES (20, '管理班级');
INSERT INTO `powers` VALUES (21, '管理用户');
INSERT INTO `powers` VALUES (22, '管理角色');
INSERT INTO `powers` VALUES (23, '创建班级');
INSERT INTO `powers` VALUES (24, '任命班主任');
INSERT INTO `powers` VALUES (25, '添加学科教师');
INSERT INTO `powers` VALUES (26, '管理学科');
INSERT INTO `powers` VALUES (27, '查看教师班级');
INSERT INTO `powers` VALUES (28, '查看班级学生');
INSERT INTO `powers` VALUES (29, '查看班级成绩');
INSERT INTO `powers` VALUES (30, '更新学生成绩');
INSERT INTO `powers` VALUES (31, '提交学生成绩');
INSERT INTO `powers` VALUES (32, '查看学生班级');
INSERT INTO `powers` VALUES (33, '查看学生成绩');
INSERT INTO `powers` VALUES (34, '查看科目成绩');

-- ----------------------------
-- Table structure for role_power
-- ----------------------------
DROP TABLE IF EXISTS `role_power`;
CREATE TABLE `role_power`  (
                               `role_id` int NULL DEFAULT NULL COMMENT '角色id',
                               `power_id` int NULL DEFAULT NULL COMMENT '权限id'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '每个角色能做什么，一般来说给一个用户，返回一个权限集合吧' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of role_power
-- ----------------------------
INSERT INTO `role_power` VALUES (1, 1);
INSERT INTO `role_power` VALUES (1, 4);
INSERT INTO `role_power` VALUES (1, 5);
INSERT INTO `role_power` VALUES (1, 6);
INSERT INTO `role_power` VALUES (1, 7);
INSERT INTO `role_power` VALUES (1, 8);
INSERT INTO `role_power` VALUES (1, 9);
INSERT INTO `role_power` VALUES (1, 10);
INSERT INTO `role_power` VALUES (1, 11);
INSERT INTO `role_power` VALUES (1, 12);
INSERT INTO `role_power` VALUES (1, 13);
INSERT INTO `role_power` VALUES (1, 14);
INSERT INTO `role_power` VALUES (1, 15);
INSERT INTO `role_power` VALUES (1, 16);
INSERT INTO `role_power` VALUES (1, 17);
INSERT INTO `role_power` VALUES (1, 18);
INSERT INTO `role_power` VALUES (1, 19);
INSERT INTO `role_power` VALUES (1, 20);
INSERT INTO `role_power` VALUES (1, 21);
INSERT INTO `role_power` VALUES (1, 22);
INSERT INTO `role_power` VALUES (1, 23);
INSERT INTO `role_power` VALUES (1, 24);
INSERT INTO `role_power` VALUES (1, 25);
INSERT INTO `role_power` VALUES (1, 26);
INSERT INTO `role_power` VALUES (1, 27);
INSERT INTO `role_power` VALUES (1, 28);
INSERT INTO `role_power` VALUES (1, 29);
INSERT INTO `role_power` VALUES (1, 30);
INSERT INTO `role_power` VALUES (1, 31);
INSERT INTO `role_power` VALUES (1, 32);
INSERT INTO `role_power` VALUES (1, 33);
INSERT INTO `role_power` VALUES (1, 34);
INSERT INTO `role_power` VALUES (3, 1);
INSERT INTO `role_power` VALUES (3, 2);
INSERT INTO `role_power` VALUES (3, 3);
INSERT INTO `role_power` VALUES (3, 4);
INSERT INTO `role_power` VALUES (3, 5);
INSERT INTO `role_power` VALUES (3, 6);
INSERT INTO `role_power` VALUES (3, 7);
INSERT INTO `role_power` VALUES (3, 8);
INSERT INTO `role_power` VALUES (3, 9);
INSERT INTO `role_power` VALUES (3, 10);
INSERT INTO `role_power` VALUES (3, 11);
INSERT INTO `role_power` VALUES (3, 12);
INSERT INTO `role_power` VALUES (3, 13);
INSERT INTO `role_power` VALUES (3, 14);
INSERT INTO `role_power` VALUES (3, 15);
INSERT INTO `role_power` VALUES (3, 16);
INSERT INTO `role_power` VALUES (3, 17);
INSERT INTO `role_power` VALUES (3, 18);
INSERT INTO `role_power` VALUES (3, 19);
INSERT INTO `role_power` VALUES (3, 20);
INSERT INTO `role_power` VALUES (3, 21);
INSERT INTO `role_power` VALUES (3, 22);
INSERT INTO `role_power` VALUES (3, 23);
INSERT INTO `role_power` VALUES (3, 24);
INSERT INTO `role_power` VALUES (3, 25);
INSERT INTO `role_power` VALUES (3, 26);
INSERT INTO `role_power` VALUES (3, 27);
INSERT INTO `role_power` VALUES (3, 28);
INSERT INTO `role_power` VALUES (3, 29);
INSERT INTO `role_power` VALUES (3, 30);
INSERT INTO `role_power` VALUES (3, 31);
INSERT INTO `role_power` VALUES (3, 32);
INSERT INTO `role_power` VALUES (3, 33);
INSERT INTO `role_power` VALUES (3, 34);
INSERT INTO `role_power` VALUES (2, 1);
INSERT INTO `role_power` VALUES (2, 2);
INSERT INTO `role_power` VALUES (2, 4);
INSERT INTO `role_power` VALUES (2, 5);
INSERT INTO `role_power` VALUES (2, 6);
INSERT INTO `role_power` VALUES (2, 7);
INSERT INTO `role_power` VALUES (2, 8);
INSERT INTO `role_power` VALUES (2, 9);
INSERT INTO `role_power` VALUES (2, 10);
INSERT INTO `role_power` VALUES (2, 11);
INSERT INTO `role_power` VALUES (2, 12);
INSERT INTO `role_power` VALUES (2, 13);
INSERT INTO `role_power` VALUES (2, 14);
INSERT INTO `role_power` VALUES (2, 15);
INSERT INTO `role_power` VALUES (2, 16);
INSERT INTO `role_power` VALUES (2, 17);
INSERT INTO `role_power` VALUES (2, 18);
INSERT INTO `role_power` VALUES (2, 19);
INSERT INTO `role_power` VALUES (2, 20);
INSERT INTO `role_power` VALUES (2, 21);
INSERT INTO `role_power` VALUES (2, 22);
INSERT INTO `role_power` VALUES (2, 23);
INSERT INTO `role_power` VALUES (2, 24);
INSERT INTO `role_power` VALUES (2, 25);
INSERT INTO `role_power` VALUES (2, 26);
INSERT INTO `role_power` VALUES (2, 27);
INSERT INTO `role_power` VALUES (2, 28);
INSERT INTO `role_power` VALUES (2, 29);
INSERT INTO `role_power` VALUES (2, 30);
INSERT INTO `role_power` VALUES (2, 31);
INSERT INTO `role_power` VALUES (2, 32);
INSERT INTO `role_power` VALUES (2, 33);
INSERT INTO `role_power` VALUES (2, 34);
INSERT INTO `role_power` VALUES (9, 32);
INSERT INTO `role_power` VALUES (9, 33);
INSERT INTO `role_power` VALUES (9, 1);
INSERT INTO `role_power` VALUES (9, 34);
INSERT INTO `role_power` VALUES (9, 2);
INSERT INTO `role_power` VALUES (9, 4);
INSERT INTO `role_power` VALUES (9, 5);
INSERT INTO `role_power` VALUES (9, 6);
INSERT INTO `role_power` VALUES (9, 9);
INSERT INTO `role_power` VALUES (9, 10);
INSERT INTO `role_power` VALUES (9, 11);
INSERT INTO `role_power` VALUES (9, 25);
INSERT INTO `role_power` VALUES (9, 26);
INSERT INTO `role_power` VALUES (9, 27);
INSERT INTO `role_power` VALUES (9, 28);
INSERT INTO `role_power` VALUES (9, 29);
INSERT INTO `role_power` VALUES (9, 30);
INSERT INTO `role_power` VALUES (9, 31);

-- ----------------------------
-- Table structure for role_user
-- ----------------------------
DROP TABLE IF EXISTS `role_user`;
CREATE TABLE `role_user`  (
                              `user_id` int NULL DEFAULT NULL COMMENT '用户id',
                              `role_id` int NULL DEFAULT NULL COMMENT '角色id'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户和角色的对应表，一个用户可以有多个角色' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of role_user
-- ----------------------------
INSERT INTO `role_user` VALUES (1, 3);
INSERT INTO `role_user` VALUES (1, 2);
INSERT INTO `role_user` VALUES (1, 3);
INSERT INTO `role_user` VALUES (1, 2);
INSERT INTO `role_user` VALUES (4, 1);
INSERT INTO `role_user` VALUES (5, 1);
INSERT INTO `role_user` VALUES (6, 1);
INSERT INTO `role_user` VALUES (7, 1);
INSERT INTO `role_user` VALUES (8, 1);
INSERT INTO `role_user` VALUES (2, 2);
INSERT INTO `role_user` VALUES (2, 9);
INSERT INTO `role_user` VALUES (3, 1);

-- ----------------------------
-- Table structure for roles
-- ----------------------------
DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles`  (
                          `role_id` bigint NOT NULL AUTO_INCREMENT COMMENT '角色id',
                          `role_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '中文名',
                          PRIMARY KEY (`role_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '角色的名字，以免忘记' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of roles
-- ----------------------------
INSERT INTO `roles` VALUES (1, '学生');
INSERT INTO `roles` VALUES (2, '教师');
INSERT INTO `roles` VALUES (3, '管理员');
INSERT INTO `roles` VALUES (4, '首页处注册用户');
INSERT INTO `roles` VALUES (5, '管理员新增用户');
INSERT INTO `roles` VALUES (6, '数学老师');
INSERT INTO `roles` VALUES (7, '英语老师');
INSERT INTO `roles` VALUES (8, '计算机老师');
INSERT INTO `roles` VALUES (9, '班主任');
INSERT INTO `roles` VALUES (10, '无权限人员');
INSERT INTO `roles` VALUES (11, '数学老师');
INSERT INTO `roles` VALUES (12, '英语老师');
INSERT INTO `roles` VALUES (13, '计算机老师');
INSERT INTO `roles` VALUES (14, '班主任');
INSERT INTO `roles` VALUES (15, '无权限人员');

-- ----------------------------
-- Table structure for subjects
-- ----------------------------
DROP TABLE IF EXISTS `subjects`;
CREATE TABLE `subjects`  (
                             `subject_id` int NOT NULL AUTO_INCREMENT COMMENT '学科id',
                             `subject_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '学科名称',
                             `subject_desc` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '学科描述',
                             `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                             PRIMARY KEY (`subject_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 12 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '学科表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of subjects
-- ----------------------------
INSERT INTO `subjects` VALUES (1, '语文', '语言文学课程', '2025-05-14 10:19:41');
INSERT INTO `subjects` VALUES (2, '数学', '数学基础课程', '2025-05-14 10:19:41');
INSERT INTO `subjects` VALUES (3, '英语', '英语语言课程', '2025-05-14 10:19:41');
INSERT INTO `subjects` VALUES (4, '物理', '物理科学课程', '2025-05-14 10:19:41');
INSERT INTO `subjects` VALUES (5, '化学', '化学科学课程', '2025-05-14 10:19:41');
INSERT INTO `subjects` VALUES (6, '生物', '生物科学课程', '2025-05-14 10:19:41');
INSERT INTO `subjects` VALUES (7, '计算机', '计算机科学课程', '2025-05-14 10:19:41');
INSERT INTO `subjects` VALUES (9, '美术', '艺术是必不可少的', '2025-05-15 16:46:27');
INSERT INTO `subjects` VALUES (10, 'HCIA', '鲲鹏技术产业', '2025-05-15 16:47:27');
INSERT INTO `subjects` VALUES (11, '电路板的研究', '针对于电路板的研究', '2025-05-15 16:56:05');

-- ----------------------------
-- Table structure for user_information
-- ----------------------------
DROP TABLE IF EXISTS `user_information`;
CREATE TABLE `user_information`  (
                                     `user_id` bigint NOT NULL COMMENT '用户id，链接users表内user_id',
                                     `user_nick_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '用户昵称',
                                     `user_gender` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '用户性别',
                                     `user_birthday` date NULL DEFAULT NULL COMMENT 'YYYY-MM-DD，用户生日',
                                     `user_personalized_signature` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '用户个性签名',
                                     `user_profile_picture` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '用户头像',
                                     PRIMARY KEY (`user_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of user_information
-- ----------------------------
INSERT INTO `user_information` VALUES (1, '听风起', '男', '2004-05-25', '帮我点杯咖啡，多点奶少点糖', 'https://thirdwx.qlogo.cn/mmopen/vi_32/hQoOP719jarWIicoBGJoqLkju7oicBOtuZempcjbzQXibqnIWWF1BnTHfiaQujUHTSR4ocWz66c9CqcRl7ic8BbAg9Vt6j0TBIfyQib39ibCnKtxvQ/132');
INSERT INTO `user_information` VALUES (2, NULL, NULL, NULL, NULL, 'https://wework.qpic.cn/wwpic3az/422947_JYGyUUsyQNiZdw8_1710503243/0');
INSERT INTO `user_information` VALUES (3, '三儿', '男', '2005-09-01', '好好学习', 'https://thirdwx.qlogo.cn/mmopen/vi_32/hQoOP719jarWIicoBGJoqLkju7oicBOtuZempcjbzQXibqnIWWF1BnTHfiaQujUHTSR4ocWz66c9CqcRl7ic8BbAg9Vt6j0TBIfyQib39ibCnKtxvQ/132');
INSERT INTO `user_information` VALUES (4, '小四', '女', '2005-10-15', '天天向上', 'https://wework.qpic.cn/wwpic3az/422947_JYGyUUsyQNiZdw8_1710503243/0');
INSERT INTO `user_information` VALUES (5, '五哥', '男', '2006-02-20', '努力就有收获', 'https://thirdwx.qlogo.cn/mmopen/vi_32/hQoOP719jarWIicoBGJoqLkju7oicBOtuZempcjbzQXibqnIWWF1BnTHfiaQujUHTSR4ocWz66c9CqcRl7ic8BbAg9Vt6j0TBIfyQib39ibCnKtxvQ/132');
INSERT INTO `user_information` VALUES (6, '六六', '女', '2006-04-05', '知识改变命运', 'https://wework.qpic.cn/wwpic3az/422947_JYGyUUsyQNiZdw8_1710503243/0');
INSERT INTO `user_information` VALUES (7, '小七', '男', '2005-12-12', '学无止境', 'https://thirdwx.qlogo.cn/mmopen/vi_32/hQoOP719jarWIicoBGJoqLkju7oicBOtuZempcjbzQXibqnIWWF1BnTHfiaQujUHTSR4ocWz66c9CqcRl7ic8BbAg9Vt6j0TBIfyQib39ibCnKtxvQ/132');
INSERT INTO `user_information` VALUES (8, '八爷', '男', '2005-08-08', '勤奋是成功之母', 'https://wework.qpic.cn/wwpic3az/422947_JYGyUUsyQNiZdw8_1710503243/0');

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users`  (
                          `user_id` bigint NOT NULL AUTO_INCREMENT COMMENT '用户id',
                          `user_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '用户名',
                          `user_email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '电子邮件',
                          `user_password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '用户密码',
                          `user_token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '当前密钥',
                          `user_number` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '用户号，一般来说以这个为登录号会更加合理。比如说我的学生证卡号。',
                          PRIMARY KEY (`user_id`) USING BTREE,
                          UNIQUE INDEX `users_pk`(`user_name` ASC) USING BTREE,
                          UNIQUE INDEX `users_pk_2`(`user_email` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of users
-- ----------------------------
INSERT INTO `users` VALUES (1, '李氏民', '3115089759@qq.com', 'Huawei@123', '106b3d3b-b34e-40df-94e2-1aa5cc11d890', '3122230220');
INSERT INTO `users` VALUES (2, '李翔', '3122230200@gnust.edu.cn', 'Huawei@123', 'c22d0a99-4e18-4e43-bbf6-17aff8d617c5', '3122230200');
INSERT INTO `users` VALUES (3, '张三', 'zhangsan@school.com', 'Huawei@123', 'student_token_1', 'S3001');
INSERT INTO `users` VALUES (4, '李四', 'lisi@school.com', 'Huawei@123', 'student_token_2', 'S3002');
INSERT INTO `users` VALUES (5, '王五', 'wangwu@school.com', 'Huawei@123', 'd44bfd47-7c9e-4784-a3e7-3edefdf401e6', 'S3003');
INSERT INTO `users` VALUES (6, '赵六', 'zhaoliu@school.com', 'Huawei@123', 'student_token_4', 'S3004');
INSERT INTO `users` VALUES (7, '钱七', 'qianqi@school.com', 'Huawei@123', 'student_token_5', 'S3005');
INSERT INTO `users` VALUES (8, '孙八', 'sunba@school.com', 'Huawei@123', 'student_token_6', 'S3006');

-- ----------------------------
-- Table structure for verification_codes
-- ----------------------------
DROP TABLE IF EXISTS `verification_codes`;
CREATE TABLE `verification_codes`  (
                                       `code_id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键，验证码id',
                                       `code_number` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '验证码内容',
                                       `code_email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '邮箱',
                                       `expiry_date` datetime(6) NOT NULL COMMENT '过期时间',
                                       `code_purpose` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '验证码用途',
                                       PRIMARY KEY (`code_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '验证码表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of verification_codes
-- ----------------------------

SET FOREIGN_KEY_CHECKS = 1;

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

 Date: 12/05/2025 21:19:52
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for powers
-- ----------------------------
DROP TABLE IF EXISTS `powers`;
CREATE TABLE `powers`  (
                           `power_id` int NOT NULL AUTO_INCREMENT COMMENT '权限id',
                           `power_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '中文名',
                           PRIMARY KEY (`power_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '权限的名字' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of powers
-- ----------------------------
INSERT INTO `powers` VALUES (null, '学生端进入');
INSERT INTO `powers` VALUES (null, '教师端进入');
INSERT INTO `powers` VALUES (null, '管理员端进入');
INSERT INTO `powers` VALUES (null, '查看所有用户信息');
INSERT INTO `powers` VALUES (null, '修改用户基础信息');
INSERT INTO `powers` VALUES (null, '修改用户密码');
INSERT INTO `powers` VALUES (null, '增加角色');
INSERT INTO `powers` VALUES (null, '查看所有角色信息');
INSERT INTO `powers` VALUES (null, '更新角色信息');
INSERT INTO `powers` VALUES (null, '删除角色');
INSERT INTO `powers` VALUES (null, '查看所有权限列表');
INSERT INTO `powers` VALUES (null, '增加角色');
INSERT INTO `powers` VALUES (null, '修改用户角色');
INSERT INTO `powers` VALUES (null, '删除用户');

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
INSERT INTO `role_power` VALUES (2, 1);
INSERT INTO `role_power` VALUES (2, 2);
INSERT INTO `role_power` VALUES (2, 13);
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
INSERT INTO `role_power` VALUES (9, 1);
INSERT INTO `role_power` VALUES (9, 2);

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

-- ----------------------------
-- Table structure for roles
-- ----------------------------
DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles`  (
                          `role_id` bigint NOT NULL AUTO_INCREMENT COMMENT '角色id',
                          `role_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '中文名',
                          PRIMARY KEY (`role_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '角色的名字，以免忘记' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of roles
-- ----------------------------
INSERT INTO `roles` VALUES (null, '学生');
INSERT INTO `roles` VALUES (null, '教师');
INSERT INTO `roles` VALUES (null, '管理员');
INSERT INTO `roles` VALUES (null, '首页处注册用户');
INSERT INTO `roles` VALUES (null, '管理员新增用户');
INSERT INTO `roles` VALUES (null, '数学老师');
INSERT INTO `roles` VALUES (null, '英语老师');
INSERT INTO `roles` VALUES (null, '计算机老师');
INSERT INTO `roles` VALUES (null, '班主任');
INSERT INTO `roles` VALUES (null, '无权限人员');

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
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user_information
-- ----------------------------
INSERT INTO `user_information` VALUES (1, '听风起', '男', '2004-05-25', '帮我点杯咖啡，多点奶少点糖', 'https://thirdwx.qlogo.cn/mmopen/vi_32/hQoOP719jarWIicoBGJoqLkju7oicBOtuZempcjbzQXibqnIWWF1BnTHfiaQujUHTSR4ocWz66c9CqcRl7ic8BbAg9Vt6j0TBIfyQib39ibCnKtxvQ/132');
INSERT INTO `user_information` VALUES (2, NULL, NULL, NULL, NULL, 'https://wework.qpic.cn/wwpic3az/422947_JYGyUUsyQNiZdw8_1710503243/0');

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
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of users
-- ----------------------------
INSERT INTO `users` VALUES (1, '李氏民', '3115089759@qq.com', 'Huawei@123', 'f9e91d57-cb64-48f1-bc43-5ea001214e29', '3122230220');
INSERT INTO `users` VALUES (2, '张三', '3122230200@gnust.edu.cn', '3122230222', '94b1d021-a490-4969-9eff-63d0dc286ec1', '3122230200');

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
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '验证码表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of verification_codes
-- ----------------------------

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE `users`
(
    `id`         bigint       NOT NULL AUTO_INCREMENT,
    `created_at` varchar(255) DEFAULT NULL,
    `email`      varchar(255) NOT NULL,
    `password`   varchar(255) NOT NULL,
    `role_id`    int          NOT NULL,
    `updated_at` varchar(255) DEFAULT NULL,
    `user_name`  varchar(255) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `UK6dotkott2kjsp8vw4d0m25fb7` (`email`),
    UNIQUE KEY `UKk8d0f2n7n88w1a16yhua64onx` (`user_name`)
) ENGINE = InnoDB
  AUTO_INCREMENT = 4
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;


CREATE TABLE `verification_codes`
(
    `id`          bigint       NOT NULL AUTO_INCREMENT,
    `code`        varchar(255) NOT NULL,
    `email`       varchar(255) NOT NULL,
    `expiry_date` datetime(6)  NOT NULL,
    `purpose`     varchar(255) NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE = InnoDB
  AUTO_INCREMENT = 9
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;
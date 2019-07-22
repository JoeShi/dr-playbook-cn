# AWS 灾备解决方案

## 目录结构

- basic: 基础网络结构。可用户建设灾备区域基础网络架构, 基础配置。 包含如下架构：
  * VPC
  * Subnet
  * Security Group 
  * DB Subnet Group & Cache Subnet group
  * Route Table
 
- database: 数据库相关内容。帮助用户自动创建RDS
 
- app：应用相关资源。
  * Redis
  * ELB
  * NAT
  * Route table
  * Launch Template
  * Auto Scaling Group
  * ELB, Listener, Target Group
  * 配置文件
  * S3FS 挂载到 EC2 作为 WordPress 的 Media Library
  


  

## 费用
以 ZHY 为例

* NAT: `0.37 * 24 * 365  =  CNY 3241.2/y`
* ALB: `0.156 * 24 * 365 + 0.072 * 2 * 24 * 365 = CNY 2628/y`


## 素材

BJS AMI: ami-0eebef1aaa174c852
ZHY AMI: ami-0cbbf10eaeaf0f9c3

WordPress 应用程序位于 `/var/www/html` 目录下
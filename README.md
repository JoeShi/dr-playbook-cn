# AWS 灾备解决方案

## 目录结构

- basic: 基础网络结构，自动创建 VPC, Subnet, Security Group。可用于北京区启动


## 费用
以 ZHY 为例

NAT: `0.37 * 24 * 365  =  CNY 3241.2/y`

ALB: `0.156 * 24 * 365 + 0.072 * 2 * 24 * 365 = CNY 2628/y`


## 素材

BJS AMI: ami-0eebef1aaa174c852
ZHY AMI: ami-0cbbf10eaeaf0f9c3

WordPress 应用程序位于 `/var/www/html` 目录下
# AWS 灾备解决方案

## 写在开头

1. 本文架构部署使用 [**terraform**](https://www.terraform.io/) 一键部署AWS 资源，
请在本机安装 terraform, 并配置好[AWS Credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)

2. 本文使用 AWS China Region, 如使用 AWS Global Region，需要修改 镜像地址和 region 信息。

3. 中国区执行 terraform init 下载 `aws provider` 会比较慢，如果使用 MAC, 
可以点[击此](https://aws-quickstart.s3.cn-northwest-1.amazonaws.com.cn/mirror/hashicorp/terraform-provider-aws/2.20.0/terraform-provider-aws_2.20.0_darwin_amd64.zip)
手动下载 `aws provider`。

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
   
## 使用方法

利用 basic, database, app 可以创建生产环境。

利用 basic, app 可以创建灾备环境。

我们利用 terraform workspace 即区分是生产环境还是灾备环境。

> Terraform 可以将信息存储在 S3 和 DynamoDB 中，请先根据一个 S3 Bucket和一个 DynamoDB Table, 
该 DynamoDB 的 primary key 必须叫 `LockID`。

## （可选）创建生产环境

您可以选择手动启动生产环境，这里是为了快速创建进行 demo。

### 基础网络环境

1. 修改 `basic/variables.tf`。
2. 修改 `basic/terraform.tf`, 修改成自己的 Terraform backend 信息。
3. 在 basic 目录下执行 `terraform init`。如果 init 太慢，请手动[下载 aws provider](https://aws-quickstart.s3.cn-northwest-1.amazonaws.com.cn/mirror/hashicorp/terraform-provider-aws/2.20.0/terraform-provider-aws_2.20.0_darwin_amd64.zip)
并置于 `basic/.terraform/plugins/darwin_amd64` 目录下，再次执行 `terraform init`
4. 执行 `terraform workspace create xxx`, 切换到 xxx workspace. 
5. 执行 `terraform apply` 创建基础网络环境


### 数据库 和 S3 Bucket

自动启动数据库只是为了方便 demo, 可以手动启动。

1. 修改 `database/variables.tf`, `database/terraform.tf`.
2. 在 database 目录下执行 `terraform init`, `terraform workspace create xxx`
3. 执行 `terraform apply` 创建数据库
4. 创建 S3 bucket，用于 Wordpress 的 media 文件。
5. 记录 terraform 的输出，其中包括 database 的 endpoint。


### 创建 APP 层

1. 修改 `app/variables.tf`, `app/terraform.tf`.
2. 在 app 目录下执行 `terraform init`, `terraform workspace create xxx`
3. 执行 `terraform apply` 创建 APP 层
4. 记录 terraform  的输出，其中包括 ELB 的 `CNAME` 地址。


至此在生产环境中的 Wordpress 已经创建完成。等待 APP 启动后，即可访问生产环境。

## DR 步骤

根据的实际情况，DR 方案的实施过程分为以下4个步骤

* 准备工作 
* 持久化数据同步
* 故障转移
* 灾后恢复

### 准备工作

0. 提前申请好 Limits. 每一项 AWS 服务都有limits.
1. 在本地安装 **terraform** 工具 和 **AWS CLI**, 并且配置好 AWS Credentials.
2. 创建 用于存储 terraform 状态的 S3 和 DynamoDB, 务必在灾备区域创建！
  由于使用的很少，DynamoDB 建议使用 On-Demand 收费方式。
3. 在原 region 制作 AMI, 并拷贝到灾备区域.
4. 将 使用到的 SSL 证书提前导入 AMI.
5. 修改 `basic/terraform.tf` 和 `basic/variables.tf`. **terraform.tf** 内是
  状态信息保存的地方。**variables.tf** 是模板的变量。
6. 在 **basic** 目录下执行 `terraform init`, 该步骤会下载 provider 文件，耗时长。
7. 执行 `terraform apply`, 创建网络和安全相关设置。
8. 根据 terraform outputs 修改 `apps/variables.tf` 和 `apps/terraform.tf`
9. 根据 terraform outputs 修改 `bastion/variables.tf` 和 `bastion/terraform.tf`


因为大陆地区下载 terraform provider 较慢，建议在 **apps** 和 **bastion** 目录下
提前执行 `terraform init` 来初始化 terraform.

### 数据同步

1. 在原区域选择需要同步的 MySQL 和 PostgreSQL 创建 read replica.
   database subnet group 已经提前创建好. Security Group 已经提前创建好
   但新创建的 read replica 使用默认安全组，需要自行修改。
2. 为 S3 开启 cross region replication 功能
3. 验证数据是否能够正常访问。

如果使用堡垒机进行验证，请在完成**准备工作**之后，再启动堡垒机。

### 故障转移 

强烈建议在完成数据同步之后，进行一次故障转移的演练。

在灾难发生后，执行故障转移。

1. 在 app 目录下 执行 `terraform init` （如已执行，可跳过）
2. 执行 `terraform apply`
3. 在 RDS Console 将 RDS Instance 提升为 master （无与上一步同时执行）
4. 根据 terraform outputs 修改应用的配置 （该步骤可自动化）
5. 测试。功能测试应该在之前测试过，这里主要测试连通性
6. 切换 DNS

### 灾后恢复

灾后恢复请务必咨询架构师！

1. S3 的数据可以通过 **AWS CLI Sync** 命令来完成
2. RDS 需要将原 region 的数据库拆除，并新建可读节点进行同步
3. 修改原 region 的应用配置
4. 找一个合适的时间，重启业务，让数据写入到原 region
6. 切换DNS

## 费用
以 ZHY 为例

* NAT: `0.37 * 24 * 365  =  CNY 3241.2/y`
* ALB: `0.156 * 24 * 365 + 0.072 * 2 * 24 * 365 = CNY 2628/y`


## 素材

BJS AMI: ami-0eebef1aaa174c852
ZHY AMI: ami-0cbbf10eaeaf0f9c3

WordPress 应用程序位于 `/var/www/html` 目录下
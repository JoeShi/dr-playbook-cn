# AWS 灾备解决方案

## 写在开头

1. 本文使用 AWS China Region, 如使用 AWS Global Region，需要修改镜像地址和 region 信息。

2. 本文架构部署使用 [**Terraform**](https://www.terraform.io/) 一键部署AWS 资源，
请在本机安装 **Terraform**, 并配置好[AWS Credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) 

3. 该解决方案使用到 [Terraform S3 Backend](https://www.terraform.io/docs/backends/types/s3.html), 
（可以修改为其他类型的 backend ）需要使用到 S3 Bucket 和 DynamoDB 用于存储状态信息，请提前创建 S3 Bucket 和 DynamoDB Table, 并且
该 DynamoDB Table 的 primary key 必须为 `LockID`。

## 目录结构

- basic: 基础结构。可用于构建基础网络架构, 基础安全配置等等。 包含如下资源：
  * VPC
  * Subnet (包含 public subnet, private subnet)
  * Security Group 
  * DB Subnet Group
  * Cache Subnet Group
  * Route Table

- database: 数据库架构。用于自动创建 RDS 实例。包含如下资源：
  * Database Parameter Group
  * Database 实例
  
- app：应用相关资源。可用于自动构建缓存，应用及更新配置文件。包含如下资源:
  * Redis
  * Application Load Balancer
  * NAT
  * Route Table (给私有子网增加 NAT 路由)
  * Launch Template
  * Auto Scaling Group
  * Application Load Balancer
  * Listener, Target Group
  * 自动生成配置文件
  * S3FS 自动挂载到 EC2 作为 WordPress 的 Media Library

## 使用方法 Step Guide
   
Terraform 可以将信息存储在 S3 和 DynamoDB 中，请先根据一个 S3 Bucket 和一个 DynamoDB Table, 
该 DynamoDB 的 primary key 必须为 `LockID`，类型为 string。

项目内有三个文件夹，`basic`, `database`, `app` 我们将以`<project>`表示。


### 准备工作

1. 提前提升好 limits. 每一项 AWS 服务都有 limits，确保灾备切换时，能否启动足够的资源来支撑应用。
2. 在本地安装 **Terraform** 工具 和 **AWS CLI**, 并且配置好 AWS Credentials.
3. 创建用于存储 Terraform 状态的 S3 和 DynamoDB（由于使用的很少，DynamoDB 建议使用 On-Demand 
收费方式）, **请勿在生产区域部署 S3, DynamoDB**。防止 Region Down 之后，无法使用 Terraform。
4. 在生产区域制作 AMI, 并拷贝到灾备区域。
5. 将使用到的 SSL 证书提前导入 IAM。
6. 修改 `<project>/terraform.tf` 和 `<project>/variables.tf`. **terraform.tf** 是状态信
息保存的地方, 需要使用到之前提到的 DynamoDB 和 S3。**variables.tf** 是模板的变量, 根据实际情况修改。
7. 配置好 AWS Credentials. 该 credentials 需要具备访问 S3, DynamoDB 及自动创建相关资源的权限。

中国大陆地区执行 terraform init 下载 `aws provider` 会比较慢，可提前手动下载, 并解压到
`<project>/.terraform/plugins/<arch>/` 目录下。`<arch>` 为本机的系统和CPU架构, 
如 `darwin_amd64`, `linux_amd64`。

### (可选)创建模拟生产环境

**如果对现有生产环境进行操作，直接跳过此步骤。**

该步骤创建模拟的生产环境，用于演示。可以选择手动创建，或者利用脚本快速创建。使用脚本的好处是，
在演示结束后，我们可以快速销毁演示环境。

**创建基础环境**

1. 修改 `basic/variables.tf` 和 `basic/terraform.tf`
2. 在 basic 目录下执行 `terraform init`
3. 执行 `terraform workspace create prod` 创建 模拟生产环境的 workspace. 
我们使用 workspace 来区分是模拟生产环境或者灾备环境
4. 执行 `terraform apply` 创建基础网络环境

**创建数据库/对象存储资源**

1. 在模拟生产区域创建 S3 Bucket, 并启用 **versioning** 功能，用于存储 WordPress media 文件
2. 修改 `database/variables.tf` 和 `database/terraform.tf`
3. 在 database 目录下执行 `terraform init`
4. 执行 `terraform workspace create prod` 创建 模拟生产环境的 workspace. 
5. 执行 `terraform apply` 创建数据库相关资源

**创建应用层**

1. 修改 `app/variables.tf` 和 `app/terraform.tf`
2. 在 basic 目录下执行 `terraform init`
3. 执行 `terraform workspace create prod` 创建 模拟生产环境的 workspace. 
4. 执行 `terraform apply` 创建基础网络环境


### 灾备环境准备工作

我们需要提前在灾备环境创建基础网络架构，来使得灾难发生时可以快速切换。在使用以下脚本的时候
注意参数的配置。推荐使用脚本创建，这样可以提高自动化的水平。

如果已经在**创建模拟生产环境**中修改了 `terraform.tf` 文件，无需修改该文件。

**拷贝镜像**

1. 在生产区域中选择 EC2, 创建镜像文件 
1. 需要拷贝的镜像文件, 拷贝到灾备区域

**创建基础环境**

1. 修改 `basic/dr.tfvars` 和 `basic/terraform.tf`
2. 在 basic 目录下执行 `terraform init`
3. 执行 `terraform workspace create dr` 创建灾备环境的 workspace. 
我们使用 workspace 来区分是模拟生产环境或者灾备环境
4. 执行 `terraform apply --var-file=dr.tfvars` 创建基础网络环境

**S3 数据同步**

1. 在灾备区域中创建 S3 Bucket, 并启用 **versioning** 功能，用于备份 WordPress 的 Media 文件
1. 在 S3 Console 中选择生产区域的 S3 Bucket, 点击 **Management**, 选择 **Replication**
1. 点击 **Add Rule**, 选择 **Entire bucket**, 并点击 **Next**
1. 选择在灾备区域中选择的目标桶，点击 **Next**
1. 在 IAM Role 中选择 **Create new role**, 输入 **Rule name**, 选择 **Next**。
1. 选择 **Save** 保存复制规则。

开启 S3 Cross Region Replication 的更多资料，请参考[这里](https://docs.aws.amazon.com/AmazonS3/latest/user-guide/enable-crr.html#enable-crr-add-rule)。

**RDS 数据同步**

TODO

1. 在生产区域中选中 RDS 实例，点击右上角 **Actions**, 选择 **Create read replica**
1. 
1.  

**修改灾备应用脚本启动参数**

1. 修改 **`basic/dr.tfvars`**, `basic/terraform.tf`(如之前未修改)
2. 在 app 目录下执行 `terraform init`
3. 执行 `terraform workspace create dr` 创建灾备环境的 workspace. 


### 故障转移 

> 强烈建议在完成数据同步之后，进行一次故障转移的演练。

在灾难发生后，执行故障转移, 请确保 `app` 目录下的 terraform workspace 是 `dr`。

1. 在 app 目录下 执行 `terraform init` （如已执行，可跳过）
1. 执行 `terraform apply --var-file=dr.tfvars` 来启动资源
1. 在 灾备区域 RDS Console 将 RDS Instance 提升为 master （可与上一步同时执行）
1. 测试。功能测试应该在之前测试过，这里主要测试连通性
1. 切换 DNS


### 灾后恢复

灾后恢复请务必咨询架构师！

1. S3 的数据可以通过 **AWS CLI Sync** 命令来完成
1. RDS 需要将原 region 的数据库拆除，并新建可读节点进行同步
1. 找一个合适的时间，重启业务，让数据写入到原 region
1. 切换DNS

## 费用
以 ZHY 为灾备区域计费。



## 素材

BJS AMI: ami-0eebef1aaa174c852
ZHY AMI: ami-0cbbf10eaeaf0f9c3

WordPress 应用程序位于 `/var/www/html` 目录下
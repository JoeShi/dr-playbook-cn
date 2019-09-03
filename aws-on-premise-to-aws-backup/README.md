# On-Premise to AWS Cold Backup & Pilot Light 容灾解决方案

该方案是模拟一个 IT infrastructure 从 On-premises 到云的 Cold Backup 和 Pilot Light Backup。

## SLA

- For Cold Backup:
  - RTO=24小时, RPO=24小时
- For Pilot Light:
  - RTO= 4小时, RPO= 4小时

## 架构图

- 数据复制关系：其中 Cold 与 Pilot Light 都在上图，使用不同颜色线条来反映数据复制
  
    ![](../assets/aws-on-premise-to-aws-backup-hybrid-2.png)

- 网络：

    为了进行数据复制与同步，需要将本地IDC网络与云端VPC进行连接，采用以下选项：
    
    - VPN：使用托管VPN服务，通过互联网建立 Site to Site VPN 进行连接
    - 专线：使用Direct Connect服务进行专线连接，提供 1Gb 至 10Gb 带宽。亦可通过合作伙伴提供小于1Gb带宽的专线连接。


- 本地IDC基础架构：

  - VMware/Hyper-V

    - Web服务器
    - 常见单机或2层架构办公系统，如OA
  - 物理服务器：
    - Redis
    - MySQL数据库
    - 文件服务器
- Pilot Light部分：
  - MySQL数据库

## 解决方案

**非结构化数据服务：NAS（文件共享）**

利用AWS Storage Gateway File Gateway模式来实现非结构化数据的同步与灾备

- 将Storage Gateway虚拟机镜像部署于本地IDC vmware虚拟化平台
- 定期rsync将NAS服务器文件拷贝至Storage Gateway
- Storage Gateway自动将文件同步至S3存储桶
- 云端虚拟机使用s3fs将S3存储桶挂载至本机卷进行文件访问

**结构化数据服务(MySQL数据库)**

- Cold冷备份模式
  
  - 利用XtraBackup工具或者原生备份工具对MySQL数据库进行定时备份并备份文件上传至云端

- Pilot Light模式
  
  - 通过MySQL Binlog复制实现较好的RPO指标

**Web服务器镜像**

- 可将本地IDC中运行于vmware中的虚拟机导出成.ova格式，使用 ec2 import 命令行导入至云端
- 在应用简单的情况下也可在云端重新部署

**常见单机办公系统或者2层架构，如OA等**

- AWS SMS（Server Migration Services) 支持VMware与Hyper-V环境，可以使用SMS迁移目前虚拟环境当中的虚拟机直接到AWS平台中成为AMI
- 在AWS平台中可以方便使用AMI进行恢复或者进行灾难演练

云上快速恢复的脚本已经上传至 [GitHub](https://github.com/lab798/aws-dr-samples)。

## 执行步骤:

1. 建立本地与云中的复制关系

    1. 数据库复制

        **Cold Backup**

        - 安装XtraBackup工具，进行全量、增量备份及还原，具体步骤可参考：https://www.cnblogs.com/kerrycode/p/9236574.html
        - 将生成的备份文件存入NAS文件服务器
        - 由Storage Gateway同步至S3存储桶

        **Pilot Light**

        - 配置步骤参考：Mysql主从复制搭建及详解 (https://blog.csdn.net/hsd2012/article/details/51251051)
        - 开启本地MySQL服务器的Binlog
        - 开启本地MySQL服务器GTID
        - 配置云端RDS MySQL的主节点为本地MySQL服务器
        - 开始进行Binlog同步

    2. 使用VM Import方式进行镜像复制

        1. 在VMWarevSphere中将虚拟机导出为OVF格式，参考 vmware在线文档 (http://pubs.vmware.com/vsphere-4-esx-vcenter/index.jsp?topic=/com.vmware.vsphere.vmadmin.doc_41/vc_client_help/importing_and_exporting_virtual_appliances/t_export_a_virtual_machine.html)
        2. 将导出的OVF格式虚拟机及磁盘文件上传至S3存储桶
        3. 使用import-image命令导入镜像及磁盘文件 https://docs.aws.amazon.com/zh_cn/vm-import/latest/userguide/vmimport-image-import.html

    3. 在线虚拟机复制方式 - AWS SMS：

        1. 参考以下文档，配置IAM Role权限：https://docs.aws.amazon.com/zh_cn/server-migration-service/latest/userguide/permissions-roles.html
        2. 在on-premise环境中VSPHERE/HYPER-V建立Connector. https://docs.aws.amazon.com/zh_cn/server-migration-service/latest/userguide/VMware.html
        3. 对要容灾的VM进行设置，在控制台进行复制 https://docs.aws.amazon.com/zh_cn/server-migration-service/latest/userguide/console_workflow.html

    4. 非结构化数据复制

        1. 使用rsync将nas存储中数据定时同步至Storage Gateway，进一步同步至S3。https://blog.csdn.net/daniel_ustc/article/details/18005925


2. 故障切换，以具有MYSQL, REDIS环境为例

    1. 如果云中部署AD，请将Active Directory切换FSMO
    2. 将RDS MySQL由从节点更改为主节点，中断Binlog复制
    3. 启动ElastiCache集群
    4. 调整Auto Scaling Group节点数量启动EC2 Web服务器
    5. 调整应用配置
    6. 验证与测试
    7. 切换DNS记录
3. 内部系统故障切换，以SMS、VM Import等备份成AMI为例：

    1. 确保VPN，专线到AWS VPC畅通，以保证后续内部系统的访问
    2. 启动VM Import，SMS等系统的AMI
    3. 调整应用配置
    4. 对系统进行验证
    5. 切换DNS记录，使用容灾系统

4. 系统回切

    1. 确保和验证IDC与云上网络的连通性
    2. 等待Active Directory的数据同步，切换FSMO到本地Active Directory服务器
    3. 从RDS MySQL进行备份，恢复至本地数据中心
    4. 配置从RDS MySQL到本地MySQL的主从复制(GTID)
    5. 系统验证与测试
    6. 切换DNS记录
    7. 调整云端Web服务器数量
    8. 终止ElastiCache集群

## 成本分析

1. 正在运行费用
2. 基础架构拉起费用

    <table>
       <tr>
          <td colspan="7">AWS ZHY宁夏区域</td>
       </tr>
       <tr>
          <td></td>
          <td></td>
          <td>service</td>
          <td>type</td>
          <td>hours</td>
          <td>1year</td>
          <td>remarks</td>
       </tr>
       <tr>
          <td rowspan="7">Cold冷备份</td>
          <td>本地工作负载迁移到 AWS</td>
          <td>SMS</td>
          <td>-</td>
          <td>-</td>
          <td>-</td>
          <td>免费使用SMS</td>
       </tr>
       <tr>
          <td>SMS复制时创建EBS快照</td>
          <td>AMI (20GB)</td>
          <td>0.277/GB/月</td>
          <td>-</td>
          <td>66.48</td>
          <td></td>
       </tr>
       <tr>
          <td>本地系统初始数据传输上云</td>
          <td>Snowball</td>
          <td>5000元/次</td>
          <td></td>
          <td></td>
          <td></td>
       </tr>
       <tr>
          <td>数据备份至S3</td>
          <td>S3 (1TB)</td>
          <td>0.1755/GB/月</td>
          <td></td>
          <td>2156.544</td>
          <td></td>
       </tr>
       <tr>
          <td>容灾演练(每半年一次)</td>
          <td>EC2/EBS</td>
          <td>-</td>
          <td>-</td>
          <td>-</td>
          <td>取决于是否需要灾难演练以及需要容灾演练的系统和演练周期，通常占cost比例较小</td>
       </tr>
       <tr>
          <td></td>
          <td></td>
          <td></td>
          <td>total</td>
          <td>2223.024</td>
          <td></td>
       </tr>
       <tr>
          <td></td>
          <td></td>
          <td></td>
          <td>with tax</td>
          <td>2356.40544</td>
          <td></td>
       </tr>
       <tr>
          <td></td>
          <td>service</td>
          <td>type</td>
          <td>hours</td>
          <td>1year</td>
          <td>remarks</td>
       </tr>
       <tr>
          <td rowspan="4">Pilot Light 模式</td>
          <td>数据库资源</td>
          <td>RDS</td>
          <td>db.m4.large (single-AZ)/EBS 200G</td>
          <td>1.1733</td>
          <td>7131.2</td>
          <td></td>
       </tr>
       <tr>
          <td>远程接入</td>
          <td>VPN</td>
          <td>m5.large (linux)</td>
          <td>0.678</td>
          <td>1720</td>
          <td></td>
       </tr>
       <tr>
          <td></td>
          <td></td>
          <td></td>
          <td>total</td>
          <td>11074.224</td>
          <td></td>
       </tr>
       <tr>
          <td></td>
          <td></td>
          <td></td>
          <td>with tax</td>
          <td>11738.67744</td>
          <td></td>
       </tr>
    </table>
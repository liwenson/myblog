

## 备份当前 jenkins 所有项目的配置

"""备份 jenkins 配置, 需要调用 jenkins-cli.jar"""

```
#!/usr/bin/python3

import subprocess

jenkins_host = ""
jenkins_user = ""
jenkins_password = ""
jenkins_cli_path = r'C:\Users\Administrator\Desktop\sh\jenkins-cli.jar'
jenkins_cmd = f'java -jar {jenkins_cli_path} -s {jenkins_host} -auth {jenkins_user}:{jenkins_password} -webSocket'


def execute_command(cmd):
    output = subprocess.Popen(cmd, stdout=subprocess.PIPE).communicate()[0]
    output_string = str(output, encoding='utf-8')
    return output_string


# 获取所有任务
jobs = execute_command(f'{jenkins_cmd} list-jobs').split('\n')[:-1]

# 备份所有任务配置到 xml 文件
for job in jobs:
    job_config = execute_command(f'{jenkins_cmd} get-job {job}')
    with open(f'{job}-backup.xml', 'w', encoding='utf-8') as f:
        f.write(job_config)
        print(job)

# 如需恢复,调用 update-job api 导入即可

```